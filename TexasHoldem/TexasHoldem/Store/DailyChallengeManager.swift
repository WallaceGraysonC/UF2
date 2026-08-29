import Foundation

enum ChallengeKind: String, Codable {
    case playHands
    case winHands
    case winPot
    case winWithCategory
}

struct DailyChallenge: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let kind: ChallengeKind
    let target: Int
    let xpReward: Int
    let chipReward: Int
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

        return [
            DailyChallenge(id: "\(dateKey).playHands", title: "Play \(handsTarget) Hands",
                            detail: "Play \(handsTarget) hands at any table.",
                            kind: .playHands, target: handsTarget, xpReward: 80, chipReward: 100),
            DailyChallenge(id: "\(dateKey).winHands", title: "Win \(winsTarget) Hands",
                            detail: "Win \(winsTarget) hands at any table.",
                            kind: .winHands, target: winsTarget, xpReward: 120, chipReward: 150),
            DailyChallenge(id: "\(dateKey).winPot", title: "Win a \(potTarget)+ Pot",
                            detail: "Win a single pot worth at least $\(potTarget).",
                            kind: .winPot, target: potTarget, xpReward: 100, chipReward: 150),
            DailyChallenge(id: "\(dateKey).category", title: "Win with \(category.1)",
                            detail: "Win a showdown holding \(category.1) or better.",
                            kind: .winWithCategory, target: category.0.rawValue, xpReward: 140, chipReward: 200),
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

/// Tracks today's three challenges and the player's progress toward each,
/// persisted locally so progress survives app restarts within the same day.
final class DailyChallengeManager: ObservableObject {
    static let shared = DailyChallengeManager()

    @Published private(set) var challenges: [DailyChallenge] = []
    @Published private(set) var progress: [String: Int] = [:]
    @Published private(set) var claimedIDs: Set<String> = []

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

    private func increment(_ kind: ChallengeKind, by amount: Int = 1, minimumTarget: Int = 0) {
        rolloverIfNeeded()
        for challenge in challenges where challenge.kind == kind {
            switch kind {
            case .winPot, .winWithCategory:
                // "At least" style challenges: only count if this single
                // event already clears the bar, tracked as a 0/1 flag.
                if minimumTarget >= challenge.target {
                    progress[challenge.id] = challenge.target
                }
            default:
                progress[challenge.id, default: 0] += amount
            }
        }
        persist()
    }

    func recordHandPlayed() { increment(.playHands) }
    func recordHandWon() { increment(.winHands) }
    func recordPotWon(amount: Int) { increment(.winPot, minimumTarget: amount) }
    func recordShowdownWin(category: HandCategory) { increment(.winWithCategory, minimumTarget: category.rawValue) }

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
