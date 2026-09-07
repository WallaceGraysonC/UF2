import Foundation

struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let xpReward: Int
    let chipReward: Int
}

/// Permanent milestones -- unlike Daily Challenges, these never reset and
/// aren't tied to a calendar day. Checked cheaply against already-persisted
/// `StatsManager`/`BankrollManager` state, so `checkAll()` can be called
/// freely after any hand or session without extra bookkeeping.
enum AchievementCatalog {
    static let all: [Achievement] = [
        Achievement(id: "first_win", title: "First Blood", detail: "Win your first hand.",
                    icon: "star.fill", xpReward: 50, chipReward: 50),
        Achievement(id: "hands_100", title: "Grinder", detail: "Play 100 hands total.",
                    icon: "suit.club.fill", xpReward: 150, chipReward: 200),
        Achievement(id: "hands_500", title: "Regular", detail: "Play 500 hands total.",
                    icon: "suit.club.fill", xpReward: 300, chipReward: 500),
        Achievement(id: "big_pot_1000", title: "High Roller", detail: "Win a single pot of $1,000 or more.",
                    icon: "dollarsign.circle.fill", xpReward: 200, chipReward: 300),
        Achievement(id: "quads_plus", title: "Monster Hand", detail: "Win a showdown with Four of a Kind or better.",
                    icon: "flame.fill", xpReward: 250, chipReward: 350),
        Achievement(id: "sng_win", title: "Sit & Go Champion", detail: "Win a Sit & Go (or Turbo Sit & Go) tournament.",
                    icon: "trophy.fill", xpReward: 300, chipReward: 400),
        Achievement(id: "vip_win", title: "High Stakes Winner", detail: "Win a VIP High Stakes tournament.",
                    icon: "crown.fill", xpReward: 400, chipReward: 600),
        Achievement(id: "bankroll_5000", title: "Made It", detail: "Reach a lifetime peak of $5,000 chips.",
                    icon: "chart.line.uptrend.xyaxis", xpReward: 300, chipReward: 0),
        Achievement(id: "level_5", title: "VIP Access", detail: "Reach Level 5.",
                    icon: "star.circle.fill", xpReward: 0, chipReward: 250),
        Achievement(id: "hard_bot_win", title: "Outplayed", detail: "Win a hand at a Hard-difficulty table.",
                    icon: "brain.head.profile", xpReward: 150, chipReward: 200),
    ]
}

final class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published private(set) var unlockedIDs: Set<String> = []

    private let defaults = UserDefaults.standard
    private enum Keys { static let unlocked = "achievements.unlocked" }

    private init() {
        unlockedIDs = Set(defaults.stringArray(forKey: Keys.unlocked) ?? [])
    }

    func isUnlocked(_ achievement: Achievement) -> Bool { unlockedIDs.contains(achievement.id) }

    @discardableResult
    private func unlock(_ id: String) -> Bool {
        guard !unlockedIDs.contains(id), let achievement = AchievementCatalog.all.first(where: { $0.id == id }) else { return false }
        unlockedIDs.insert(id)
        defaults.set(Array(unlockedIDs), forKey: Keys.unlocked)
        if achievement.xpReward > 0 { BankrollManager.shared.addXP(achievement.xpReward) }
        if achievement.chipReward > 0 { BankrollManager.shared.applyDelta(achievement.chipReward) }
        return true
    }

    /// Threshold achievements -- safe to call after every hand or session.
    func checkAll() {
        let combined = StatsManager.shared.allModesCombined
        if combined.handsWon >= 1 { unlock("first_win") }
        if combined.handsPlayed >= 100 { unlock("hands_100") }
        if combined.handsPlayed >= 500 { unlock("hands_500") }
        if combined.biggestPotWon >= 1000 { unlock("big_pot_1000") }
        if BankrollManager.shared.highestChips >= 5000 { unlock("bankroll_5000") }
        if BankrollManager.shared.level >= 5 { unlock("level_5") }
        let sngWins = StatsManager.shared.stats(for: .sitAndGo).tournamentsWon
            + StatsManager.shared.stats(for: .turboSitAndGo).tournamentsWon
        if sngWins >= 1 { unlock("sng_win") }
        if StatsManager.shared.stats(for: .vipHighStakes).tournamentsWon >= 1 { unlock("vip_win") }
    }

    /// Event-triggered achievements that aren't a simple threshold check.
    func recordShowdownWin(category: HandCategory) {
        if category >= .fourOfAKind { unlock("quads_plus") }
    }

    func recordHardBotWin() { unlock("hard_bot_win") }
}
