import Foundation

/// Scores a blackjack hand -- total value with aces counted as 11 wherever
/// that doesn't bust the hand, else knocked down to 1 one at a time
/// ("soft" vs "hard" totals).
enum BlackjackHandEvaluator {
    struct Value: Equatable {
        let total: Int
        /// True if at least one ace is still counting as 11 -- a "soft"
        /// total, which can't bust on the next card the way a hard total can.
        let isSoft: Bool
    }

    static func value(of cards: [Card]) -> Value {
        var total = 0
        var aces = 0
        for card in cards {
            total += card.rank.blackjackValue
            if card.rank == .ace { aces += 1 }
        }
        var softAcesRemaining = aces
        while total > 21 && softAcesRemaining > 0 {
            total -= 10
            softAcesRemaining -= 1
        }
        return Value(total: total, isSoft: softAcesRemaining > 0)
    }

    /// A natural blackjack is exactly ace + ten-value card as the first two
    /// cards dealt -- `canBeNatural` is false for hands created by splitting
    /// a pair, since a 21 built that way pays even money, not 3:2.
    static func isNatural(_ cards: [Card], canBeNatural: Bool) -> Bool {
        canBeNatural && cards.count == 2 && value(of: cards).total == 21
    }
}
