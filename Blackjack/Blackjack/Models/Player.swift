import Foundation

/// One hand in front of a player. A player starts each round with exactly
/// one; splitting a pair adds a second (rarely a third or fourth -- see
/// `BlackjackEngine.maxHandsPerPlayer`).
struct BlackjackHand: Identifiable, Codable, Hashable {
    var id: String
    var cards: [Card] = []
    var bet: Int = 0
    var isDoubled: Bool = false
    var isSurrendered: Bool = false
    var isStood: Bool = false
    /// False for a hand created by splitting a pair -- a 21 built that way
    /// is just 21, not a natural blackjack, so it pays even money rather
    /// than 3:2.
    var canBeNatural: Bool = true
    /// A hand created by splitting a pair of aces: standard rules deal it
    /// exactly one more card and lock it there, no further hitting.
    var isSplitAceHand: Bool = false

    var value: BlackjackHandEvaluator.Value { BlackjackHandEvaluator.value(of: cards) }
    var total: Int { value.total }
    var isSoft: Bool { value.isSoft }
    var isBusted: Bool { total > 21 }
    var isBlackjack: Bool { BlackjackHandEvaluator.isNatural(cards, canBeNatural: canBeNatural) }

    /// Nothing left to decide on this hand -- it's done acting and just
    /// waits for the dealer.
    var isResolved: Bool {
        isBusted || isStood || isSurrendered || isBlackjack
            || (isSplitAceHand && cards.count >= 2)
            || (isDoubled && cards.count >= 3)
    }

    /// Short status text shown on the seat -- "21", "Bust", "Blackjack!",
    /// "Soft 18", etc.
    var displayTotal: String {
        if cards.isEmpty { return "" }
        if isBlackjack { return "Blackjack!" }
        if isBusted { return "Bust" }
        if isSoft && total != 21 { return "Soft \(total)" }
        return "\(total)"
    }
}

struct Player: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var chips: Int
    var hands: [BlackjackHand] = []
    var insuranceBet: Int = 0
    var hasDecidedInsurance: Bool = false
    var isBot: Bool = false
    var cardBackID: String = CosmeticCatalog.defaultCardBack
    var cardFaceID: String = CosmeticCatalog.defaultCardFace
    var avatarID: String = CosmeticCatalog.defaultAvatar
    var avatarFrameID: String = CosmeticCatalog.defaultAvatarFrame
    /// Fixed seat slot assigned once when a player sits down -- seat
    /// rendering keys off this instead of live array index so a table keeps
    /// everyone in their original spot as others bust out, rather than
    /// reshuffling every remaining seat around a shrinking table.
    var seatIndex: Int = 0

    var isEliminated: Bool { chips <= 0 }

    mutating func resetForNewRound() {
        hands = []
        insuranceBet = 0
        hasDecidedInsurance = false
    }
}
