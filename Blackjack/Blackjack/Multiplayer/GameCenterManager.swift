import Foundation
import GameKit
import Combine
import UIKit

/// Wraps Game Center authentication and real-time matchmaking so players can
/// invite friends from their Game Center friends list. This uses Apple's
/// free, built-in GameKit framework -- no third-party server, accounts, ads,
/// or purchases involved.
final class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()

    @Published private(set) var isAuthenticated = false
    @Published private(set) var localPlayerName: String = "You"
    @Published var authenticationViewController: UIViewController?

    var match: GKMatch? {
        didSet { match?.delegate = self }
    }

    /// Called with decoded action payloads received from peers.
    var onReceiveData: ((Data, String) -> Void)?
    var onPlayerDisconnected: ((String) -> Void)?

    private override init() { super.init() }

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            if let viewController {
                self.authenticationViewController = viewController
            } else if GKLocalPlayer.local.isAuthenticated {
                self.isAuthenticated = true
                self.localPlayerName = GKLocalPlayer.local.displayName
            } else {
                self.isAuthenticated = false
                if let error { print("Game Center auth failed: \(error.localizedDescription)") }
            }
        }
    }

    /// Presents Apple's built-in matchmaker UI, which lets the player invite
    /// friends, auto-match with others, or start a private match.
    func makeMatchmakerViewController(minPlayers: Int = 2, maxPlayers: Int = 7, delegate: GKMatchmakerViewControllerDelegate) -> GKMatchmakerViewController? {
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        request.playerGroup = 1
        guard let vc = GKMatchmakerViewController(matchRequest: request) else { return nil }
        vc.matchmakerDelegate = delegate
        return vc
    }

    func send(_ data: Data, reliable: Bool = true) {
        guard let match else { return }
        try? match.sendData(toAllPlayers: data, with: reliable ? .reliable : .unreliable)
    }

    /// Sends data to a single remote participant.
    func send(_ data: Data, to player: GKPlayer, reliable: Bool = true) {
        guard let match else { return }
        try? match.send(data, to: [player], dataMode: reliable ? .reliable : .unreliable)
    }

    func disconnect() {
        match?.disconnect()
        match = nil
    }
}

extension GameCenterManager: GKMatchDelegate {
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        onReceiveData?(data, player.gamePlayerID)
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        if state == .disconnected {
            onPlayerDisconnected?(player.gamePlayerID)
        }
    }
}
