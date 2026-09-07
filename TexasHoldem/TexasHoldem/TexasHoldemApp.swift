import SwiftUI

@main
struct TexasHoldemApp: App {
    @StateObject private var bankroll = BankrollManager.shared
    @StateObject private var gameCenter = GameCenterManager.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(bankroll)
                .environmentObject(gameCenter)
                .preferredColorScheme(.dark)
                // No-ops (and loads nothing) unless the player has turned
                // the music up at some point.
                .task { AudioManager.shared.startIfEnabled() }
        }
    }
}
