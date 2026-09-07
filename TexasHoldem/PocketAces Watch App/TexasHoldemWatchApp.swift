import SwiftUI

/// Entry point for the watchOS companion app. This is bot-practice only --
/// no Game Center, no matchmaking -- just you, a few bots, your two cards,
/// and the five community cards, sized for a wrist screen. It shares its
/// domain layer (`PokerEngine`, `BankrollManager`, etc.) with the iOS app
/// via target membership on the same files under `TexasHoldem/Models/` and
/// `TexasHoldem/Store/` -- see the project README for the full list. None
/// of those use GameKit or any other iOS-only framework -- the couple that
/// reference `UIImage` (for the Custom Photo cosmetic slot) are fine, since
/// UIImage itself has been available on watchOS since watchOS 2.
///
/// The watch's chip balance, lifetime peak, and XP are deliberately
/// device-local -- an "exhibition" stack for quick bot practice on the
/// wrist that can neither drain nor inflate the phone's real bankroll (see
/// `BankrollManager.write(_:forKey:cloudSynced:)` and
/// `pullFromCloudIfNewer()`). Whichever cosmetic is *equipped* in each
/// category, though, still syncs via iCloud like it does between two iOS
/// devices, so the watch always looks like the phone even though its money
/// doesn't follow. An uploaded Custom Photo's actual image data is the one
/// look that can't carry over -- those stay on local disk on whichever
/// device you uploaded them on (a photo is far too big for the key-value
/// store), so a custom photo equipped on the phone just falls back to that
/// category's built-in look on the watch rather than failing to render.
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
