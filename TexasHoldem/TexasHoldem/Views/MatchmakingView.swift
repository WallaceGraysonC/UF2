import SwiftUI
import GameKit

/// Presents Apple's Game Center matchmaker, which lets the player invite
/// friends directly or auto-match with other online players. On success it
/// hands back a live `GKMatch` that `MultiplayerMatch` drives.
struct MatchmakingView: UIViewControllerRepresentable {
    let onMatchFound: (GKMatch) -> Void
    let onCancelOrError: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> GKMatchmakerViewController {
        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = 8
        request.playerGroup = 1
        let vc = GKMatchmakerViewController(matchRequest: request)!
        vc.matchmakerDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKMatchmakerViewController, context: Context) {}

    final class Coordinator: NSObject, GKMatchmakerViewControllerDelegate {
        let parent: MatchmakingView
        init(_ parent: MatchmakingView) { self.parent = parent }

        func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
            viewController.dismiss(animated: true)
            parent.onCancelOrError()
        }

        func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
            viewController.dismiss(animated: true)
            parent.onCancelOrError()
        }

        func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
            viewController.dismiss(animated: true)
            parent.onMatchFound(match)
        }
    }
}
