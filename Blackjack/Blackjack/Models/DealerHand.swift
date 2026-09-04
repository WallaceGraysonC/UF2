import Foundation

/// The house's hand. Unlike every player's hand (always face up in
/// blackjack), the dealer's second card stays hidden until every player has
/// finished acting -- `holeCardRevealed` gates what `visibleCards` shows.
struct DealerHand: Codable {
    var cards: [Card] = []
    var holeCardRevealed: Bool = false

    var upCard: Card? { cards.first }
    var holeCard: Card? { cards.count > 1 ? cards[1] : nil }

    /// What should actually render at the table -- everything once revealed,
    /// otherwise just the up card.
    var visibleCards: [Card] { holeCardRevealed ? cards : Array(cards.prefix(1)) }

    var value: BlackjackHandEvaluator.Value { BlackjackHandEvaluator.value(of: cards) }
    var total: Int { value.total }
    var isBusted: Bool { total > 21 }
    var isBlackjack: Bool { BlackjackHandEvaluator.isNatural(cards, canBeNatural: true) }

    var displayTotal: String {
        guard holeCardRevealed else { return upCard.map { String($0.rank.blackjackValue) } ?? "" }
        if isBlackjack { return "Blackjack!" }
        if isBusted { return "Bust" }
        if value.isSoft && total != 21 { return "Soft \(total)" }
        return "\(total)"
    }
}
