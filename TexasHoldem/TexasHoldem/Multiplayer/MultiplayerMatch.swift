import Foundation
import GameKit
import Combine

/// Messages exchanged between host and peers over the GKMatch data channel.
enum NetworkMessage: Codable {
    case stateSync(GameState)
    case action(PlayerAction, playerID: String)
    case requestNewHand
    case showdown([ShowdownResultPayload])

    enum CodingKeys: String, CodingKey { case type, state, action, playerID, results }

    private enum Kind: String, Codable { case stateSync, action, requestNewHand, showdown }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .stateSync(let state):
            try container.encode(Kind.stateSync, forKey: .type)
            try container.encode(state, forKey: .state)
        case .action(let action, let playerID):
            try container.encode(Kind.action, forKey: .type)
            try container.encode(action, forKey: .action)
            try container.encode(playerID, forKey: .playerID)
        case .requestNewHand:
            try container.encode(Kind.requestNewHand, forKey: .type)
        case .showdown(let results):
            try container.encode(Kind.showdown, forKey: .type)
            try container.encode(results, forKey: .results)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .type)
        switch kind {
        case .stateSync:
            self = .stateSync(try container.decode(GameState.self, forKey: .state))
        case .action:
            self = .action(try container.decode(PlayerAction.self, forKey: .action),
                            playerID: try container.decode(String.self, forKey: .playerID))
        case .requestNewHand:
            self = .requestNewHand
        case .showdown:
            self = .showdown(try container.decode([ShowdownResultPayload].self, forKey: .results))
        }
    }
}

struct ShowdownResultPayload: Codable {
    var playerID: String
    var playerName: String
    var amountWon: Int
    var handDescription: String
}

/// Coordinates a live GKMatch with the local PokerEngine. The player who
/// creates the match acts as host and runs the authoritative engine; every
/// other participant is a thin client that sends actions to the host and
/// renders whatever `GameState` the host broadcasts.
final class MultiplayerMatch: ObservableObject {
    @Published private(set) var latestState: GameState?
    @Published private(set) var isHost: Bool
    @Published private(set) var connectedPlayerNames: [String] = []

    private let engine: PokerEngine?
    private let localPlayerID: String
    private let gameCenter = GameCenterManager.shared

    init(isHost: Bool, engine: PokerEngine?, localPlayerID: String) {
        self.isHost = isHost
        self.engine = engine
        self.localPlayerID = localPlayerID

        gameCenter.onReceiveData = { [weak self] data, senderID in
            self?.handle(data: data, from: senderID)
        }
    }

    // MARK: - Sending

    func sendAction(_ action: PlayerAction) {
        if isHost {
            engine?.apply(action, by: localPlayerID)
            broadcastState()
        } else {
            let message = NetworkMessage.action(action, playerID: localPlayerID)
            if let data = try? JSONEncoder().encode(message) {
                gameCenter.send(data)
            }
        }
    }

    func requestNewHand() {
        if isHost {
            engine?.startNextHand()
            broadcastState()
        } else {
            if let data = try? JSONEncoder().encode(NetworkMessage.requestNewHand) {
                gameCenter.send(data)
            }
        }
    }

    /// Sends every participant a personalized snapshot (their own hole cards
    /// visible, everyone else's hidden until showdown) rather than one
    /// identical broadcast, so peers can't see opponents' cards on the wire.
    private func broadcastState() {
        guard let engine else { return }
        latestState = engine.snapshot(for: localPlayerID)
        guard let match = gameCenter.match else { return }
        for player in match.players {
            let state = engine.snapshot(for: player.gamePlayerID)
            if let data = try? JSONEncoder().encode(NetworkMessage.stateSync(state)) {
                gameCenter.send(data, to: player)
            }
        }
    }

    // MARK: - Receiving

    private func handle(data: Data, from senderID: String) {
        guard let message = try? JSONDecoder().decode(NetworkMessage.self, from: data) else { return }
        switch message {
        case .stateSync(let state):
            DispatchQueue.main.async { self.latestState = state }
        case .action(let action, let playerID):
            guard isHost else { return }
            engine?.apply(action, by: playerID)
            broadcastState()
        case .requestNewHand:
            guard isHost else { return }
            engine?.startNextHand()
            broadcastState()
        case .showdown:
            break
        }
    }
}
