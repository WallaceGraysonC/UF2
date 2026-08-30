import SwiftUI

/// Entry point for the watchOS companion app. This is bot-practice only --
/// no Game Center, no matchmaking -- just you, a few bots, your two cards,
/// and the five community cards, sized for a wrist screen. Every cosmetic
/// equipped on the phone (card faces, felt, avatars, ...) renders here too,
/// since it all reads from the same shared `BankrollManager`.
///
/// Setup: create a new "Watch App" target in Xcode (File > New > Target >
/// watchOS > Watch App), delete its placeholder ContentView/App files, then
/// add this folder's files to that target. Also give the new target
/// membership of these shared files from the iOS target (select each file
/// in Xcode, check the watch target's box in the File Inspector's Target
/// Membership list):
///   Card.swift, Deck.swift, HandEvaluator.swift, Player.swift,
///   GameState.swift, PokerEngine.swift, EngineSnapshot.swift,
///   GamePersistence.swift, BotAI.swift, Cosmetic.swift,
///   CosmeticPalettes.swift, CustomCosmeticStore.swift, BankrollManager.swift,
///   PATheme.swift
/// None of these use GameKit or any other iOS-only framework -- the couple
/// that reference `UIImage` (for the Custom Photo cosmetic slot) are fine,
/// since UIImage itself has been available on watchOS since watchOS 2.
///
/// BankrollManager syncs via iCloud, so with it shared: chips, XP, and
/// which cosmetic is *equipped* in each category all carry over between
/// phone and watch automatically. The one thing that does NOT carry over
/// is an uploaded Custom Photo's actual image data -- those are saved to
/// local disk on whichever device you uploaded them on, not iCloud (a
/// photo is far too big for the key-value store), so a custom photo
/// equipped on the phone just falls back to that category's built-in look
/// on the watch rather than failing to render.
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
