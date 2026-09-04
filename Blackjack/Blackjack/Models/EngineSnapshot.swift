import Foundation

/// Everything needed to rebuild a `BlackjackEngine` exactly as it was,
/// including cards already dealt and the exact remaining shoe order, so a
/// saved-and-resumed round deals identically to how it would have continued.
struct EngineSnapshot: Codable {
    var players: [Player]
    var dealer: DealerHand
    var phase: RoundPhase
    var activePlayerIndex: Int?
    var activeHandIndex: Int
    var roundNumber: Int
    var lastActionDescription: String
    var roundResults: [RoundResult]
    var isRoundInProgress: Bool
    var shoeRemaining: [Card]
    var deckCount: Int
    var minBet: Int
    var maxBet: Int
}
