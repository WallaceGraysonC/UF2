import SwiftUI

/// Root of the view hierarchy. Owns the run and the save slot.
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var studio = Studio()
    @State private var path = NavigationPath()
    @State private var savedGame: SaveFile? = SaveStore.load()

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
        .environment(studio)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, !path.isEmpty {
                studio.save()
            }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .floor: StudioFloorView(onNavigate: handleTab)
        case .employees: EmployeesView()
        }
    }

    private var savedSummary: String? {
        guard let savedGame else { return nil }
        return "DAY \(savedGame.day) · LV. \(savedGame.studioLevel) · $\(savedGame.cash)"
    }

    private func startNewGame() {
        SaveStore.deleteSave()
        studio = Studio()
        studio.save()
        savedGame = studio.snapshot()
        path.append(Route.floor)
    }

    private func continueSavedGame() {
        guard let savedGame else { return }
        studio = Studio(snapshot: savedGame)
        path.append(Route.floor)
    }

    private func handleTab(_ tab: AppTab) {
        switch tab {
        case .floor: break
        case .employees: path.append(Route.employees)
        }
    }

    private enum Route: Hashable {
        case floor
        case employees
    }
}

#Preview {
    ContentView()
}
