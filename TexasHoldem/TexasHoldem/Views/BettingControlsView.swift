import SwiftUI

struct BettingControlsView: View {
    let player: Player
    let currentBet: Int
    let minRaise: Int
    let bigBlind: Int
    let onAction: (PlayerAction) -> Void

    @State private var raiseAmount: Double = 0

    private var toCall: Int { max(0, currentBet - player.currentBet) }
    private var minTarget: Int { currentBet == 0 ? bigBlind : currentBet + minRaise }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Bet to \(Int(raiseAmount))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            Slider(value: $raiseAmount, in: Double(minTarget)...Double(max(minTarget, player.chips + player.currentBet)), step: 1)
                .onAppear { raiseAmount = Double(minTarget) }

            HStack(spacing: 10) {
                Button(role: .destructive) { onAction(.fold) } label: {
                    Label("Fold", systemImage: "hand.raised.slash")
                }
                .buttonStyle(.bordered)

                if toCall == 0 {
                    Button { onAction(.check) } label: {
                        Label("Check", systemImage: "checkmark")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button { onAction(.call) } label: {
                        Label("Call \(toCall)", systemImage: "arrow.turn.down.right")
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    onAction(currentBet == 0 ? .bet(Int(raiseAmount)) : .raise(Int(raiseAmount)))
                } label: {
                    Label(currentBet == 0 ? "Bet" : "Raise", systemImage: "arrow.up.circle")
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(PATheme.gold)
                .foregroundStyle(PATheme.ink)
                .disabled(player.chips == 0)

                Button {
                    onAction(.allIn)
                } label: {
                    Text("All In")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .font(.footnote.bold())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(PATheme.gold.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
