import Foundation
import Observation
import SwiftUI

/// Single source of truth. Every screen reads from this, and `endDay()` is
/// the one place the simulation advances.
@Observable
final class Studio {
    var day: Int = 1
    var cash: Int = 1_200
    var fans: Int = 0
    var studioLevel: Int = 1

    var employees: [Employee] = Employee.starterRoster()
    var hiringBoard: [Employee] = [Employee.candidate(studioLevel: 1), Employee.candidate(studioLevel: 1)]

    var currentProject: GameProject?
    /// True once development time is up and the player has to decide to ship.
    var needsShipDecision: Bool = false

    var shippedGames: [ShippedGame] = []

    /// Genre×topic pairings actually tried — ratings stay hidden until then.
    var discoveredCombos: Set<String> = []

    /// Fan-count thresholds already celebrated, so each only fires once.
    var milestonesReached: Set<Int> = []
    /// Transient — the most recent milestone, for a one-time celebration.
    var lastMilestone: FanMilestone?

    struct FanMilestone: Equatable {
        var fans: Int
        var cashBonus: Int
    }

    /// Real-time clock. Live only — no offline catch-up, same as the game
    /// this is modelled on: you watch it happen.
    var isRunning: Bool = false
    var secondsPerDay: Double = 1.6

    /// Transient — a replay of what the sim already decided.
    var lastEvents: [DayEvent] = []
    var lastShipResult: ShipResult?

    struct ShipResult {
        var game: ShippedGame
        var pointsRatio: Double
        var bugPenaltyApplied: Bool
    }

    init() {}

    // MARK: Persistence

    func snapshot() -> SaveFile {
        SaveFile(day: day, cash: cash, fans: fans, studioLevel: studioLevel,
                employees: employees, hiringBoard: hiringBoard,
                currentProject: currentProject, needsShipDecision: needsShipDecision,
                shippedGames: shippedGames, discoveredCombos: discoveredCombos,
                milestonesReached: milestonesReached)
    }

    init(snapshot: SaveFile) {
        day = snapshot.day
        cash = snapshot.cash
        fans = snapshot.fans
        studioLevel = snapshot.studioLevel
        employees = snapshot.employees
        hiringBoard = snapshot.hiringBoard
        currentProject = snapshot.currentProject
        needsShipDecision = snapshot.needsShipDecision
        shippedGames = snapshot.shippedGames
        discoveredCombos = snapshot.discoveredCombos
        milestonesReached = snapshot.milestonesReached
    }

    func save() { SaveStore.save(snapshot()) }

    // MARK: Derived

    var deskCapacity: Int {
        StudioUpgrade.upgrade(toReach: studioLevel)?.deskCapacity
            ?? StudioUpgrade.ladder.first!.deskCapacity
    }

    var dailyWageBill: Int { employees.map(\.dailyWage).reduce(0, +) }

    func laneIndex(for employee: Employee) -> Int {
        employees.firstIndex { $0.id == employee.id } ?? 0
    }

    // MARK: Day tick

    /// Runs one day: the team works the current project (if any), bugs may
    /// appear, wages come out, shipped games sell a little more, and the
    /// project pauses for a ship decision once its time is up.
    func endDay() {
        lastEvents = []
        var lane = 0
        func nextLane() -> Int { defer { lane = (lane + 1) % max(1, employees.count) }; return lane }

        // --- The project ---
        if var project = currentProject, !needsShipDecision {
            let affinityBonus = project.affinity.multiplier
            for employee in employees {
                let genreBonus = employee.favoriteGenre == project.genre ? 1.25 : 1.0
                let output = Double(employee.speed) / 55.0 * affinityBonus * genreBonus

                let designEarned = Double(employee.design) * project.focusBias * output
                let techEarned = Double(employee.tech) * (1 - project.focusBias) * output
                project.designPoints += designEarned
                project.techPoints += techEarned

                let total = Int(designEarned + techEarned)
                if total > 0 {
                    lastEvents.append(DayEvent(headline: "+\(total)",
                                               detail: "\(employee.name) · working",
                                               tint: Theme.plum, lane: laneIndex(for: employee)))
                }
            }

            project.daysElapsed += 1

            // Bugs start turning up once the project is mostly built. Leaning
            // the focus dial hard toward Design (at the expense of Tech)
            // makes them more likely — the real cost of that choice.
            let bugChance = 0.18 + project.focusBias * 0.32
            if project.isInPolishWindow && Double.random(in: 0...1) < bugChance {
                let lane = employees.indices.randomElement() ?? 0
                project.bugs.append(Bug(deskLane: lane, spawnedDay: day))
                lastEvents.append(DayEvent(headline: "BUG",
                                           detail: "found at \(employees[safe: lane]?.name ?? "a desk")",
                                           tint: Theme.red, lane: lane))
            }

            if project.isReadyToShip {
                needsShipDecision = true
                lastEvents.append(DayEvent(headline: "DONE",
                                           detail: "\(project.name) is ready",
                                           tint: Theme.amberDeep, lane: nextLane()))
            }

            currentProject = project
        }

        // --- Wages ---
        let wages = dailyWageBill
        cash -= wages
        if wages > 0 {
            lastEvents.append(DayEvent(headline: "-$\(wages)", detail: "wages",
                                       tint: Theme.red, lane: nextLane()))
        }

        // --- Shipped games keep selling, tapering off ---
        for index in shippedGames.indices where !shippedGames[index].isRetired {
            let game = shippedGames[index]
            let decay = pow(0.88, Double(game.daysSinceShip))
            let dailySales = Double(salesBudget(for: game)) * decay
            let revenue = Int(dailySales)
            if revenue > 0 {
                cash += revenue
                shippedGames[index].lifetimeSales += revenue
                lastEvents.append(DayEvent(headline: "+$\(revenue)",
                                           detail: "\(game.name) sales",
                                           tint: Theme.green, lane: nextLane()))
            }
            shippedGames[index].daysSinceShip += 1
            if decay < 0.03 { shippedGames[index].isRetired = true }
        }

        day += 1
        save()
    }

    /// The daily sales a shipped game is capable of at its peak, before decay —
    /// scaled by its score, size, and how well the genre fit the platform.
    private func salesBudget(for game: ShippedGame) -> Int {
        let starRatio = Double(game.stars) / 5.0
        let marketReach = game.platform.salesMultiplier * game.platform.fit(for: game.genre)
        return Int(Double(game.size.salesCeiling) * starRatio * starRatio * 0.14 * marketReach)
    }

    // MARK: Unlocks

    func isUnlocked(_ genre: Genre) -> Bool { studioLevel >= genre.unlockLevel }
    func isUnlocked(_ platform: Platform) -> Bool { studioLevel >= platform.unlockLevel }

    // MARK: Starting a project

    var canStartProject: Bool { currentProject == nil }

    /// The licence fee stacks on top of the project's own development cost.
    func totalCost(size: ProjectSize, platform: Platform) -> Int {
        size.cost + platform.entryFee
    }

    func canAfford(size: ProjectSize, platform: Platform) -> Bool {
        cash >= totalCost(size: size, platform: platform)
    }

    func startProject(name: String, genre: Genre, topic: Topic, size: ProjectSize, platform: Platform) {
        guard canStartProject, canAfford(size: size, platform: platform),
              isUnlocked(genre), isUnlocked(platform) else { return }
        cash -= totalCost(size: size, platform: platform)
        discoveredCombos.insert(GenreTopicCombo.key(genre: genre, topic: topic))
        currentProject = GameProject(name: name.isEmpty ? "Untitled" : name,
                                     genre: genre, topic: topic, size: size, platform: platform)
        needsShipDecision = false
        save()
    }

    func hasDiscovered(genre: Genre, topic: Topic) -> Bool {
        discoveredCombos.contains(GenreTopicCombo.key(genre: genre, topic: topic))
    }

    // MARK: Bugs

    func squashBug(_ bug: Bug) {
        guard var project = currentProject else { return }
        project.bugs.removeAll { $0.id == bug.id }
        project.bugsFixed += 1
        // A small reward, split toward whichever point the project needs more.
        if project.designPoints < project.techPoints {
            project.designPoints += 6
        } else {
            project.techPoints += 6
        }
        currentProject = project
    }

    // MARK: Shipping

    /// Ships the finished project: scores it, banks the launch sales burst,
    /// and clears the desks for the next one.
    @discardableResult
    func shipProject() -> ShipResult? {
        guard var project = currentProject, needsShipDecision else { return nil }

        let ratio = project.totalPoints / project.size.targetPoints
        let bugPenalty = max(0, 1.0 - Double(project.unfixedBugCount) * 0.06)
        let finalRatio = ratio * bugPenalty

        let stars: Int
        switch finalRatio {
        case ..<0.5: stars = 1
        case ..<0.8: stars = 2
        case ..<1.1: stars = 3
        case ..<1.5: stars = 4
        default: stars = 5
        }

        var shipped = ShippedGame(name: project.name, genre: project.genre, topic: project.topic,
                                  size: project.size, platform: project.platform, shipDay: day,
                                  stars: stars, reviewLine: Self.reviewLine(stars: stars, name: project.name))

        // Launch week burst, scaled by the platform's market fit, then the
        // game joins the regular sales tail.
        let marketReach = project.platform.salesMultiplier * project.platform.fit(for: project.genre)
        let burst = Int(Double(project.size.salesCeiling) * (Double(stars) / 5.0) * 0.22 * marketReach)
        cash += burst
        shipped.lifetimeSales = burst
        fans += stars * 40

        shippedGames.append(shipped)
        growTeam(from: project, stars: stars)
        currentProject = nil
        needsShipDecision = false
        project.bugs = []

        let result = ShipResult(game: shipped, pointsRatio: ratio, bugPenaltyApplied: project.unfixedBugCount > 0)
        lastShipResult = result
        checkFanMilestones()
        save()
        return result
    }

    /// The whole team worked the one project, so the whole team learns from
    /// it — a better game teaches more. Growth leans toward whichever point
    /// type the project actually emphasised.
    private func growTeam(from project: GameProject, stars: Int) {
        let gain = max(1, stars - 1)
        for index in employees.indices {
            if project.focusBias >= 0.5 {
                employees[index].design = min(99, employees[index].design + gain)
            } else {
                employees[index].tech = min(99, employees[index].tech + gain)
            }
        }
    }

    /// One-time celebratory bumps as the studio's fan count crosses round
    /// numbers — a bit of texture between ships rather than a silent counter.
    private static let fanMilestones = [250, 750, 1_500, 3_000, 6_000, 12_000]

    private func checkFanMilestones() {
        for milestone in Self.fanMilestones where fans >= milestone && !milestonesReached.contains(milestone) {
            milestonesReached.insert(milestone)
            let bonus = milestone / 2
            cash += bonus
            lastMilestone = FanMilestone(fans: milestone, cashBonus: bonus)
        }
    }

    private static func reviewLine(stars: Int, name: String) -> String {
        switch stars {
        case 5: return "\"\(name) is the game of the year. Everyone is talking about it.\""
        case 4: return "\"\(name) is genuinely great. A few rough edges, nothing that matters.\""
        case 3: return "\"\(name) is solid. Worth a look if the genre's your thing.\""
        case 2: return "\"\(name) needed another month in the oven.\""
        default: return "\"\(name) shipped broken. Players noticed.\""
        }
    }

    // MARK: Hiring

    func refreshHiringBoard() {
        hiringBoard = (0..<3).map { _ in Employee.candidate(studioLevel: studioLevel) }
    }

    func canHire(_ candidate: Employee) -> Bool {
        cash >= candidate.signingFee && employees.count < deskCapacity
    }

    func hire(_ candidate: Employee) {
        guard canHire(candidate) else { return }
        cash -= candidate.signingFee
        employees.append(candidate)
        hiringBoard.removeAll { $0.id == candidate.id }
        save()
    }

    // MARK: The office ladder

    var nextUpgrade: StudioUpgrade? { StudioUpgrade.upgrade(toReach: studioLevel + 1) }

    func canUpgrade(to upgrade: StudioUpgrade) -> Bool {
        cash >= upgrade.cost && employees.count >= upgrade.staffRequired
    }

    func performUpgrade() {
        guard let upgrade = nextUpgrade, canUpgrade(to: upgrade) else { return }
        cash -= upgrade.cost
        studioLevel = upgrade.level
        refreshHiringBoard()
        save()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
