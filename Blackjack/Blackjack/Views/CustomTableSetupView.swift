import SwiftUI

/// Lets the player configure their own practice table -- bot count, starting
/// stack, and table limits -- before sitting down. A free sandbox: it costs
/// nothing from the bankroll to sit down, and chips won here stay at the
/// table, so the stakes can be set to anything without touching the real
/// economy.
struct CustomTableSetupView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss

    @State private var botCount: Double = 4
    @State private var buyIn: Double = 500
    @State private var maxBet: Double = 100
    @State private var startGame = false

    private var minBet: Int { max(1, Int(maxBet) / 10) }

    var body: some View {
        NavigationView {
            Form {
                Section("Other Players") {
                    Stepper("\(Int(botCount)) Bots", value: $botCount, in: 1...6)
                }
                Section("Starting Stack") {
                    Slider(value: $buyIn, in: 100...2000, step: 50)
                    Text("$\(Int(buyIn)) per player")
                        .foregroundColor(.secondary)
                }
                Section("Table Limits") {
                    Slider(value: $maxBet, in: 10...1000, step: 10)
                    Text("Limits: $\(minBet) – $\(Int(maxBet))")
                        .foregroundColor(.secondary)
                }
                Section {
                    Label("Free to play — this table doesn't touch your bankroll, and chips won here stay at the table.",
                          systemImage: "infinity")
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
                .tint(BJTheme.gold)
                .foregroundStyle(BJTheme.ink)
                .padding()
            }
        }
        .tint(BJTheme.gold)
        .fullScreenCover(isPresented: $startGame) {
            LocalGameView(botCount: Int(botCount), buyIn: Int(buyIn), minBet: minBet, maxBet: Int(maxBet),
                          enableResume: false, tableTitle: "Custom Table", usesBankroll: false)
                .environmentObject(bankroll)
        }
    }
}
