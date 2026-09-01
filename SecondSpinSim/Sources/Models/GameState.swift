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

    /// At most one Drop in prep at a time.
    var activeDrop: CuratedDrop?
    /// The most recent write-up, and the running history of them.
    var lastDropResult: DropResult?
    var dropHistory: [DropResult] = []
    /// Theme×angle pairings the player has actually run — ratings stay hidden
    /// until tried, so combinations are something you learn, not read off.
    var discoveredCombos: Set<String> = []

    /// Three faces rotating on the hiring board, refreshed on a level-up.
    var hiringBoard: [StaffMember] = [
        StaffMember.candidate(shopLevel: 1),
        StaffMember.candidate(shopLevel: 1),
        StaffMember.candidate(shopLevel: 1)
    ]

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
        /// Staff back from a convention, with what they picked up.
        var trainingFinished: [String] = []
        /// Non-nil on the day a Sourcing Run comes back.
        var haulSize: Int?
        /// Non-nil on the day a Drop launches.
        var dropResult: DropResult?

        var net: Int { revenue - wages }
    }

    // MARK: Unlocks driven by shop level

    /// Formats the shop can stock. Hauls only turn up what you can sell.
    var unlockedFormats: Set<MediaFormat> {
        var formats: Set<MediaFormat> = [.cd, .vhs]
        if shopLevel >= 2 { formats.insert(.vinyl) }
        if shopLevel >= 4 { formats.insert(.game) }
        if shopLevel >= 6 { formats.insert(.laserdisc) }
        return formats
    }

    var benchUnlocked: Bool { shopLevel >= 3 }

    var benchCapacity: Int {
        if shopLevel < 3 { return 0 }
        return shopLevel >= 7 ? 6 : 4
    }

    /// Shelf slots on the floor — the expansion at Level 7 buys real room.
    var binCapacity: Int { shopLevel >= 7 ? 18 : 12 }

    /// Live Drops need the stage; the cheap endcap doesn't.
    func isUnlocked(_ theme: DropTheme) -> Bool {
        switch theme {
        case .staffPicks: return true
        case .breakbeatWall: return shopLevel >= 2
        case .horrorNight: return true
        case .importShelf: return shopLevel >= 4
        case .listeningParty: return shopLevel >= 5
        }
    }

    var availableThemes: [DropTheme] { DropTheme.allCases.filter(isUnlocked) }

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
        workingIDs.formUnion(activeDrop?.curatorIDs ?? [])
        for index in staff.indices {
            if workingIDs.contains(staff[index].id) {
                staff[index].fatigue = min(100, staff[index].fatigue + 12)
            } else {
                staff[index].fatigue = max(0, staff[index].fatigue - 18)
            }
        }

        // --- Training: conventions tick down and pay out on return ---
        var trainingFinished: [String] = []
        for index in staff.indices where staff[index].isTraining {
            staff[index].trainingDaysRemaining -= 1
            if staff[index].trainingDaysRemaining <= 0, let stat = staff[index].trainingStat {
                let gain = Int.random(in: 6...11)
                staff[index].raise(stat, by: gain)
                staff[index].trainingStat = nil
                trainingFinished.append("\(staff[index].name) — \(stat.rawValue) +\(gain)")
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

        // --- Curated Drops ---
        var launchedDrop: DropResult?
        if var drop = activeDrop {
            let crew = drop.curatorIDs.compactMap { staffMember(id: $0) }
            // Theme x angle is worth more than an extra body — a perfect
            // pairing is a 1.5x on everything the curators put in.
            let comboBonus = drop.affinity.multiplier
            for curator in crew {
                let specBonus = curator.specialization == drop.theme.format ? 1.3 : 1.0
                drop.designPoints += Double(curator.design) * curator.effectiveness
                    * specBonus * comboBonus * 0.5
                drop.hypePoints += Double(curator.hype) * curator.effectiveness * 0.5
            }
            drop.daysRemaining -= 1

            if drop.daysRemaining <= 0 {
                resolveDrop(drop)
                launchedDrop = lastDropResult
                activeDrop = nil
            } else {
                activeDrop = drop
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
                               gradeUps: gradeUps, trainingFinished: trainingFinished,
                               haulSize: haulSize, dropResult: launchedDrop)
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

    /// Staff away at a convention can't be assigned to anything.
    var buyers: [StaffMember] { staff.filter { $0.role == .buyer && !$0.isTraining } }

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

        // Hauls only turn up formats the shop is licensed to sell — the
        // Vinyl/Games/Laserdisc sections have to be unlocked first.
        let sellable = run.location.formats.filter { unlockedFormats.contains($0) }
        let pool = sellable.isEmpty ? Array(unlockedFormats) : sellable

        return (0..<max(1, count)).map { _ in
            let format = pool.randomElement() ?? .cd
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

    // MARK: The shop ladder

    var nextUpgrade: ShopUpgrade? { ShopUpgrade.upgrade(toReach: shopLevel + 1) }

    /// Every gate on the next rung, each with whether it's currently met —
    /// so the upgrade sheet can show exactly what's still missing.
    func requirements(for upgrade: ShopUpgrade) -> [UpgradeRequirement] {
        var rows: [UpgradeRequirement] = [
            UpgradeRequirement(label: "$\(upgrade.cash) in the till", met: cash >= upgrade.cash),
            UpgradeRequirement(label: "\(upgrade.staffRequired) staff on the roster",
                               met: staff.count >= upgrade.staffRequired)
        ]

        if let role = upgrade.roleRequired {
            rows.append(UpgradeRequirement(
                label: "A \(role.rawValue) on the roster",
                met: staff.contains { $0.role == role }))
        }

        if let rep = upgrade.repRequirement {
            rows.append(UpgradeRequirement(
                label: "\(rep.archetype.rawValue) rep \(rep.value)+",
                met: (reputation[rep.archetype] ?? 0) >= rep.value))
        }

        if let breadth = upgrade.breadthRequirement {
            let count = reputation.values.filter { $0 >= breadth.value }.count
            rows.append(UpgradeRequirement(
                label: "\(breadth.value)+ rep with \(breadth.count) crowds (\(count)/\(breadth.count))",
                met: count >= breadth.count))
        }

        return rows
    }

    func canUpgrade(to upgrade: ShopUpgrade) -> Bool {
        requirements(for: upgrade).allSatisfy(\.met)
    }

    /// Buys the next rung. Refreshes the hiring board, since a bigger shop
    /// attracts better people.
    func performUpgrade() {
        guard let upgrade = nextUpgrade, canUpgrade(to: upgrade) else { return }
        cash -= upgrade.cash
        shopLevel = upgrade.level
        ledger.append(LedgerEntry(day: day, detail: "Upgrade — \(upgrade.title)",
                                  amount: -upgrade.cash, kind: .upgrade))
        refreshHiringBoard()
    }

    // MARK: Hiring & training

    func refreshHiringBoard() {
        hiringBoard = (0..<3).map { _ in StaffMember.candidate(shopLevel: shopLevel) }
    }

    func canHire(_ candidate: StaffMember) -> Bool { cash >= candidate.signingFee }

    func hire(_ candidate: StaffMember) {
        guard canHire(candidate) else { return }
        cash -= candidate.signingFee
        ledger.append(LedgerEntry(day: day, detail: "Signed \(candidate.name) (\(candidate.role.rawValue))",
                                  amount: -candidate.signingFee, kind: .purchase))
        staff.append(candidate)
        hiringBoard.removeAll { $0.id == candidate.id }
    }

    /// A convention costs cash and takes the staffer off the floor for three
    /// days — stat growth is never instant.
    static let trainingCost = 350
    static let trainingDays = 3

    func canTrain(_ member: StaffMember) -> Bool {
        cash >= Self.trainingCost && !member.isTraining
    }

    func sendToConvention(_ member: StaffMember, for stat: TrainableStat) {
        guard canTrain(member), let index = staff.firstIndex(where: { $0.id == member.id }) else { return }
        cash -= Self.trainingCost
        ledger.append(LedgerEntry(day: day, detail: "\(member.name) — convention (\(stat.rawValue))",
                                  amount: -Self.trainingCost, kind: .upgrade))
        staff[index].trainingDaysRemaining = Self.trainingDays
        staff[index].trainingStat = stat
    }

    // MARK: Curated Drops

    var curators: [StaffMember] { staff.filter { $0.role == .curator && !$0.isTraining } }

    var techs: [StaffMember] { staff.filter { $0.role == .tech && !$0.isTraining } }

    func canAfford(_ theme: DropTheme) -> Bool { cash >= theme.cost }

    func startDrop(name: String, theme: DropTheme, angle: DropAngle, curatorIDs: [UUID]) {
        guard activeDrop == nil, !curatorIDs.isEmpty, canAfford(theme) else { return }
        cash -= theme.cost
        ledger.append(LedgerEntry(day: day, detail: "\(theme.rawValue) — setup",
                                  amount: -theme.cost, kind: .upgrade))
        // Running a pairing is how you learn what it's worth.
        discoveredCombos.insert(DropCombo.key(theme: theme, angle: angle))
        activeDrop = CuratedDrop(name: name, theme: theme, angle: angle, curatorIDs: curatorIDs)
    }

    /// A pairing the player has run before, so the planner can show its rating
    /// up front instead of making them guess twice.
    func hasDiscovered(theme: DropTheme, angle: DropAngle) -> Bool {
        discoveredCombos.contains(DropCombo.key(theme: theme, angle: angle))
    }

    /// Launch day. Hype sets how many people show up; Design decides whether
    /// what they found was worth the trip — a big turnout on a thin display
    /// is the bad review, which is why Hype alone isn't a strategy.
    private func resolveDrop(_ drop: CuratedDrop) {
        let theme = drop.theme

        let turnout = max(1, Int((drop.hypePoints / 8.0) * (1.0 + Double(overallReputation) / 120.0)))

        // Design measured against what the theme promised.
        let ratio = drop.designPoints / theme.expectation
        let stars: Int
        switch ratio {
        case ..<0.4: stars = 1
        case ..<0.7: stars = 2
        case ..<1.1: stars = 3
        case ..<1.6: stars = 4
        default: stars = 5
        }

        // Themed stock moves at a premium, capped by how many people came.
        var revenue = 0
        var soldIDs: [UUID] = []
        let sellable = shelvedInventory.filter { $0.format == theme.format }
        for item in sellable.prefix(max(1, turnout / 3)) {
            let price = Double(item.askingPrice(trendModifier: trendModifier(for: item.format)))
            let premium = 1.0 + Double(stars) * 0.08
            revenue += Int((price * premium).rounded())
            soldIDs.append(item.id)
        }
        inventory.removeAll { soldIDs.contains($0.id) }

        if revenue > 0 {
            cash += revenue
            ledger.append(LedgerEntry(day: day, detail: "\(drop.name) — \(soldIDs.count) sold",
                                      amount: revenue, kind: .sale))
        }

        // Reputation swings both ways: a 1- or 2-star write-up costs you.
        let repDelta = (stars - 2) * 4
        var gains: [CustomerArchetype: Int] = [:]
        for archetype in theme.draws {
            let before = reputation[archetype] ?? 0
            reputation[archetype] = max(0, min(100, before + repDelta))
            gains[archetype] = (reputation[archetype] ?? 0) - before
        }

        let result = DropResult(themeName: drop.name, day: day, turnout: turnout,
                                stars: stars, revenue: revenue, repGains: gains,
                                review: DropResult.review(stars: stars, themeName: drop.name))
        lastDropResult = result
        dropHistory.append(result)
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
