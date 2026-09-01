import SwiftUI

/// Root of the view hierarchy. Placeholder until real navigation (NavigationStack
/// or a coordinator) is wired up between Main Menu, Shop Floor, Sourcing, etc.
struct ContentView: View {
    var body: some View {
        MainMenuView()
    }
}

#Preview {
    ContentView()
}
