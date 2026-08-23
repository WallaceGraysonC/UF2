import Foundation

enum BettingRound: Int, Codable, CaseIterable {
    case preFlop, flop, turn, river, showdown
}

enum PlayerAction: Codable, Equatable {
    case fold
    case check
    case call
    case bet(Int)
    case raise(Int)
    case allIn
}

struct PotShare: Identifiable {
    var id: Int
    var amount: Int
    var eligiblePlayerIDs: Set<String>
}

struct ShowdownResult: Identifiable {
    var id = UUID()
    var playerID: String
    var playerName: String
    var hand: HandRank
    var amountWon: Int
}

/// Snapshot of the table, safe to broadcast to remote players
/// (does not reveal other players' hole cards unless it's showdown).
struct GameState: Codable {
    var players: [Player]
    var communityCards: [Card]
    var round: BettingRound
    var potTotal: Int
    var dealerIndex: Int
    var activePlayerIndex: Int?
    var currentBet: Int
    var minRaise: Int
    var smallBlind: Int
    var bigBlind: Int
    var handNumber: Int
    var lastActionDescription: String
}
