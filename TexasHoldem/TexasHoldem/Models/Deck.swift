import Foundation

struct Deck {
    private(set) var cards: [Card]

    init() {
        cards = Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in Card(rank: rank, suit: suit) }
        }
        cards.shuffle()
    }

    mutating func deal() -> Card? {
        cards.isEmpty ? nil : cards.removeLast()
    }

    mutating func deal(_ count: Int) -> [Card] {
        (0..<count).compactMap { _ in deal() }
    }
}
