import Foundation

enum RoundPhase: Int, Codable, CaseIterable {
    case betting, insurance, playerTurns, dealerTurn, payout
}

enum PlayerAction: Codable, Equatable {
    case placeBet(Int)
    case hit
    case stand
    case doubleDown
    case split
    case surrender
    case insurance(Bool)
}

enum HandOutcome: String, Codable {
    case blackjack, win, push, lose, bust, surrender

    var displayText: String {
        switch self {
        case .blackjack: return "Blackjack!"
        case .win: return "Win"
        case .push: return "Push"
        case .lose: return "Lose"
        case .bust: return "Bust"
        case .surrender: return "Surrender"
        }
    }
}

struct RoundResult: Identifiable, Codable {
    var id = UUID()
    var playerID: String
    var playerName: String
    var handIndex: Int
    var outcome: HandOutcome
    /// What came back to the player for this hand, including their own
    /// returned bet where applicable -- 0 for a clean loss, `bet` for a
    /// push, `bet * 2` for an even-money win, `bet * 2.5` for a natural.
    var amountReturned: Int
    var handTotal: Int
}

/// Snapshot of the table, safe to broadcast to remote players -- the
/// dealer's hole card is stripped out until it's actually revealed, but
/// every player's own hand is public information in blackjack, so (unlike
/// Hold'em hole cards) nothing about a player needs to be hidden from peers.
struct GameState: Codable {
    var players: [Player]
    var dealer: DealerHand
    var phase: RoundPhase
    var activePlayerIndex: Int?
    var activeHandIndex: Int
    var minBet: Int
    var maxBet: Int
    var roundNumber: Int
    var lastActionDescription: String
    var roundResults: [RoundResult]
}

extension GameState {
    /// These four mirror `BlackjackEngine`'s equivalents exactly, for use on
    /// a synced snapshot -- a multiplayer peer only ever sees a `GameState`,
    /// never the host's live engine, so the UI needs its own read-only copy
    /// of "what can I do right now" to drive the action buttons.
    var currentPlayer: Player? {
        guard let idx = activePlayerIndex, players.indices.contains(idx) else { return nil }
        return players[idx]
    }

    var currentHand: BlackjackHand? {
        guard let player = currentPlayer, player.hands.indices.contains(activeHandIndex) else { return nil }
        return player.hands[activeHandIndex]
    }

    var canDoubleDownNow: Bool {
        guard phase == .playerTurns, let hand = currentHand, let player = currentPlayer else { return false }
        return hand.cards.count == 2 && !hand.isDoubled && !hand.isSplitAceHand && player.chips >= hand.bet
    }

    var canSplitNow: Bool {
        guard phase == .playerTurns, let hand = currentHand, let player = currentPlayer,
              hand.cards.count == 2, hand.cards[0].rank == hand.cards[1].rank else { return false }
        return player.hands.count < BlackjackEngine.maxHandsPerPlayer && player.chips >= hand.bet
    }

    var canSurrenderNow: Bool {
        guard phase == .playerTurns, let hand = currentHand else { return false }
        return hand.canBeNatural && hand.cards.count == 2
    }
}
