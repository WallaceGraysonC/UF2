import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @State private var startGame = false
    @State private var botCount: Int = 3
    @State private var showHandGuide = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Image(systemName: "suit.spade.fill")
                        .font(.title)
                        .foregroundColor(PATheme.goldBright)
                    Text("Pocket Aces")
                        .font(.headline)
                    Text("$\(bankroll.chips)")
                        .font(.subheadline.bold())
                        .foregroundColor(PATheme.goldBright)
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
                        Button("Get $\(BankrollManager.bankrollTopUpAmount)") { bankroll.topUpBankroll() }
                            .font(.caption2)
                    }

                    Button {
                        showHandGuide = true
                    } label: {
                        Label("Hands", systemImage: "questionmark.circle")
                            .font(.caption2)
                    }
                    .tint(.gray)
                }
                .padding()
            }
            .navigationDestination(isPresented: $startGame) {
                WatchGameView(botCount: botCount)
            }
            .sheet(isPresented: $showHandGuide) { WatchHandRankingsView() }
        }
    }
}
