import Foundation

/// Everything needed to rebuild a `PokerEngine` exactly as it was,
/// including cards already dealt and the exact remaining deck order, so a
/// saved-and-resumed hand deals identically to how it would have continued.
struct EngineSnapshot: Codable {
    var players: [Player]
    var communityCards: [Card]
    var round: BettingRound
    var dealerIndex: Int
    var activePlayerIndex: Int?
    var currentBet: Int
    var minRaise: Int
    var handNumber: Int
    var lastActionDescription: String
    var showdownResults: [ShowdownResult]
    var isHandInProgress: Bool
    var deckRemaining: [Card]
    var pots: [PotShare]
    var playersActedThisRound: [String]
    var smallBlind: Int
    var bigBlind: Int
}
