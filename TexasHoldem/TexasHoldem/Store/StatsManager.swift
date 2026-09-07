import Foundation

/// The distinct tables a hand can be recorded against. "Play with Friends"
/// isn't included -- it's host-authoritative multiplayer, and reliably
/// attributing a result to the local player from there is a separate piece
/// of work, not a Just-add-a-case change.
enum GameModeID: String, Codable, CaseIterable, Identifiable, Hashable {
    case playVsBots, customTable, sitAndGo, turboSitAndGo, vipHighStakes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .playVsBots: return "Play vs Bots"
        case .customTable: return "Custom Table"
        case .sitAndGo: return "Sit & Go"
        case .turboSitAndGo: return "Turbo Sit & Go"
        case .vipHighStakes: return "VIP High Stakes"
        }
    }

    var isTournament: Bool {
        switch self {
        case .sitAndGo, .turboSitAndGo, .vipHighStakes: return true
        case .playVsBots, .customTable: return false
        }
    }
}

/// Lifetime counters for one game mode. `totalWon` is the sum of amounts
/// actually won at showdown/by-fold in this mode -- it's a "how much have
/// you brought in" figure, not a true net profit/loss (that would need
/// tracking every chip put in on hands you didn't win too).
struct ModeStats: Codable, Equatable {
    var handsPlayed = 0
    var handsWon = 0
    var biggestPotWon = 0
    var totalWon = 0
    var tournamentsPlayed = 0
    var tournamentsWon = 0
    /// Lower is better (1 = won outright). Nil until a tournament in this
    /// mode has been finished at least once.
    var bestFinish: Int?

    static func += (lhs: inout ModeStats, rhs: ModeStats) {
        lhs.handsPlayed += rhs.handsPlayed
        lhs.handsWon += rhs.handsWon
        lhs.biggestPotWon = max(lhs.biggestPotWon, rhs.biggestPotWon)
        lhs.totalWon += rhs.totalWon
        lhs.tournamentsPlayed += rhs.tournamentsPlayed
        lhs.tournamentsWon += rhs.tournamentsWon
        if let rBest = rhs.bestFinish {
            lhs.bestFinish = min(lhs.bestFinish ?? rBest, rBest)
        }
    }
}

struct HandHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let mode: GameModeID
    let date: Date
    let summary: String
    /// Amount won this hand, or 0 if it wasn't won.
    let amountWon: Int

    init(id: UUID = UUID(), mode: GameModeID, date: Date = Date(), summary: String, amountWon: Int) {
        self.id = id
        self.mode = mode
        self.date = date
        self.summary = summary
        self.amountWon = amountWon
    }
}

/// Tracks per-mode lifetime stats and a rolling hand history, fed by
/// `LocalGameView` as hands and tournaments finish. Purely a personal
/// record -- like Daily Challenges, it's local-only (not synced to iCloud)
/// and never feeds back into the bankroll itself.
final class StatsManager: ObservableObject {
    static let shared = StatsManager()

    @Published private(set) var stats: [GameModeID: ModeStats] = [:]
    @Published private(set) var history: [HandHistoryEntry] = []

    private let defaults = UserDefaults.standard
    private let maxHistory = 200
    private enum Keys {
        static let stats = "stats.byMode"
        static let history = "stats.history"
    }

    private init() {
        if let data = defaults.data(forKey: Keys.stats),
           let decoded = try? JSONDecoder().decode([GameModeID: ModeStats].self, from: data) {
            stats = decoded
        }
        if let data = defaults.data(forKey: Keys.history),
           let decoded = try? JSONDecoder().decode([HandHistoryEntry].self, from: data) {
            history = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(stats) { defaults.set(data, forKey: Keys.stats) }
        if let data = try? JSONEncoder().encode(history) { defaults.set(data, forKey: Keys.history) }
    }

    func stats(for mode: GameModeID) -> ModeStats { stats[mode] ?? ModeStats() }

    /// Every mode's counters rolled into one -- used for the "All Modes"
    /// row in the Stats screen and for achievement thresholds that don't
    /// care which table you earned them at.
    var allModesCombined: ModeStats {
        var total = ModeStats()
        for s in stats.values { total += s }
        return total
    }

    func recordHand(mode: GameModeID, won: Bool, amountWon: Int, summary: String) {
        var s = stats[mode] ?? ModeStats()
        s.handsPlayed += 1
        if won {
            s.handsWon += 1
            s.biggestPotWon = max(s.biggestPotWon, amountWon)
            s.totalWon += amountWon
        }
        stats[mode] = s

        history.insert(HandHistoryEntry(mode: mode, summary: summary, amountWon: won ? amountWon : 0), at: 0)
        if history.count > maxHistory { history.removeLast(history.count - maxHistory) }
        persist()
    }

    func recordTournamentFinish(mode: GameModeID, placement: Int) {
        var s = stats[mode] ?? ModeStats()
        s.tournamentsPlayed += 1
        if placement == 1 { s.tournamentsWon += 1 }
        s.bestFinish = min(s.bestFinish ?? placement, placement)
        stats[mode] = s
        persist()
    }

    /// Most-recent-first, optionally filtered to one mode.
    func history(for mode: GameModeID?) -> [HandHistoryEntry] {
        guard let mode else { return history }
        return history.filter { $0.mode == mode }
    }

    /// Wipes stats/history for one mode, or everything when `mode` is nil.
    func reset(mode: GameModeID?) {
        if let mode {
            stats[mode] = nil
            history.removeAll { $0.mode == mode }
        } else {
            stats = [:]
            history = []
        }
        persist()
    }
}
