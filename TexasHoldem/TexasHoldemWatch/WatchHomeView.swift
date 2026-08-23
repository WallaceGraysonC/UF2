import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @State private var startGame = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Image(systemName: "suit.spade.fill")
                    .font(.title)
                Text("Pocket Aces")
                    .font(.headline)
                Text("$\(bankroll.chips)")
                    .font(.subheadline.bold())
                    .foregroundColor(.yellow)

                Button {
                    startGame = true
                } label: {
                    Text(GamePersistence.hasSavedLocalGame ? "Resume" : "Play vs Bots")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if bankroll.chips <= 0 {
                    Button("Reset Chips") { bankroll.resetBankroll() }
                        .font(.caption2)
                }
            }
            .padding()
            .navigationDestination(isPresented: $startGame) {
                WatchGameView()
            }
        }
    }
}
