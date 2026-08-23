import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @EnvironmentObject var gameCenter: GameCenterManager
    @State private var showResetConfirm = false

    var body: some View {
        NavigationView {
            Form {
                Section("Bankroll") {
                    HStack {
                        Text("Current Chips")
                        Spacer()
                        Text("$\(bankroll.chips)").bold().foregroundColor(.yellow)
                    }
                    Button("Reset Bankroll to $\(BankrollManager.startingChips)") {
                        showResetConfirm = true
                    }
                    .foregroundColor(.red)
                }

                Section("Game Center") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(gameCenter.isAuthenticated ? "Signed in as \(gameCenter.localPlayerName)" : "Not signed in")
                            .foregroundColor(gameCenter.isAuthenticated ? .green : .secondary)
                    }
                    if !gameCenter.isAuthenticated {
                        Button("Sign in to Game Center") { gameCenter.authenticate() }
                    }
                }

                Section("About") {
                    Text("This game has no ads, no pop-ups, and no in-app purchases. Chips are a free virtual currency used only to keep score and unlock cosmetics -- they cannot be bought with real money or cashed out.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Bankroll?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { bankroll.resetBankroll() }
            } message: {
                Text("This sets your chip balance back to $\(BankrollManager.startingChips). Your owned cosmetics are kept.")
            }
        }
    }
}
