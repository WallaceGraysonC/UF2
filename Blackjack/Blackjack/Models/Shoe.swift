import Foundation

/// A multi-deck dealing shoe, the way a real casino blackjack table deals
/// from several decks mixed together rather than a single 52-card deck --
/// mostly so the count of any one rank left in play stays high enough that
/// card counting isn't a meaningfully exploitable strategy against `BlackjackBotAI`.
struct Shoe: Codable {
    private(set) var cards: [Card]
    let deckCount: Int

    init(deckCount: Int = 6) {
        self.deckCount = deckCount
        cards = (0..<deckCount).flatMap { _ in
            Suit.allCases.flatMap { suit in
                Rank.allCases.map { rank in Card(rank: rank, suit: suit) }
            }
        }
        cards.shuffle()
    }

    /// Rebuilds a shoe from a specific set of remaining cards, e.g. when
    /// restoring a saved in-progress round. No reshuffling.
    init(cards: [Card], deckCount: Int) {
        self.cards = cards
        self.deckCount = deckCount
    }

    mutating func deal() -> Card? {
        cards.isEmpty ? nil : cards.removeLast()
    }

    /// True once the shoe has burned through roughly three quarters of its
    /// cards -- the point a real table's cut card would trigger a reshuffle.
    /// Checked between rounds, never mid-round, so a hand in progress never
    /// has cards vanish out from under it.
    var needsReshuffle: Bool { cards.count < deckCount * 52 / 4 }

    mutating func reshuffleFresh() {
        self = Shoe(deckCount: deckCount)
    }
}
