import SwiftUI

struct BettingControlsView: View {
    @EnvironmentObject var bankroll: BankrollManager
    let player: Player
    let currentBet: Int
    let minRaise: Int
    let bigBlind: Int
    let onAction: (PlayerAction) -> Void

    @State private var raiseAmount: Double = 0

    private static let chipDenominations = [5, 10, 25, 100, 500, 1000]

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
                Button {
                    raiseAmount = Double(minTarget)
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.caption2.bold())
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.6))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Self.chipDenominations, id: \.self) { amount in
                        ChipTokenButton(amount: amount, chipSetID: bankroll.equippedChips, isMaxedOut: raiseAmount >= Double(maxTarget)) {
                            raiseAmount = min(raiseAmount + Double(amount), Double(maxTarget))
                        }
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 1)
            }
            // player.chips/currentBet/minRaise change after every action, which
            // can move this range on a re-render of the *same* view instance --
            // re-clamp explicitly or raiseAmount can end up outside its own range.
            .onAppear { raiseAmount = Double(minTarget) }
            .onChange(of: minTarget) { _, _ in clampRaiseAmount() }
            .onChange(of: maxTarget) { _, _ in clampRaiseAmount() }

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

/// A tappable poker-chip token that adds a fixed amount to the pending bet,
/// styled with whatever chip set the player has equipped from the Store.
private struct ChipTokenButton: View {
    let amount: Int
    let chipSetID: String
    let isMaxedOut: Bool
    let action: () -> Void

    private var label: String {
        amount >= 1000 ? "\(amount / 1000)K" : "\(amount)"
    }

    private var fill: AnyShapeStyle {
        let color = ChipPalette.color(for: chipSetID)
        return CustomCosmeticFill.style(
            for: chipSetID, kind: .chipSet,
            fallback: AnyShapeStyle(RadialGradient(colors: [color.opacity(0.95), color.opacity(0.65)],
                                                    center: .center, startRadius: 2, endRadius: 26))
        )
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(fill)
                Circle()
                    .strokeBorder(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 3, dash: [4, 3]))
                    .padding(3)
                Text(label)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 1)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .opacity(isMaxedOut ? 0.35 : 1)
        .disabled(isMaxedOut)
        .materialShadow(radius: 4, y: 2)
    }
}
