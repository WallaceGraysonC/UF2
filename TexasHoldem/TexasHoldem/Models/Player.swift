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
    var cardFaceID: String = CosmeticCatalog.defaultCardFace
    var avatarID: String = CosmeticCatalog.defaultAvatar
    var avatarFrameID: String = CosmeticCatalog.defaultAvatarFrame
    /// Fixed seat slot assigned once when a player sits down, independent of
    /// their live position in the engine's `players` array. Seat rendering
    /// keys off this instead of array index so a table with N starting
    /// seats keeps everyone in their original spot as others bust out,
    /// rather than reshuffling every remaining seat around a shrinking oval.
    var seatIndex: Int = 0

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
