import SwiftUI

/// Root of the view hierarchy. Owns the run and the save slot: Continue
/// resumes the file on disk, New Game replaces it.
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var game = GameState()
    @State private var path = NavigationPath()
    /// Checked once at launch so the menu knows whether Continue is live.
    @State private var savedGame: SaveGame? = SaveStore.load()

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView(
                hasSave: savedGame != nil,
                savedSummary: savedSummary,
                onNewGame: { startNewGame() },
                onContinue: { continueSavedGame() }
            )
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
                    .navigationBarBackButtonHidden()
            }
        }
        .environment(game)
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
        case .shopFloor: ShopFloorView(onNavigate: handleTab)
        case .sourcingRun: SourcingRunView()
        case .bench: BenchView()
        case .drops: DropsView()
        case .staff: StaffView()
        case .ledger: LedgerView()
        }
    }

    /// One line describing what Continue would return you to.
    private var savedSummary: String? {
        guard let savedGame else { return nil }
        return "DAY \(savedGame.day) · LV. \(savedGame.shopLevel) · $\(savedGame.cash)"
    }

    private func startNewGame() {
        SaveStore.deleteSave()
        game = GameState()
        game.save()
        savedGame = game.snapshot()
        path.append(Route.shopFloor)
    }

    private func continueSavedGame() {
        guard let savedGame else { return }
        game = GameState(snapshot: savedGame)
        path.append(Route.shopFloor)
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
    }
}

#Preview {
    ContentView()
}
