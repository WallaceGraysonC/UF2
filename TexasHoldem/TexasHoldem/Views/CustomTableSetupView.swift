import SwiftUI

/// Lets the player configure their own practice table -- bot count, buy-in,
/// and blinds -- before sitting down. Purely a local/offline table, same as
/// "Play vs Bots" but with player-chosen stakes instead of the fixed default.
struct CustomTableSetupView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss

    @State private var botCount: Double = 4
    @State private var buyIn: Double = 500
    @State private var bigBlind: Double = 20
    @State private var startGame = false

    private var smallBlind: Int { max(1, Int(bigBlind) / 2) }

    var body: some View {
        NavigationView {
            Form {
                Section("Opponents") {
                    Stepper("\(Int(botCount)) Bots", value: $botCount, in: 1...7)
                }
                Section("Buy-In") {
                    Slider(value: $buyIn, in: 100...2000, step: 50)
                    Text("$\(Int(buyIn)) per player")
                        .foregroundColor(.secondary)
                }
                Section("Blinds") {
                    Slider(value: $bigBlind, in: 10...200, step: 10)
                    Text("Blinds: $\(smallBlind) / $\(Int(bigBlind))")
                        .foregroundColor(.secondary)
                }
                Section {
                    Text("You have $\(bankroll.chips) available.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Custom Table")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    startGame = true
                } label: {
                    Text("Sit Down").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(PATheme.gold)
                .foregroundStyle(PATheme.ink)
                .disabled(bankroll.chips < Int(buyIn))
                .padding()
            }
        }
        .tint(PATheme.gold)
        .fullScreenCover(isPresented: $startGame) {
            LocalGameView(botCount: Int(botCount), buyIn: Int(buyIn), smallBlind: smallBlind, bigBlind: Int(bigBlind),
                          enableResume: false, tableTitle: "Custom Table")
                .environmentObject(bankroll)
        }
    }
}
