import Foundation

struct Deck {
    private(set) var cards: [Card]

    init() {
        cards = Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in Card(rank: rank, suit: suit) }
        }
        cards.shuffle()
    }

    /// Rebuilds a deck from a specific set of remaining cards, e.g. when
    /// restoring a saved in-progress hand. No reshuffling.
    init(cards: [Card]) {
        self.cards = cards
    }

    mutating func deal() -> Card? {
        cards.isEmpty ? nil : cards.removeLast()
    }

    mutating func deal(_ count: Int) -> [Card] {
        (0..<count).compactMap { _ in deal() }
    }
}
