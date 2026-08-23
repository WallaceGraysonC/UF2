import Foundation

/// Lightweight heuristic opponent used for offline practice tables.
/// Not meant to be unbeatable -- just enough to make solo play possible
/// with no server and no other humans required.
enum BotAI {
    static func decideAction(for player: Player, engine: PokerEngine) -> PlayerAction {
        let toCall = engine.currentBet - player.currentBet
        let strength = handStrength(player: player, community: engine.communityCards)
        let potOdds = toCall == 0 ? 0 : Double(toCall) / Double(max(engine.potTotal, 1))

        if toCall == 0 {
            if strength > 0.72, player.chips > 0, Double.random(in: 0...1) < 0.6 {
                return .bet(min(player.chips, max(engine.bigBlind, Int(Double(engine.potTotal) * 0.6))))
            }
            return .check
        }

        if strength < 0.25 && potOdds > 0.15 {
            return .fold
        }
        if strength > 0.8 && player.chips > toCall && Double.random(in: 0...1) < 0.5 {
            return .raise(engine.currentBet + max(engine.minRaise, toCall))
        }
        if strength < potOdds {
            return .fold
        }
        return .call
    }

    /// Very rough 0...1 strength estimate: preflop uses hole-card heuristics,
    /// postflop uses actual hand category against a normalized scale.
    private static func handStrength(player: Player, community: [Card]) -> Double {
        guard !community.isEmpty else {
            return preflopStrength(player.holeCards)
        }
        let allCards = player.holeCards + community
        guard allCards.count >= 5 else { return 0.4 }
        let rank = HandEvaluator.bestHand(from: allCards)
        return Double(rank.category.rawValue) / Double(HandCategory.straightFlush.rawValue)
    }

    private static func preflopStrength(_ cards: [Card]) -> Double {
        guard cards.count == 2 else { return 0.3 }
        let a = cards[0], b = cards[1]
        var score = Double(max(a.rank.rawValue, b.rank.rawValue)) / 14.0
        if a.rank == b.rank { score += 0.25 }
        if a.suit == b.suit { score += 0.08 }
        let gap = abs(a.rank.rawValue - b.rank.rawValue)
        if gap == 1 { score += 0.05 }
        return min(score, 1.0)
    }
}
