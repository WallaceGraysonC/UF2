import Foundation

/// Lightweight heuristic opponent used for offline practice tables.
/// Not meant to be unbeatable -- just enough to make solo play possible
/// with no server and no other humans required.
enum BotAI {
    /// `difficulty` only changes the thresholds below -- Easy calls too much
    /// and rarely bluffs (loose-passive, easy to beat), Normal is the
    /// original single-tier behavior, and Hard folds closer to true pot
    /// odds, value-bets/raises more often, and occasionally bluffs.
    static func decideAction(for player: Player, engine: PokerEngine, difficulty: BotDifficulty = .normal) -> PlayerAction {
        let toCall = engine.currentBet - player.currentBet
        let strength = handStrength(player: player, community: engine.communityCards)
        let potOdds = toCall == 0 ? 0 : Double(toCall) / Double(max(engine.potTotal, 1))

        switch difficulty {
        case .easy:
            if toCall == 0 {
                if strength > 0.85, player.chips > 0, Double.random(in: 0...1) < 0.3 {
                    return .bet(min(player.chips, max(engine.bigBlind, Int(Double(engine.potTotal) * 0.5))))
                }
                return .check
            }
            if strength < 0.15 && potOdds > 0.35 {
                return .fold
            }
            if strength > 0.9 && player.chips > toCall && Double.random(in: 0...1) < 0.3 {
                return .raise(engine.currentBet + max(engine.minRaise, toCall))
            }
            return .call

        case .normal:
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

        case .hard:
            if toCall == 0 {
                if strength > 0.6, player.chips > 0, Double.random(in: 0...1) < 0.75 {
                    return .bet(min(player.chips, max(engine.bigBlind, Int(Double(engine.potTotal) * 0.75))))
                }
                if strength < 0.35 && Double.random(in: 0...1) < 0.12 {
                    return .bet(min(player.chips, max(engine.bigBlind, Int(Double(engine.potTotal) * 0.5))))
                }
                return .check
            }
            if strength < potOdds * 0.9 {
                return .fold
            }
            if strength > 0.7 && player.chips > toCall && Double.random(in: 0...1) < 0.65 {
                return .raise(engine.currentBet + max(engine.minRaise, toCall))
            }
            return .call
        }
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
