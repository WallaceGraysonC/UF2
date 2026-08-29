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
    // Always >= minTarget, so this ClosedRange can never invert.
    private var maxTarget: Int { max(minTarget, player.chips + player.currentBet) }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Bet to \(Int(raiseAmount))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            Slider(value: $raiseAmount, in: Double(minTarget)...Double(maxTarget), step: 1)
                .onAppear { raiseAmount = Double(minTarget) }
                // player.chips/currentBet/minRaise change after every action, which
                // can move this range on a re-render of the *same* slider instance --
                // onAppear alone won't refire, so re-clamp explicitly or the slider's
                // stored value can end up outside its own range and crash.
                .onChange(of: minTarget) { _ in clampRaiseAmount() }
                .onChange(of: maxTarget) { _ in clampRaiseAmount() }

            HStack(spacing: 6) {
                Button(role: .destructive) { onAction(.fold) } label: {
                    Label("Fold", systemImage: "hand.raised.slash")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if toCall == 0 {
                    Button { onAction(.check) } label: {
                        Label("Check", systemImage: "checkmark")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button { onAction(.call) } label: {
                        Label("Call \(toCall)", systemImage: "arrow.turn.down.right")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    onAction(currentBet == 0 ? .bet(Int(raiseAmount)) : .raise(Int(raiseAmount)))
                } label: {
                    Label(currentBet == 0 ? "Bet" : "Raise", systemImage: "arrow.up.circle")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(PATheme.gold)
                .foregroundStyle(PATheme.ink)
                .disabled(player.chips == 0)

                Button {
                    onAction(.allIn)
                } label: {
                    Text("All In")
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
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

    private func clampRaiseAmount() {
        raiseAmount = Double(min(max(Int(raiseAmount), minTarget), maxTarget))
    }
}
