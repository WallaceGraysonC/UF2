import SwiftUI

/// Root of the view hierarchy. Main Menu pushes to the Shop Floor hub, and
/// the hub's tab bar pushes on to each project screen.
struct ContentView: View {
    @State private var game = GameState()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView(
                onNewGame: { startNewGame() },
                onContinue: { path.append(Route.shopFloor) }
            )
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
                    .navigationBarBackButtonHidden()
            }
        }
        .environment(game)
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

    private func startNewGame() {
        game = GameState()
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
