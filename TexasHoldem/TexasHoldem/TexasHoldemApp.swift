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
        }
    }
}
