import SwiftUI

/// Root of the view hierarchy. Owns the run, the save slot, and the legacy
/// profile that outlives both.
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var game = GameState()
    @State private var path = NavigationPath()
    /// Checked once at launch so the menu knows whether Continue is live.
    @State private var savedGame: SaveGame? = SaveStore.load()
    @State private var legacy: LegacyProfile = LegacyStore.load()
    @State private var showingLegacy = false

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView(
                hasSave: savedGame != nil,
                savedSummary: savedSummary,
                legacySummary: legacySummary,
                onNewGame: { startNewGame() },
                onContinue: { continueSavedGame() },
                onLegacy: { showingLegacy = true }
            )
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
                    .navigationBarBackButtonHidden()
            }
        }
        .environment(game)
        .sheet(isPresented: $showingLegacy) {
            LegacyView(profile: $legacy)
        }
        .onChange(of: scenePhase) { _, phase in
            // Backgrounding is the other moment a run can end abruptly.
            if phase != .active, !path.isEmpty {
                game.save()
            }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .shopFloor:
            ShopFloorView(onNavigate: handleTab,
                          onOpenMuseum: { path.append(Route.museum) },
                          skin: ShopSkin(profile: legacy))
        case .sourcingRun: SourcingRunView()
        case .bench: BenchView()
        case .drops: DropsView()
        case .staff: StaffView()
        case .ledger: LedgerView()
        case .museum: MuseumView(onCloseUpShop: { retireAndReopen() })
        }
    }

    /// One line describing what Continue would return you to.
    private var savedSummary: String? {
        guard let savedGame else { return nil }
        return "DAY \(savedGame.day) · LV. \(savedGame.shopLevel) · $\(savedGame.cash)"
    }

    private var legacySummary: String? {
        guard legacy.prestigeCount > 0 else { return nil }
        return "\(legacy.prestigeCount) SHOP\(legacy.prestigeCount == 1 ? "" : "S") CLOSED · BEST \(legacy.bestLegacyScore)"
    }

    private func startNewGame() {
        SaveStore.deleteSave()
        game = GameState(legacy: legacy)
        game.save()
        savedGame = game.snapshot()
        path.append(Route.shopFloor)
    }

    private func continueSavedGame() {
        guard let savedGame else { return }
        game = GameState(snapshot: savedGame)
        path.append(Route.shopFloor)
    }

    /// After closing up shop the run save is already gone — reload the profile
    /// so the new run inherits the perk just chosen, and go back to the menu.
    private func retireAndReopen() {
        legacy = LegacyStore.load()
        savedGame = nil
        game = GameState(legacy: legacy)
        path = NavigationPath()
    }

    private func handleTab(_ tab: AppTab) {
        switch tab {
        case .floor: break
        case .source: path.append(Route.sourcingRun)
        case .bench: path.append(Route.bench)
        case .drops: path.append(Route.drops)
        case .staff: path.append(Route.staff)
        case .ledger: path.append(Route.ledger)
        }
    }

    private enum Route: Hashable {
        case shopFloor
        case sourcingRun
        case bench
        case drops
        case staff
        case ledger
        case museum
    }
}

#Preview {
    ContentView()
}
