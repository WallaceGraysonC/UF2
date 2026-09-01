import Foundation
import Observation

/// Single source of truth for a run. Every screen reads from this, and
/// `endDay()` is the one place the simulation actually advances.
@Observable
final class GameState {
    var day: Int = 1
    var cash: Int = 800
    var shopLevel: Int = 1

    var staff: [StaffMember] = StaffMember.starterRoster()
    var inventory: [InventoryItem] = InventoryItem.starterStock()
    var benchJobs: [RestorationJob] = RestorationJob.starterJobs()
    var ledger: [LedgerEntry] = []

    /// At most one buying trip out at a time.
    var activeRun: SourcingRun?
    /// Haul waiting to be graded — items aren't stock until the player rules on them.
    var pendingHaul: [InventoryItem] = []

    let benchCapacity = 4

    var reputation: [CustomerArchetype: Int] = [
        .collector: 40, .crateDigger: 55, .completionist: 20,
        .nostalgic: 60, .reseller: 30, .casual: 70
    ]

    /// Seasonal demand — one format runs hot for a stretch, so the optimal
    /// stocking strategy keeps moving instead of being solved once.
    var trendingFormat: MediaFormat = .vhs
    private var trendDaysRemaining: Int = 6

    /// Summary of the most recent `endDay()`, shown as the day-report.
    var lastReport: DayReport?

    struct DayReport {
        var day: Int
        var itemsSold: Int
        var revenue: Int
        var wages: Int
        var restorationsAdvanced: Int
        var gradeUps: [String]
        /// Non-nil on the day a Sourcing Run comes back.
        var haulSize: Int?

        var net: Int { revenue - wages }
    }

    // MARK: Derived

    var shelvedInventory: [InventoryItem] { inventory.filter(\.isShelved) }

    var dailyWageBill: Int { staff.map(\.dailyWage).reduce(0, +) }

    var overallReputation: Int {
        guard !reputation.isEmpty else { return 0 }
        return reputation.values.reduce(0, +) / reputation.count
    }

    func staffMember(id: UUID?) -> StaffMember? {
        guard let id else { return nil }
        return staff.first { $0.id == id }
    }

    func trendModifier(for format: MediaFormat) -> Double {
        format == trendingFormat ? 1.4 : 1.0
    }

    // MARK: Day tick

    /// Runs one business day: sales roll against reputation, techs advance
    /// bench work, wages come out, fatigue moves, trends age.
    func endDay() {
        var revenue = 0
        var itemsSold = 0
        var soldIDs: [UUID] = []

        // --- Sales ---
        for item in shelvedInventory {
            guard let buyer = interestedArchetype(for: item) else { continue }
            let repScore = Double(reputation[buyer] ?? 0) / 100.0
            // Rare stock moves slower; it takes the right buyer walking in.
            let baseChance = item.isRare ? 0.08 : 0.28
            guard Double.random(in: 0...1) < baseChance + repScore * 0.25 else { continue }

            let price = Double(item.askingPrice(trendModifier: trendModifier(for: item.format)))
            let paid = Int((price * buyer.priceMultiplier).rounded())
            revenue += paid
            itemsSold += 1
            soldIDs.append(item.id)
            ledger.append(LedgerEntry(day: day, detail: "\(item.title) → \(buyer.rawValue)",
                                      amount: paid, kind: .sale))
            bumpReputation(buyer, by: item.isRare ? 4 : 1)
        }
        inventory.removeAll { soldIDs.contains($0.id) }

        // --- Bench work ---
        var advanced = 0
        var gradeUps: [String] = []
        for index in benchJobs.indices {
            guard let tech = staffMember(id: benchJobs[index].assignedTechID) else { continue }
            let specBonus = tech.specialization == benchJobs[index].format ? 1.35 : 1.0
            let points = Double(tech.restoration) * tech.effectiveness * specBonus
            benchJobs[index].progress += (points / 100.0) / benchJobs[index].effortMultiplier
            advanced += 1

            if benchJobs[index].progress >= 1.0 {
                benchJobs[index].progress = 0
                if let next = benchJobs[index].grade.next {
                    benchJobs[index].grade = next
                    gradeUps.append("\(benchJobs[index].itemName) → \(next.label)")
                }
            }
        }

        // --- Wages ---
        let wages = dailyWageBill
        cash += revenue - wages
        ledger.append(LedgerEntry(day: day, detail: "Staff wages (\(staff.count))",
                                  amount: -wages, kind: .wages))

        // --- Fatigue: staff on the bench or out on a run tire, the rest recover.
        // Runs are still active here — a buyer tires on the day they get back too.
        var workingIDs = Set(benchJobs.compactMap(\.assignedTechID))
        workingIDs.formUnion(activeRun?.buyerIDs ?? [])
        for index in staff.indices {
            if workingIDs.contains(staff[index].id) {
                staff[index].fatigue = min(100, staff[index].fatigue + 12)
            } else {
                staff[index].fatigue = max(0, staff[index].fatigue - 18)
            }
        }

        // --- Sourcing runs ---
        var haulSize: Int?
        if var run = activeRun {
            run.daysRemaining -= 1
            if run.daysRemaining <= 0 {
                let haul = resolveHaul(for: run)
                pendingHaul.append(contentsOf: haul)
                haulSize = haul.count
                activeRun = nil
            } else {
                activeRun = run
            }
        }

        // --- Trend rotation ---
        trendDaysRemaining -= 1
        if trendDaysRemaining <= 0 {
            trendingFormat = MediaFormat.allCases.randomElement() ?? .vinyl
            trendDaysRemaining = Int.random(in: 5...9)
        }

        lastReport = DayReport(day: day, itemsSold: itemsSold, revenue: revenue,
                               wages: wages, restorationsAdvanced: advanced,
                               gradeUps: gradeUps, haulSize: haulSize)
        day += 1
    }

    /// Picks which archetype, if any, is in the market for this item today.
    private func interestedArchetype(for item: InventoryItem) -> CustomerArchetype? {
        let candidates = CustomerArchetype.allCases.filter {
            $0.preferredFormats.contains(item.format)
        }
        // Weight by reputation so a shop known to collectors sees collectors.
        let weighted = candidates.flatMap { archetype in
            Array(repeating: archetype, count: max(1, (reputation[archetype] ?? 0) / 10))
        }
        return weighted.randomElement()
    }

    private func bumpReputation(_ archetype: CustomerArchetype, by amount: Int) {
        reputation[archetype] = min(100, (reputation[archetype] ?? 0) + amount)
    }

    // MARK: Assignment

    func assign(techID: UUID?, to jobID: UUID) {
        guard let index = benchJobs.firstIndex(where: { $0.id == jobID }) else { return }
        benchJobs[index].assignedTechID = techID
    }

    // MARK: Sourcing

    var buyers: [StaffMember] { staff.filter { $0.role == .buyer } }

    func canAfford(_ location: SourcingLocation) -> Bool { cash >= location.cost }

    /// Sends buyers out. Cost is paid up front, win or lose.
    func startRun(location: SourcingLocation, buyerIDs: [UUID]) {
        guard activeRun == nil, !buyerIDs.isEmpty, canAfford(location) else { return }
        cash -= location.cost
        ledger.append(LedgerEntry(day: day, detail: "\(location.rawValue) — buy-in",
                                  amount: -location.cost, kind: .purchase))
        activeRun = SourcingRun(location: location, buyerIDs: buyerIDs)
    }

    /// Turns a finished run into stock. Volume comes from the location and the
    /// buyers' Volume stat; rare odds come from their Rarity Sense; condition
    /// is rolled per item within the location's range.
    private func resolveHaul(for run: SourcingRun) -> [InventoryItem] {
        let crew = run.buyerIDs.compactMap { staffMember(id: $0) }
        guard !crew.isEmpty else { return [] }

        let avgVolume = Double(crew.map(\.volume).reduce(0, +)) / Double(crew.count)
        let avgRarity = Double(crew.map(\.raritySense).reduce(0, +)) / Double(crew.count)
        let effectiveness = crew.map(\.effectiveness).reduce(0, +) / Double(crew.count)

        let range = run.location.itemRange
        // A strong crew pushes toward the top of the location's range.
        let volumeBias = (avgVolume / 99.0) * effectiveness
        let span = Double(range.upperBound - range.lowerBound)
        let count = range.lowerBound + Int((span * volumeBias).rounded())

        let rareChance = min(0.6, run.location.rareChance * (1.0 + avgRarity / 60.0) * effectiveness)

        return (0..<max(1, count)).map { _ in
            let format = run.location.formats.randomElement() ?? .cd
            let isRare = Double.random(in: 0...1) < rareChance
            let condition = Double.random(in: run.location.conditionRange)
            return HaulCatalog.roll(format: format, isRare: isRare, condition: condition)
        }
    }

    // MARK: Grading the haul

    var benchHasRoom: Bool { benchJobs.count < benchCapacity }

    /// Put a graded item straight out on the floor.
    func shelve(_ item: InventoryItem) {
        var shelved = item
        shelved.isShelved = true
        inventory.append(shelved)
        pendingHaul.removeAll { $0.id == item.id }
    }

    /// Send it to the backroom bench to have its grade worked up first.
    func sendToBench(_ item: InventoryItem) {
        guard benchHasRoom else { return }
        benchJobs.append(RestorationJob(itemName: item.title, format: item.format,
                                        grade: item.grade, progress: 0,
                                        assignedTechID: nil))
        pendingHaul.removeAll { $0.id == item.id }
    }

    /// Dump it — some of what comes back in a storage unit is genuinely junk.
    func discard(_ item: InventoryItem) {
        pendingHaul.removeAll { $0.id == item.id }
    }
}

extension ConditionGrade {
    /// The next band up, or nil at Mint.
    var next: ConditionGrade? {
        switch self {
        case .poor: return .fair
        case .fair: return .good
        case .good: return .veryGood
        case .veryGood: return .nearMint
        case .nearMint: return .mint
        case .mint: return nil
        }
    }
}
