import SwiftUI

/// Entry point for the watchOS companion app. This is bot-practice only --
/// no Game Center, no matchmaking -- just you, five bots, your two cards,
/// and the five community cards, sized for a wrist screen.
///
/// Setup: create a new "Watch App" target in Xcode (File > New > Target >
/// watchOS > Watch App), delete its placeholder ContentView/App files, then
/// add this folder's files to that target. Also give the new target
/// membership of these shared, GameKit/UIKit-free files from the iOS
/// target: Card.swift, Deck.swift, HandEvaluator.swift, Player.swift,
/// GameState.swift, PokerEngine.swift, EngineSnapshot.swift, BotAI.swift,
/// Cosmetic.swift, CosmeticPalettes.swift, BankrollManager.swift (select
/// each file in Xcode, check the watch target's box in the File Inspector's
/// Target Membership list). BankrollManager syncs via iCloud, so if you
/// keep it shared, chips earned on the watch reflect on the phone too.
@main
struct TexasHoldemWatchApp: App {
    @StateObject private var bankroll = BankrollManager.shared

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(bankroll)
        }
    }
}
