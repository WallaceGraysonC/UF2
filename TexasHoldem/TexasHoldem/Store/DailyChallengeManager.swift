import Foundation

/// Challenges are split into two tracks, each only advancing at the tables
/// it belongs to, so a tournament goal can't be knocked out at the cash
/// table and vice versa.
enum ChallengeTrack: String, Codable, CaseIterable, Hashable {
    case daily
    case sitAndGo

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .sitAndGo: return "Sit & Go"
        }
    }

    /// Where this track's challenges actually make progress -- shown on the
    /// screen so it's never a guess.
    var scopeNote: String {
        switch self {
        case .daily: return "Progress counts at the Play vs Bots table."
        case .sitAndGo: return "Progress counts in Sit & Go and VIP High Stakes."
        }
    }
}

enum ChallengeKind: String, Codable {
    // Daily track -- the cash table
    case playHands
    case winHands
    case winPot
    case winWithCategory
    // Sit & Go track -- tournaments
    case tournamentsPlayed
    case topThreeFinish
    case tournamentWin
    case deepRun

    var track: ChallengeTrack {
        switch self {
        case .playHands, .winHands, .winPot, .winWithCategory: return .daily
        case .tournamentsPlayed, .topThreeFinish, .tournamentWin, .deepRun: return .sitAndGo
        }
    }

    /// Threshold challenges are satisfied outright by one qualifying event
    /// ("win a $500 pot"), rather than counting up to a target.
    var isThreshold: Bool {
        switch self {
        case .winPot, .winWithCategory, .deepRun: return true
        default: return false
        }
    }
}

struct DailyChallenge: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let kind: ChallengeKind
    let target: Int
    let xpReward: Int
    let chipReward: Int

    var track: ChallengeTrack { kind.track }
}

/// Deterministic, date-seeded pool: every player sees the same three
/// challenges on a given calendar day, and they roll over at midnight.
private enum ChallengePool {
    static func generate(for dateKey: String) -> [DailyChallenge] {
        var rng = SeededGenerator(seed: dateKey.hashValue)

        let handsTarget = Int.random(in: 8...15, using: &rng)
        let winsTarget = Int.random(in: 2...4, using: &rng)
        let potTarget = [300, 500, 750, 1000].randomElement(using: &rng) ?? 500
        let categoryOptions: [(HandCategory, String)] = [
            (.threeOfAKind, "Three of a Kind"), (.straight, "a Straight"),
            (.flush, "a Flush"), (.fullHouse, "a Full House")
        ]
        let category = categoryOptions.randomElement(using: &rng) ?? (.threeOfAKind, "Three of a Kind")

        let tourneyTarget = Int.random(in: 2...3, using: &rng)
        let blindTarget = [50, 75, 100].randomElement(using: &rng) ?? 75

        return [
            // MARK: Daily track -- the Play vs Bots table
            DailyChallenge(id: "\(dateKey).playHands", title: "Play \(handsTarget) Hands",
                            detail: "Play \(handsTarget) hands at the cash table.",
                            kind: .playHands, target: handsTarget, xpReward: 80, chipReward: 100),
            DailyChallenge(id: "\(dateKey).winHands", title: "Win \(winsTarget) Hands",
                            detail: "Win \(winsTarget) hands at the cash table.",
                            kind: .winHands, target: winsTarget, xpReward: 120, chipReward: 150),
            DailyChallenge(id: "\(dateKey).winPot", title: "Win a \(potTarget)+ Pot",
                            detail: "Win a single pot worth at least $\(potTarget).",
                            kind: .winPot, target: potTarget, xpReward: 100, chipReward: 150),
            DailyChallenge(id: "\(dateKey).category", title: "Win with \(category.1)",
                            detail: "Win a showdown holding \(category.1) or better.",
                            kind: .winWithCategory, target: category.0.rawValue, xpReward: 140, chipReward: 200),

            // MARK: Sit & Go track -- tournaments
            DailyChallenge(id: "\(dateKey).sng.played", title: "Play \(tourneyTarget) Tournaments",
                            detail: "Sit down for \(tourneyTarget) Sit & Gos and play them to the end.",
                            kind: .tournamentsPlayed, target: tourneyTarget, xpReward: 120, chipReward: 200),
            DailyChallenge(id: "\(dateKey).sng.topThree", title: "Finish in the Money",
                            detail: "Place in the top 3 of a tournament.",
                            kind: .topThreeFinish, target: 1, xpReward: 160, chipReward: 250),
            DailyChallenge(id: "\(dateKey).sng.deepRun", title: "Reach the $\(blindTarget) Blinds",
                            detail: "Still be at the table when the big blind hits $\(blindTarget).",
                            kind: .deepRun, target: blindTarget, xpReward: 140, chipReward: 200),
            DailyChallenge(id: "\(dateKey).sng.win", title: "Take It Down",
                            detail: "Win a tournament outright.",
                            kind: .tournamentWin, target: 1, xpReward: 250, chipReward: 400),
        ]
    }
}

/// Tiny deterministic PRNG so the same seed always produces the same
/// sequence -- `Int.random`/`.randomElement` accept any `RandomNumberGenerator`.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: Int) { state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

/// Tracks today's challenges and the player's progress toward each,
/// persisted locally so progress survives app restarts within the same day.
final class DailyChallengeManager: ObservableObject {
    static let shared = DailyChallengeManager()

    @Published private(set) var challenges: [DailyChallenge] = []
    @Published private(set) var progress: [String: Int] = [:]
    @Published private(set) var claimedIDs: Set<String> = []

    func challenges(in track: ChallengeTrack) -> [DailyChallenge] {
        challenges.filter { $0.track == track }
    }

    /// How many of a track's challenges are finished but not yet claimed --
    /// drives the "ready to collect" badge.
    func unclaimedCount(in track: ChallengeTrack) -> Int {
        challenges(in: track).filter { isComplete($0) && !isClaimed($0) }.count
    }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let dateKey = "challenges.dateKey"
        static let progress = "challenges.progress"
        static let claimed = "challenges.claimed"
    }

    private static var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }

    private init() {
        rolloverIfNeeded()
    }

    /// Regenerates the challenge set if the calendar day has changed since
    /// the last launch/check, clearing yesterday's progress.
    private func rolloverIfNeeded() {
        let today = Self.todayKey
        let savedKey = defaults.string(forKey: Keys.dateKey)
        challenges = ChallengePool.generate(for: today)
        if savedKey == today {
            progress = (defaults.dictionary(forKey: Keys.progress) as? [String: Int]) ?? [:]
            claimedIDs = Set(defaults.stringArray(forKey: Keys.claimed) ?? [])
        } else {
            progress = [:]
            claimedIDs = []
            defaults.set(today, forKey: Keys.dateKey)
            persist()
        }
    }

    private func persist() {
        defaults.set(progress, forKey: Keys.progress)
        defaults.set(Array(claimedIDs), forKey: Keys.claimed)
    }

    func progressValue(for challenge: DailyChallenge) -> Int {
        min(progress[challenge.id] ?? 0, challenge.target)
    }

    func isComplete(_ challenge: DailyChallenge) -> Bool {
        progressValue(for: challenge) >= challenge.target
    }

    func isClaimed(_ challenge: DailyChallenge) -> Bool {
        claimedIDs.contains(challenge.id)
    }

    private func increment(_ kind: ChallengeKind, by amount: Int = 1, reached: Int = 0) {
        rolloverIfNeeded()
        for challenge in challenges where challenge.kind == kind {
            if kind.isThreshold {
                // "At least" style: one event that clears the bar finishes it
                // outright, so it's tracked as a 0/1 flag rather than a count.
                if reached >= challenge.target {
                    progress[challenge.id] = challenge.target
                }
            } else {
                progress[challenge.id, default: 0] += amount
            }
        }
        persist()
    }

    // MARK: Daily track -- called from the Play vs Bots table only

    func recordHandPlayed() { increment(.playHands) }
    func recordHandWon() { increment(.winHands) }
    func recordPotWon(amount: Int) { increment(.winPot, reached: amount) }
    func recordShowdownWin(category: HandCategory) { increment(.winWithCategory, reached: category.rawValue) }

    // MARK: Sit & Go track -- called when a tournament is settled

    /// Records one finished tournament. `placement` is 1 for an outright
    /// win, and `bigBlindReached` is the blind level the player was still
    /// alive at, which is what the deep-run challenge measures.
    func recordTournamentFinish(placement: Int, bigBlindReached: Int) {
        increment(.tournamentsPlayed)
        increment(.deepRun, reached: bigBlindReached)
        if placement <= 3 { increment(.topThreeFinish) }
        if placement == 1 { increment(.tournamentWin) }
    }

    /// Grants the challenge's reward once, then marks it claimed. Returns
    /// the (xp, chips) awarded, or nil if it wasn't ready to claim.
    @discardableResult
    func claim(_ challenge: DailyChallenge) -> (xp: Int, chips: Int)? {
        guard isComplete(challenge), !isClaimed(challenge) else { return nil }
        claimedIDs.insert(challenge.id)
        persist()
        BankrollManager.shared.addXP(challenge.xpReward)
        BankrollManager.shared.applyDelta(challenge.chipReward)
        return (challenge.xpReward, challenge.chipReward)
    }
}
