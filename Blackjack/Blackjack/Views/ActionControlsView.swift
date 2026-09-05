import SwiftUI

/// Bet-builder shown during the betting phase, before cards are dealt --
/// the same chip-token idea as Hold'em's raise slider, just building a
/// wager instead of a bet-to amount.
struct BetBuilderView: View {
    @EnvironmentObject var bankroll: BankrollManager
    let chips: Int
    let minBet: Int
    let maxBet: Int
    /// The last amount this player actually bet at this table, if any --
    /// pre-fills the builder so repeating a bet is just a tap of Deal
    /// instead of rebuilding it from chip tokens every round.
    var defaultBet: Int? = nil
    let onDeal: (Int) -> Void

    @State private var betAmount: Double = 0

    private static let chipDenominations = [5, 10, 25, 100, 500, 1000]

    private var clampedMax: Int { max(minBet, min(maxBet, chips)) }
    private var canDeal: Bool { Int(betAmount) >= minBet && Int(betAmount) <= chips }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Bet $\(Int(betAmount))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Button {
                    betAmount = Double(minBet)
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
                        ChipTokenButton(amount: amount, chipSetID: bankroll.equippedChips, isMaxedOut: betAmount >= Double(clampedMax)) {
                            betAmount = min(betAmount + Double(amount), Double(clampedMax))
                        }
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 1)
            }
            .onAppear { betAmount = Double(min(defaultBet ?? minBet, clampedMax)) }

            Button {
                onDeal(Int(betAmount))
            } label: {
                Text("Deal").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(BJTheme.gold)
            .foregroundStyle(BJTheme.ink)
            .disabled(!canDeal)
            .font(.footnote.bold())
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BJTheme.gold.opacity(0.25), lineWidth: 1))
        .padding(.horizontal)
    }
}

/// Hit / Stand / Double / Split / Surrender controls shown while it's the
/// player's turn on their active hand.
struct HandActionControlsView: View {
    let canDouble: Bool
    let canSplit: Bool
    let canSurrender: Bool
    let onAction: (PlayerAction) -> Void

    var body: some View {
        VStack(spacing: 8) {
            if canDouble || canSplit {
                HStack(spacing: 6) {
                    if canDouble {
                        Button { onAction(.doubleDown) } label: {
                            Label("Double", systemImage: "2.circle")
                                .lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                    if canSplit {
                        Button { onAction(.split) } label: {
                            Label("Split", systemImage: "arrow.triangle.branch")
                                .lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                }
                .font(.footnote.bold())
            }

            HStack(spacing: 6) {
                if canSurrender {
                    Button(role: .destructive) { onAction(.surrender) } label: {
                        Label("Surrender", systemImage: "flag")
                            .lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button { onAction(.stand) } label: {
                    Label("Stand", systemImage: "hand.raised")
                        .lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button { onAction(.hit) } label: {
                    Label("Hit", systemImage: "plus.circle")
                        .lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(BJTheme.gold)
                .foregroundStyle(BJTheme.ink)
            }
            .font(.footnote.bold())
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BJTheme.gold.opacity(0.25), lineWidth: 1))
        .padding(.horizontal)
    }
}

/// A tappable chip token that adds a fixed amount to the pending bet,
/// styled with whatever chip set the player has equipped from the Store.
struct ChipTokenButton: View {
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

/// Accept / Decline controls for the insurance side bet, offered whenever
/// the dealer's up card is an ace.
struct InsuranceControlsView: View {
    let insuranceCost: Int
    let onDecide: (Bool) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Dealer shows an Ace. Insurance costs $\(insuranceCost) and pays 2:1 if the dealer has Blackjack.")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button(role: .destructive) { onDecide(false) } label: {
                    Text("Decline").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button { onDecide(true) } label: {
                    Text("Take Insurance").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(BJTheme.gold)
                .foregroundStyle(BJTheme.ink)
            }
            .font(.footnote.bold())
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(BJTheme.gold.opacity(0.25), lineWidth: 1))
        .padding(.horizontal)
    }
}
