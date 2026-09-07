import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @State private var startGame = false
    @State private var botCount: Int = 3
    @State private var showHandGuide = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "suit.spade.fill")
                            .foregroundColor(PATheme.goldBright)
                        Text("Pocket Aces")
                            .font(.headline)
                    }

                    Text("$\(bankroll.chips) · Lvl \(bankroll.level)")
                        .font(.caption2)
                        .foregroundColor(PATheme.goldBright)

                    if !GamePersistence.hasSavedLocalGame {
                        HStack(spacing: 10) {
                            Button {
                                botCount = max(1, botCount - 1)
                            } label: {
                                Image(systemName: "minus")
                            }
                            .disabled(botCount <= 1)

                            Text("\(botCount) Bots")
                                .font(.caption)
                                .frame(minWidth: 50)

                            Button {
                                botCount = min(5, botCount + 1)
                            } label: {
                                Image(systemName: "plus")
                            }
                            .disabled(botCount >= 5)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }

                    Button {
                        startGame = true
                    } label: {
                        Text(GamePersistence.hasSavedLocalGame ? "Resume" : "Play vs Bots")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    HStack(spacing: 6) {
                        if bankroll.canTopUpBankroll {
                            Button("Top Up") { bankroll.topUpBankroll() }
                                .controlSize(.mini)
                        }
                        Button {
                            showHandGuide = true
                        } label: {
                            Label("Hands", systemImage: "questionmark.circle")
                        }
                        .controlSize(.mini)
                        .tint(.gray)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 4)
            }
            .navigationDestination(isPresented: $startGame) {
                WatchGameView(botCount: botCount)
            }
            .sheet(isPresented: $showHandGuide) { WatchHandRankingsView() }
        }
    }
}
