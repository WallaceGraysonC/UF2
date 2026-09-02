import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @EnvironmentObject var gameCenter: GameCenterManager
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false

    var body: some View {
        NavigationView {
            Form {
                Section("Bankroll") {
                    HStack {
                        Text("Current Chips")
                        Spacer()
                        Text("$\(bankroll.chips)").bold().foregroundColor(PATheme.goldBright)
                    }
                    HStack {
                        Text("Best Ever")
                        Spacer()
                        Text("$\(bankroll.highestChips)").foregroundColor(.secondary)
                    }
                    Button("Top Up to $\(BankrollManager.bankrollTopUpFloor)") {
                        showResetConfirm = true
                    }
                    .disabled(!bankroll.canTopUpBankroll)
                    .foregroundColor(bankroll.canTopUpBankroll ? .red : .secondary)
                    Text(topUpHint)
                        .font(.footnote)
                        .foregroundColor(.secondary)
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

                Section("iCloud Sync") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(bankroll.isCloudAvailable ? "Syncing" : "Unavailable")
                            .foregroundColor(bankroll.isCloudAvailable ? .green : .secondary)
                    }
                    Text("Your chip balance and owned cosmetics automatically sync across your devices using iCloud, as long as you're signed into iCloud with this app's iCloud capability enabled.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("About") {
                    Text("This game has no ads, no pop-ups, and no in-app purchases. Chips are a free virtual currency used only to keep score and unlock cosmetics -- they cannot be bought with real money or cashed out.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .tint(PATheme.gold)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Top Up Your Bankroll?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Top Up") { bankroll.topUpBankroll() }
            } message: {
                Text("Brings your balance up to $\(BankrollManager.bankrollTopUpFloor) — one buy-in at the main table. Your owned cosmetics are kept.")
            }
        }
    }

    private var topUpHint: String {
        if bankroll.canTopUpBankroll {
            return "Available now — this adds $\(bankroll.topUpAmount), bringing you to $\(BankrollManager.bankrollTopUpFloor) so you can always sit down. It tops up to that figure rather than adding to it, so anything pricier has to be won at the table."
        }
        return "Available whenever you drop under $\(BankrollManager.bankrollTopUpFloor) — you're not short yet."
    }
}
