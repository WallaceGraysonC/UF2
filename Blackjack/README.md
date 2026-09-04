# Pocket 21

A SwiftUI Blackjack game for iOS, built as a companion to the Pocket Aces
Texas Hold'em app -- same "card room" visual language, same bankroll and
cosmetics system, same no-ads/no-purchases philosophy, adapted to
Blackjack's rules.

- **No ads, no pop-ups, no in-app purchases.** There is no ad SDK, no
  StoreKit purchase flow, and nothing in this project talks to a store.
- **Play with friends** using Apple's built-in Game Center (GameKit)
  matchmaker -- invite friends or auto-match, no server to run or pay for.
  Every seat plays its own hand(s) against the shared dealer, so there's no
  pot to split the way there is in Hold'em.
- **Play solo** any time against a handful of simple basic-strategy bot
  opponents dealt from a 6-deck shoe.
- **Virtual currency only.** Chips ("$") have no real-world value, can't be
  bought with real money, and can't be cashed out. You start with $1,000,
  and if you ever drop under $500 you can claim a top-up from Settings (or
  the home screen prompt) at any time -- a safety net against busting out,
  not a free reset, so it can't be farmed to unlock the store.
- **Cosmetics store.** Spend chips on card backs, card faces, table felt,
  table rails, table backdrops, chip designs, and avatars -- the exact same
  catalog and unlock-tier system as Pocket Aces, since the cosmetics are
  purely visual and don't care which card game is being played.
- **Full Blackjack rules.** Hit, Stand, Double Down, Split (up to three
  times), late Surrender, and Insurance when the dealer shows an Ace. The
  dealer peeks for Blackjack on an Ace or ten-value up card, and hits to 17
  before standing on every 17 (hard or soft).
- **A live hand-total badge** shows your current hand's value as cards come
  out, the same coaching idea as Pocket Aces' hand-type badge. Tap the
  **Rules** button any time for payouts, actions, and dealer rules.
- **iCloud sync.** Chip balance and owned/equipped cosmetics sync across
  your devices via `NSUbiquitousKeyValueStore` (see setup step 3 below).
- **Resume where you left off.** Leaving the practice table (back button,
  backgrounding, or the app getting killed) saves the exact round in
  progress -- bets, cards dealt, shoe order, everything -- and picks it back
  up next time you tap Play vs Bots. "Cash Out" between hands is the
  deliberate way to end a session and settle your stack back into your
  bankroll.

## Project layout

```
Blackjack.xcodeproj/           Xcode project
Blackjack/
  BlackjackApp.swift           App entry point
  Models/
    Card.swift                 Card primitives (shared rank/suit)
    Shoe.swift                 Multi-deck dealing shoe
    BlackjackHandEvaluator.swift  Hard/soft totals, natural blackjack
    Player.swift                Per-player table state (one or more hands)
    DealerHand.swift             The house's hand, hole card masking
    GameState.swift              Network-safe snapshot of the table
    BlackjackEngine.swift        Betting, insurance, splits, dealer play, payouts
    BlackjackBotAI.swift          Simplified basic-strategy opponent
    BotNames.swift                Shared bot name/avatar pool
    EngineSnapshot.swift          Full save/restore state for a table
    GamePersistence.swift         Reads/writes a saved local game
  Multiplayer/
    GameCenterManager.swift     Game Center auth + matchmaking
    MultiplayerMatch.swift      Host-authoritative sync over GKMatch
  Store/
    Cosmetic.swift               Cosmetics catalog (shared with Pocket Aces)
    CosmeticPalettes.swift       Shared card back / felt color lookups
    CustomCosmeticStore.swift    Player-uploaded "Custom Photo" cosmetics
    BankrollManager.swift        iCloud+local chip balance & owned/equipped cosmetics
    DailyChallengeManager.swift  Daily + Tournament challenge tracks
    Haptics.swift, AudioManager.swift
  Views/                         SwiftUI screens (home, table, store, settings,
                                  matchmaking, rules guide)
  Resources/                     Info.plist, Assets.xcassets, BlackjackTheme.wav
BlackjackWatch/                 watchOS companion source (not yet wired into a target -- see below)
```

## How the table works

Unlike Hold'em, players never play against each other in Blackjack -- every
seat's hand is settled independently against the dealer, so `BlackjackEngine`
has no pot or side-pot accounting the way `PokerEngine` does. What replaces
that complexity is per-hand bookkeeping: a player can be holding up to four
hands at once after splitting pairs, and `activePlayerIndex` +
`activeHandIndex` together track whose turn it is on which hand.

A round moves through five phases: **betting** (each seat wagers, bots
first, human last), **insurance** (only if the dealer shows an Ace),
**playerTurns** (each hand acts in turn -- Hit, Stand, Double, Split,
Surrender), **dealerTurn** (reveal and hit to 17), and **payout**.

## How multiplayer works

There's no backend server. When you tap **Play with Friends**, Apple's
`GKMatchmakerViewController` is presented so you can invite people from your
Game Center friends list (or auto-match with strangers). Once a match is
formed, the participant with the lexicographically-smallest player ID is
elected host: only that device runs the real `BlackjackEngine`. It
broadcasts a `GameState` snapshot to everyone after each action, and every
other device sends its actions to the host over the same GameKit connection.
Every player's hand is public in Blackjack (unlike Hold'em hole cards), so
the only thing that needs masking on the wire is the dealer's hole card
until it's revealed -- simpler than Hold'em's per-viewer hole-card hiding.

## Opening the project

This was authored without access to Xcode/macOS, so it has **not** been
compiled. Open `Blackjack.xcodeproj` in Xcode 15+ on macOS, and:

1. Set your own development team under the target's **Signing & Capabilities**.
2. Make sure the **Game Center** capability (already added via
   `Blackjack.entitlements`) is enabled for your App ID in the Apple
   Developer portal if you want to test multiplayer on real devices.
3. To turn on iCloud sync: in **Signing & Capabilities**, click **+ Capability**
   → **iCloud** → check **Key-value storage**. Xcode will add the right
   ubiquity container identifier to `Blackjack.entitlements` for you --
   don't type one in by hand. Without this step the app still works fine,
   it just stays local-only (`BankrollManager.isCloudAvailable` will read false).
4. Build and run on iOS 17+.

If Xcode reports any small project-file issues on first open (this file was
hand-written rather than generated by Xcode), the fix is usually just
re-adding the flagged file to the target in the File Inspector -- the Swift
source itself doesn't depend on the project file being perfect.

## Adding the watchOS companion app

Swift source for a basic bot-only watch app lives in `BlackjackWatch/`,
but it isn't wired into a build target yet -- hand-authoring a second Xcode
target (with its embed-watch-content build phase and companion-app bundle
ID) is much safer to do through Xcode's own wizard than by editing the
project file blind. To add it:

1. **File > New > Target… > watchOS > Watch App**, and when prompted, make
   it a companion to the `Blackjack` iOS target. Give the target a name
   like "Pocket 21 Watch App".
2. **Delete** (Move to Trash, not just remove from target) the placeholder
   `ContentView.swift` and `<TargetName>App.swift` files Xcode generates
   for the new target. This step gets missed easily and is the #1 cause of
   the watch app showing Xcode's default "Hello, World!" screen instead of
   ours -- if those placeholder files are still in the target, Swift is
   still compiling and running *them*, not `BlackjackWatchApp.swift`.
3. Drag in the four `.swift` files from `BlackjackWatch/` (add them to the
   new watch target only, not the iOS one), and the `Assets.xcassets`
   folder from the same directory (it already has the app icon set up).
4. In the File Inspector, give the new watch target **Target Membership**
   on these existing iOS files too (they have no UIKit/GameKit dependency,
   so they build cleanly for watchOS as-is): `Card.swift`, `Shoe.swift`,
   `BlackjackHandEvaluator.swift`, `Player.swift`, `DealerHand.swift`,
   `GameState.swift`, `BlackjackEngine.swift`, `BlackjackBotAI.swift`,
   `BotNames.swift`, `EngineSnapshot.swift`, `GamePersistence.swift`,
   `Cosmetic.swift`, `CosmeticPalettes.swift`, `CustomCosmeticStore.swift`,
   `BankrollManager.swift`, `BJTheme.swift`.
5. If you enabled iCloud sync (step 3 above) and want the watch and phone
   to share one bankroll, give the watch target the same **iCloud > Key-value
   storage** capability with the *same* container identifier as the iOS
   target.

The watch app is deliberately minimal: the dealer's cards and total, a
compact bot roster, your own hand(s) with running totals, and
Bet / Hit / Stand / Double (Split and Surrender show up only when they're
actually legal) against bot opponents.

### Troubleshooting a blank icon or "Hello, World!" on the watch

Both symptoms trace back to the same handful of things:

- **Blank/generic icon on the Watch Home Screen** -- almost always means no
  `AppIcon` image is set for that target. The `Assets.xcassets` folder in
  `BlackjackWatch/` includes a ready-made 1024x1024 `AppIcon-1024.png`;
  make sure that whole folder (not just individual files inside it) got
  added to the new watch target, and check **Signing & Capabilities** for
  a code-signing error on the watch target specifically (a failed sign
  can also leave a blank/stuck icon after install).
- **Shows "Hello, World!" instead of the real app** -- the placeholder
  template files are still present/compiling (see step 2 above). Search
  the watch target's file list for anything with `@main` other than
  `BlackjackWatchApp.swift` and delete it.
- **Build fails / won't run at all** -- almost always a missing Target
  Membership checkbox on one of the shared files listed in step 4. Xcode's
  error will name the missing type (e.g. "Cannot find 'BlackjackEngine' in
  scope"), which tells you exactly which file's membership to fix.
- **Confirm the companion link** -- under the watch target's build
  settings, `WKCompanionAppBundleIdentifier` should read
  `com.wallacegrayson.blackjack` (the iOS app's bundle ID). If it's
  blank or wrong, watchOS won't treat it as this app's companion.
