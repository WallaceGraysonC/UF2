import Foundation

/// Challenges are split into two tracks, each only advancing at the tables
/// it belongs to, so a tournament goal can't be knocked out at the cash
/// table and vice versa.
enum ChallengeTrack: String, Codable, CaseIterable, Hashable {
    case daily
    case tournament

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .tournament: return "Tournament"
        }
    }

    /// Where this track's challenges actually make progress -- shown on the
    /// screen so it's never a guess.
    var scopeNote: String {
        switch self {
        case .daily: return "Progress counts at the Play vs Bots table."
        case .tournament: return "Progress counts in Tournament and VIP High Stakes."
        }
    }
}

enum ChallengeKind: String, Codable {
    // Daily track -- the cash table
    case playHands
    case winHands
    case winBigHand
    case hitBlackjack
    // Tournament track
    case tournamentsPlayed
    case topThreeFinish
    case tournamentWin
    case deepRun

    var track: ChallengeTrack {
        switch self {
        case .playHands, .winHands, .winBigHand, .hitBlackjack: return .daily
        case .tournamentsPlayed, .topThreeFinish, .tournamentWin, .deepRun: return .tournament
        }
    }

    /// Threshold challenges are satisfied outright by one qualifying event
    /// ("win a $500 hand"), rather than counting up to a target.
    var isThreshold: Bool {
        switch self {
        case .winBigHand, .hitBlackjack, .deepRun: return true
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

/// Deterministic, date-seeded pool: every player sees the same four
/// challenges on a given calendar day, and they roll over at midnight.
private enum ChallengePool {
    static func generate(for dateKey: String) -> [DailyChallenge] {
        var rng = SeededGenerator(seed: dateKey.hashValue)

        let handsTarget = Int.random(in: 8...15, using: &rng)
        let winsTarget = Int.random(in: 3...6, using: &rng)
        let bigHandTarget = [100, 200, 300, 500].randomElement(using: &rng) ?? 200

        let tourneyTarget = Int.random(in: 2...3, using: &rng)
        let minBetTarget = [50, 75, 100].randomElement(using: &rng) ?? 75

        return [
            // MARK: Daily track -- the Play vs Bots table
            DailyChallenge(id: "\(dateKey).playHands", title: "Play \(handsTarget) Hands",
                            detail: "Play \(handsTarget) hands at the cash table.",
                            kind: .playHands, target: handsTarget, xpReward: 80, chipReward: 100),
            DailyChallenge(id: "\(dateKey).winHands", title: "Win \(winsTarget) Hands",
                            detail: "Win \(winsTarget) hands at the cash table.",
                            kind: .winHands, target: winsTarget, xpReward: 120, chipReward: 150),
            DailyChallenge(id: "\(dateKey).bigHand", title: "Win a $\(bigHandTarget)+ Hand",
                            detail: "Win a single hand worth at least $\(bigHandTarget).",
                            kind: .winBigHand, target: bigHandTarget, xpReward: 100, chipReward: 150),
            DailyChallenge(id: "\(dateKey).blackjack", title: "Hit a Blackjack",
                            detail: "Win a hand with a natural blackjack (Ace + 10-value card).",
                            kind: .hitBlackjack, target: 1, xpReward: 140, chipReward: 200),

            // MARK: Tournament track
            DailyChallenge(id: "\(dateKey).tourney.played", title: "Play \(tourneyTarget) Tournaments",
                            detail: "Sit down for \(tourneyTarget) tournaments and play them to the end.",
                            kind: .tournamentsPlayed, target: tourneyTarget, xpReward: 120, chipReward: 200),
            DailyChallenge(id: "\(dateKey).tourney.topThree", title: "Finish in the Money",
                            detail: "Place in the top 3 of a tournament.",
                            kind: .topThreeFinish, target: 1, xpReward: 160, chipReward: 250),
            DailyChallenge(id: "\(dateKey).tourney.deepRun", title: "Reach the $\(minBetTarget) Table Min",
                            detail: "Still be at the table when the minimum bet hits $\(minBetTarget).",
                            kind: .deepRun, target: minBetTarget, xpReward: 140, chipReward: 200),
            DailyChallenge(id: "\(dateKey).tourney.win", title: "Take It Down",
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
    func recordHandWon(amount: Int) {
        increment(.winHands)
        increment(.winBigHand, reached: amount)
    }
    func recordBlackjackWin() { increment(.hitBlackjack, reached: 1) }

    // MARK: Tournament track -- called when a tournament is settled

    /// Records one finished tournament. `placement` is 1 for an outright
    /// win, and `minBetReached` is the table minimum the player was still
    /// alive at, which is what the deep-run challenge measures.
    func recordTournamentFinish(placement: Int, minBetReached: Int) {
        increment(.tournamentsPlayed)
        increment(.deepRun, reached: minBetReached)
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
