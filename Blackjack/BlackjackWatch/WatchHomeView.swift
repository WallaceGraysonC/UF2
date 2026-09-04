import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @State private var startGame = false
    @State private var botCount: Int = 3
    @State private var showRulesGuide = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Text("21")
                        .font(.system(size: 30, weight: .heavy, design: .serif))
                        .foregroundColor(BJTheme.goldBright)
                    Text("Pocket 21")
                        .font(.headline)
                    Text("$\(bankroll.chips)")
                        .font(.subheadline.bold())
                        .foregroundColor(BJTheme.goldBright)
                    Text("Level \(bankroll.level)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if !GamePersistence.hasSavedLocalGame {
                        Stepper("\(botCount) Bots", value: $botCount, in: 1...5)
                            .font(.caption)
                    }

                    Button {
                        startGame = true
                    } label: {
                        Text(GamePersistence.hasSavedLocalGame ? "Resume" : "Play vs Bots")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if bankroll.canTopUpBankroll {
                        Button("Top up to $\(BankrollManager.bankrollTopUpFloor)") { bankroll.topUpBankroll() }
                            .font(.caption2)
                    }

                    Button {
                        showRulesGuide = true
                    } label: {
                        Label("Rules", systemImage: "questionmark.circle")
                            .font(.caption2)
                    }
                    .tint(.gray)
                }
                .padding()
            }
            .navigationDestination(isPresented: $startGame) {
                WatchGameView(botCount: botCount)
            }
            .sheet(isPresented: $showRulesGuide) { WatchRulesGuideView() }
        }
    }
}
