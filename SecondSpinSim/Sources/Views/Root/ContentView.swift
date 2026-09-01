import SwiftUI

/// Root of the view hierarchy. A single NavigationStack for now — Main Menu
/// pushes straight to the Shop Floor, since there's no shop-naming flow or
/// save system yet to gate on.
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView(
                onNewGame: { path.append(Route.shopFloor) },
                onContinue: { path.append(Route.shopFloor) }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .shopFloor:
                    ShopFloorView(onNavigate: handleTab)
                        .navigationBarBackButtonHidden()
                case .sourcingRun:
                    SourcingRunView()
                        .navigationBarBackButtonHidden()
                case .bench:
                    BenchView()
                        .navigationBarBackButtonHidden()
                }
            }
        }
    }

    /// Staff and Ledger aren't built yet.
    private func handleTab(_ tab: AppTab) {
        switch tab {
        case .source:
            path.append(Route.sourcingRun)
        case .bench:
            path.append(Route.bench)
        case .floor, .staff, .ledger:
            break
        }
    }

    private enum Route: Hashable {
        case shopFloor
        case sourcingRun
        case bench
    }
}

#Preview {
    ContentView()
}
