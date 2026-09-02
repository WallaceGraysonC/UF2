import Foundation
import Observation
// DayEvent carries a tint, so the day-replay colours are resolved here.
// Consistent with the other models that expose display colours.
import SwiftUI

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

    /// Paid promotion currently running. At most one at a time.
    var activeCampaign: AdCampaign?

    /// Pieces retired from sale onto the Museum Wall (Level 10).
    var museum: [MuseumPiece] = []

    /// Run totals that feed cosmetic unlocks and the legacy score.
    var highestSaleValue: Int = 0
    var lifetimeRevenue: Int = 0
    var staffTrainedCount: Int = 0
    var fiveStarDrops: Int = 0

    /// Carried in from the legacy profile so perks apply for the whole run.
    var perks: [LegacyPerk] = []

    /// Summary of the most recent `endDay()`, shown as the day-report.
    /// Deliberately not persisted — it's a transient beat, not run state.
    var lastReport: DayReport?

    /// Blow-by-blow of the last day, for the floor to play back. Also
    /// transient — a replay of what the sim already decided.
    var lastEvents: [DayEvent] = []

    init() {}

    /// A fresh run that inherits whatever previous shops earned.
    convenience init(legacy: LegacyProfile) {
        self.init()
        perks = legacy.perks
        if legacy.has(.seedMoney) { cash += 400 }
        if legacy.has(.rolodex) { staff.append(StaffMember.candidate(shopLevel: 1)) }
    }

    // MARK: Persistence

    /// Everything worth carrying across a launch.
    func snapshot() -> SaveGame {
        SaveGame(
            day: day, cash: cash, shopLevel: shopLevel,
            staff: staff, inventory: inventory, benchJobs: benchJobs,
            ledger: ledger, hiringBoard: hiringBoard,
            activeRun: activeRun, pendingHaul: pendingHaul,
            activeDrop: activeDrop, lastDropResult: lastDropResult,
            dropHistory: dropHistory, discoveredCombos: discoveredCombos,
            reputation: reputation, trendingFormat: trendingFormat,
            trendDaysRemaining: trendDaysRemaining,
            activeCampaign: activeCampaign,
            museum: museum, highestSaleValue: highestSaleValue,
            lifetimeRevenue: lifetimeRevenue, staffTrainedCount: staffTrainedCount,
            fiveStarDrops: fiveStarDrops, perks: perks
        )
    }

    init(snapshot: SaveGame) {
        day = snapshot.day
        cash = snapshot.cash
        shopLevel = snapshot.shopLevel
        staff = snapshot.staff
        inventory = snapshot.inventory
        benchJobs = snapshot.benchJobs
        ledger = snapshot.ledger
        hiringBoard = snapshot.hiringBoard
        activeRun = snapshot.activeRun
        pendingHaul = snapshot.pendingHaul
        activeDrop = snapshot.activeDrop
        lastDropResult = snapshot.lastDropResult
        dropHistory = snapshot.dropHistory
        discoveredCombos = snapshot.discoveredCombos
        reputation = snapshot.reputation
        trendingFormat = snapshot.trendingFormat
        trendDaysRemaining = snapshot.trendDaysRemaining
        activeCampaign = snapshot.activeCampaign
        museum = snapshot.museum
        highestSaleValue = snapshot.highestSaleValue
        lifetimeRevenue = snapshot.lifetimeRevenue
        staffTrainedCount = snapshot.staffTrainedCount
        fiveStarDrops = snapshot.fiveStarDrops
        perks = snapshot.perks
    }

    func save() {
        SaveStore.save(snapshot())
    }

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

    /// Which desk a staffer sits at, so their points pop from the right one.
    func laneIndex(for member: StaffMember) -> Int {
        staff.firstIndex { $0.id == member.id } ?? 0
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

        lastEvents = []
        // Shop-wide events (a sale, wages) aren't any one person's, so they
        // cycle across every desk rather than piling on the first few.
        let lanes = max(1, staff.count)
        var lane = 0
        func nextLane() -> Int {
            defer { lane = (lane + 1) % lanes }
            return lane
        }

        // --- Sales ---
        for item in shelvedInventory {
            guard let buyer = interestedArchetype(for: item) else { continue }
            let repScore = Double(reputation[buyer] ?? 0) / 100.0
            // Rare stock moves slower; it takes the right buyer walking in.
            let baseChance = item.isRare ? 0.08 : 0.28
            let traffic = activeCampaign?.method.trafficBoost ?? 0
            guard Double.random(in: 0...1) < baseChance + repScore * 0.25 + traffic else { continue }

            let price = Double(item.askingPrice(trendModifier: trendModifier(for: item.format)))
            let paid = Int((price * buyer.priceMultiplier).rounded())
            revenue += paid
            itemsSold += 1
            highestSaleValue = max(highestSaleValue, paid)
            soldIDs.append(item.id)
            ledger.append(LedgerEntry(day: day, detail: "\(item.title) → \(buyer.rawValue)",
                                      amount: paid, kind: .sale))
            bumpReputation(buyer, by: item.isRare ? 4 : 1)
            lastEvents.append(DayEvent(headline: "+$\(paid)",
                                       detail: "\(item.format.abbreviation) → \(buyer.rawValue)",
                                       tint: item.isRare ? Theme.red : Theme.green,
                                       lane: nextLane()))
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
            lastEvents.append(DayEvent(headline: "+\(Int(points))",
                                       detail: "\(tech.name) · restoration",
                                       tint: Theme.teal, lane: laneIndex(for: tech)))

            if benchJobs[index].progress >= 1.0 {
                benchJobs[index].progress = 0
                if let next = benchJobs[index].grade.next {
                    benchJobs[index].grade = next
                    gradeUps.append("\(benchJobs[index].itemName) → \(next.label)")
                    lastEvents.append(DayEvent(headline: next.label,
                                               detail: "graded up",
                                               tint: Theme.amberDeep, lane: nextLane()))
                }
            }
        }

        // --- Wages ---
        let wages = dailyWageBill
        cash += revenue - wages
        lifetimeRevenue += revenue

        // The wall works every day it stands.
        if museumDailyRep > 0 {
            bumpReputation(.collector, by: museumDailyRep)
        }
        ledger.append(LedgerEntry(day: day, detail: "Staff wages (\(staff.count))",
                                  amount: -wages, kind: .wages))
        lastEvents.append(DayEvent(headline: "-$\(wages)", detail: "wages",
                                   tint: Theme.red, lane: nextLane()))

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
                lastEvents.append(DayEvent(headline: "+\(gain)",
                                           detail: "\(staff[index].name) · \(stat.rawValue)",
                                           tint: Theme.steel, lane: index))
            }
        }

        // --- Sourcing runs ---
        var haulSize: Int?
        if var run = activeRun {
            let crew = run.buyerIDs.compactMap { staffMember(id: $0) }
            let perkBonus = perks.contains(.eyeForIt) ? 1.25 : 1.0
            for buyer in crew {
                let specBonus = run.location.formats.contains(buyer.specialization) ? 1.3 : 1.0
                let volume = Double(buyer.volume) * buyer.effectiveness * specBonus
                run.volumePoints += volume
                run.rarityPoints += Double(buyer.raritySense) * buyer.effectiveness * perkBonus
                run.negotiationPoints += Double(buyer.negotiation) * buyer.effectiveness
                lastEvents.append(DayEvent(headline: "+\(Int(volume))",
                                           detail: "\(buyer.name) · digging",
                                           tint: Theme.amberDeep,
                                           lane: laneIndex(for: buyer)))
            }
            run.daysRemaining -= 1
            if run.daysRemaining <= 0 {
                let haul = resolveHaul(for: run)
                pendingHaul.append(contentsOf: haul)
                haulSize = haul.count
                lastEvents.append(DayEvent(headline: "\(haul.count) ITEMS",
                                           detail: "haul is back",
                                           tint: Theme.amberDeep, lane: nextLane()))
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
                let design = Double(curator.design) * curator.effectiveness * specBonus * comboBonus * 0.5
                drop.designPoints += design
                drop.hypePoints += Double(curator.hype) * curator.effectiveness * 0.5
                lastEvents.append(DayEvent(headline: "+\(Int(design))",
                                           detail: "\(curator.name) · design",
                                           tint: Theme.plum,
                                           lane: laneIndex(for: curator)))
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

        // --- Advertising ---
        if var campaign = activeCampaign {
            campaign.daysRemaining -= 1
            activeCampaign = campaign.daysRemaining > 0 ? campaign : nil
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

        // Day boundaries are the natural save point.
        save()
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
        save()
    }

    /// Turns a finished run into stock. Volume comes from the location and the
    /// buyers' Volume stat; rare odds come from their Rarity Sense; condition
    /// is rolled per item within the location's range.
    private func resolveHaul(for run: SourcingRun) -> [InventoryItem] {
        guard !run.buyerIDs.isEmpty else { return [] }

        // Everything now comes from what the crew actually banked over the run.
        let dayCount = Double(max(1, run.totalDays))
        let crewSize = Double(max(1, run.buyerIDs.count))
        let volumePerHead = run.volumePoints / (dayCount * crewSize)
        let rarityPerHead = run.rarityPoints / (dayCount * crewSize)

        let range = run.location.itemRange
        let span = Double(range.upperBound - range.lowerBound)
        let count = range.lowerBound + Int((span * min(1.0, volumePerHead / 99.0)).rounded())

        let rareChance = min(0.6, run.location.rareChance * (1.0 + rarityPerHead / 60.0))

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

    // MARK: Advertising

    func canAfford(_ method: AdMethod) -> Bool { cash >= method.cost }

    /// Buys a campaign. Only one runs at a time — stacking billboards isn't
    /// a strategy, choosing the right reach for what you're holding is.
    func runCampaign(_ method: AdMethod) {
        guard activeCampaign == nil, canAfford(method) else { return }
        cash -= method.cost
        ledger.append(LedgerEntry(day: day, detail: "\(method.rawValue) — advertising",
                                  amount: -method.cost, kind: .upgrade))
        for archetype in method.reaches {
            bumpReputation(archetype, by: method.repGain)
        }
        activeCampaign = AdCampaign(method: method)
        save()
    }

    // MARK: The Museum Wall

    var museumUnlocked: Bool { shopLevel >= 10 }
    var museumCapacity: Int { 8 }
    var museumHasRoom: Bool { museum.count < museumCapacity }

    /// Standing reputation the wall generates every day, forever.
    var museumDailyRep: Int {
        museum.map(\.dailyRepContribution).reduce(0, +)
    }

    /// Take something off the market for good. The value is forfeited on
    /// purpose — that's the whole point of the wall.
    func mount(_ item: InventoryItem) {
        guard museumUnlocked, museumHasRoom else { return }
        let price = item.askingPrice(trendModifier: trendModifier(for: item.format))
        museum.append(MuseumPiece(from: item, askingPrice: price, day: day))
        inventory.removeAll { $0.id == item.id }
        pendingHaul.removeAll { $0.id == item.id }
        save()
    }

    // MARK: Closing up shop

    /// Retirement opens once the shop is finished and you've committed at
    /// least one piece to the wall — but it's never forced. Staying open
    /// keeps growing the score, so when to stop is the player's call.
    var canCloseUpShop: Bool {
        shopLevel >= 10 && !museum.isEmpty
    }

    /// What retiring right now would be worth. Keeps climbing the longer you
    /// trade, which is what makes "one more day" a real temptation.
    var legacyScore: Int {
        let repScore = overallReputation * 12
        let museumScore = museum.map(\.forgoneValue).reduce(0, +) * 2
        let tradeScore = lifetimeRevenue / 10
        let crewScore = staffTrainedCount * 60
        let dropScore = fiveStarDrops * 120
        return repScore + museumScore + tradeScore + crewScore + dropScore
    }

    /// Rolls this run's totals into the permanent profile and reports what
    /// changed, so the retirement screen can show it.
    func closeUpShop(into profile: inout LegacyProfile, perk: LegacyPerk?) -> [Cosmetic] {
        let score = legacyScore

        profile.prestigeCount += 1
        profile.totalLegacyScore += score
        profile.bestLegacyScore = max(profile.bestLegacyScore, score)
        if let perk, !profile.perks.contains(perk) {
            profile.perks.append(perk)
        }

        profile.lifetimeRevenue += lifetimeRevenue
        profile.highestSaleValue = max(profile.highestSaleValue, highestSaleValue)
        profile.bestShopLevel = max(profile.bestShopLevel, shopLevel)
        profile.totalMuseumPieces += museum.count
        profile.totalStaffTrained += staffTrainedCount
        profile.totalFiveStarDrops += fiveStarDrops
        profile.lowestRetirementCash = min(profile.lowestRetirementCash, cash)

        let newlyUnlocked = profile.refreshUnlocks()
        LegacyStore.save(profile)
        // The run is over — its save goes, the profile stays.
        SaveStore.deleteSave()
        return newlyUnlocked
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
        save()
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
        save()
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
        let days = perks.contains(.quickStudy) ? Self.trainingDays - 1 : Self.trainingDays
        staff[index].trainingDaysRemaining = max(1, days)
        staff[index].trainingStat = stat
        staffTrainedCount += 1
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
        save()
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
        if stars == 5 { fiveStarDrops += 1 }
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
