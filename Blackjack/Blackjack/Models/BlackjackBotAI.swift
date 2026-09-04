import Foundation

/// Lightweight basic-strategy opponent used for offline practice tables.
/// Not meant to be a perfect counting/strategy engine -- just enough to
/// make solo play possible with no server and no other humans required,
/// the same spirit as the Hold'em bots.
enum BlackjackBotAI {
    /// Bets a semi-random amount within the table limits, biased toward
    /// the low end -- a bot that always shoves the max isn't a fun table.
    static func decideBet(chips: Int, minBet: Int, maxBet: Int) -> Int {
        let steps = Int.random(in: 0...3)
        let target = minBet + steps * minBet
        return min(chips, min(maxBet, target))
    }

    /// Basic strategy treats insurance as a bad bet regardless of the
    /// player's own hand -- the house edge on it is worse than the game
    /// itself -- so bots always decline.
    static func decideInsurance() -> Bool { false }

    static func decideAction(hand: BlackjackHand, dealerUpCard: Card, canDouble: Bool, canSplit: Bool, canSurrender: Bool) -> PlayerAction {
        let dealerValue = dealerUpCard.rank.blackjackValue
        let total = hand.total

        if canSplit, hand.cards.count == 2, hand.cards[0].rank == hand.cards[1].rank {
            switch hand.cards[0].rank {
            case .ace, .eight:
                return .split
            case .nine:
                if ![7, 10, 11].contains(dealerValue) { return .split }
            case .seven, .six:
                if dealerValue <= 7 { return .split }
            case .two, .three:
                if dealerValue <= 7 { return .split }
            default:
                break // never split 4s, 5s, or 10-value pairs
            }
        }

        if hand.isSoft {
            switch total {
            case 13, 14:
                if canDouble, (5...6).contains(dealerValue) { return .doubleDown }
                return .hit
            case 15, 16:
                if canDouble, (4...6).contains(dealerValue) { return .doubleDown }
                return .hit
            case 17:
                if canDouble, (3...6).contains(dealerValue) { return .doubleDown }
                return .hit
            case 18:
                if canDouble, (3...6).contains(dealerValue) { return .doubleDown }
                return dealerValue >= 9 ? .hit : .stand
            default:
                return .stand // soft 19+
            }
        }

        if canSurrender, total == 16, [9, 10, 11].contains(dealerValue) { return .surrender }
        if canSurrender, total == 15, dealerValue == 10 { return .surrender }

        switch total {
        case ..<9:
            return .hit
        case 9:
            if canDouble, (3...6).contains(dealerValue) { return .doubleDown }
            return .hit
        case 10:
            if canDouble, dealerValue <= 9 { return .doubleDown }
            return .hit
        case 11:
            return canDouble ? .doubleDown : .hit
        case 12:
            return (4...6).contains(dealerValue) ? .stand : .hit
        case 13...16:
            return dealerValue <= 6 ? .stand : .hit
        default:
            return .stand // hard 17+
        }
    }
}
