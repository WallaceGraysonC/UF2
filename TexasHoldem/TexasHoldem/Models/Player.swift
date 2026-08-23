import Foundation

struct Player: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var chips: Int
    var holeCards: [Card] = []
    var currentBet: Int = 0
    var totalBetThisHand: Int = 0
    var isFolded: Bool = false
    var isAllIn: Bool = false
    var isBot: Bool = false
    var hasActedThisRound: Bool = false
    var cardBackID: String = CosmeticCatalog.defaultCardBack
    var avatarID: String = CosmeticCatalog.defaultAvatar

    var isEliminated: Bool { chips <= 0 && !isAllIn }

    mutating func resetForNewHand() {
        holeCards = []
        currentBet = 0
        totalBetThisHand = 0
        isFolded = false
        isAllIn = false
        hasActedThisRound = false
    }

    /// Puts chips into the pot, capping at the player's stack (handles all-in).
    @discardableResult
    mutating func bet(_ amount: Int) -> Int {
        let actual = min(amount, chips)
        chips -= actual
        currentBet += actual
        totalBetThisHand += actual
        if chips == 0 { isAllIn = true }
        return actual
    }
}
