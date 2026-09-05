import SwiftUI
import WatchKit
import UIKit

/// Compact bot-practice table for watchOS: the dealer's cards, a live bot
/// roster, your own hand, and Bet / Hit / Stand / Double (Split and
/// Surrender when they're legal) -- styled with whatever cosmetics are
/// equipped on the phone (they sync over automatically via
/// `BankrollManager`'s iCloud key-value store, same account, same data).
struct WatchGameView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine: BlackjackEngine
    private let humanID: String
    private let buyIn: Int
    private let resumedFromSave: Bool
    @State private var hasSettled = false
    @State private var showRulesGuide = false
    @State private var betAmount: Int = 0

    init(botCount: Int = 3, buyIn: Int = 500) {
        if let saved = GamePersistence.loadLocalGame() {
            _engine = StateObject(wrappedValue: BlackjackEngine(resuming: saved.engine))
            humanID = saved.humanID
            self.buyIn = saved.buyIn
            resumedFromSave = true
        } else {
            let human = Player(id: "watch-human", name: "You", chips: buyIn, isBot: false,
                                cardBackID: BankrollManager.shared.equippedCardBack,
                                cardFaceID: BankrollManager.shared.equippedCardFace,
                                avatarID: BankrollManager.shared.equippedAvatar,
                                avatarFrameID: BankrollManager.shared.equippedAvatarFrame)
            let names = BotNames.uniqueNames(count: botCount)
            let bots = (1...botCount).map { i in
                Player(id: "watch-bot-\(i)", name: names[i - 1], chips: buyIn, isBot: true,
                       cardBackID: BankrollManager.shared.equippedCardBack,
                       cardFaceID: BankrollManager.shared.equippedCardFace,
                       avatarID: BotNames.randomAvatar())
            }
            _engine = StateObject(wrappedValue: BlackjackEngine(players: [human] + bots, minBet: 10, maxBet: buyIn))
            humanID = human.id
            self.buyIn = buyIn
            resumedFromSave = false
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                botRoster

                Text("Dealer \(engine.dealer.displayTotal)")
                    .font(.caption.bold())
                    .foregroundColor(BJTheme.goldBright)

                HStack(spacing: 3) {
                    ForEach(Array(engine.dealer.visibleCards.enumerated()), id: \.offset) { _, card in
                        WatchCardView(card: card, cardFaceID: bankroll.equippedCardFace)
                    }
                    if !engine.dealer.holeCardRevealed, engine.dealer.cards.count > 1 {
                        WatchCardView(card: nil, cardFaceID: bankroll.equippedCardFace)
                    }
                }

                if let human = engine.players.first(where: { $0.id == humanID }) {
                    ForEach(Array(human.hands.enumerated()), id: \.element.id) { index, hand in
                        VStack(spacing: 2) {
                            HStack(spacing: 3) {
                                ForEach(hand.cards) { card in
                                    WatchCardView(card: card, cardFaceID: bankroll.equippedCardFace)
                                }
                            }
                            if !hand.displayTotal.isEmpty {
                                Text("\(hand.displayTotal) · $\(hand.bet)")
                                    .font(.caption2.bold())
                                    .foregroundColor(index == engine.activeHandIndex && engine.currentPlayer?.id == humanID ? BJTheme.goldBright : .secondary)
                            }
                        }
                    }
                    Text("You: $\(human.chips)")
                        .font(.caption2)
                        .foregroundColor(BJTheme.goldBright)
                }

                if !engine.roundResults.isEmpty {
                    ForEach(engine.roundResults.filter { $0.playerID == humanID }) { result in
                        Text(result.summaryText)
                            .font(.caption2.bold())
                            .foregroundColor(.yellow)
                            .multilineTextAlignment(.center)
                    }
                } else if !engine.lastActionDescription.isEmpty {
                    Text(engine.lastActionDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                footer

                Button {
                    showRulesGuide = true
                } label: {
                    Label("Rules", systemImage: "questionmark.circle")
                        .font(.caption2)
                }
                .tint(.gray)
            }
            .padding(.horizontal, 4)
        }
        .background(FeltPalette.color(for: bankroll.equippedFelt).opacity(0.25).ignoresSafeArea())
        .onAppear {
            if !resumedFromSave {
                bankroll.applyDelta(-buyIn)
                engine.startNextRound()
            } else {
                runBotTurnIfNeeded()
            }
            betAmount = engine.minBet
        }
        .onDisappear { saveProgress() }
        .onChange(of: engine.activePlayerIndex) { _, _ in
            runBotTurnIfNeeded()
            notifyIfHumanTurn()
        }
        .onChange(of: engine.phase) { _, _ in runBotTurnIfNeeded() }
        .sheet(isPresented: $showRulesGuide) { WatchRulesGuideView() }
    }

    /// A compact, always-visible row of every bot still at the table --
    /// name, stack, and status -- so the player has table awareness beyond
    /// just their own hand on a screen too small for full seats.
    private var botRoster: some View {
        VStack(spacing: 2) {
            ForEach(engine.players.filter { $0.id != humanID }) { bot in
                HStack(spacing: 4) {
                    WatchAvatarBadge(avatarID: bot.avatarID, size: 12)
                    Text(bot.name)
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer()
                    Text(bot.hands.isEmpty ? "$\(bot.chips)" : (bot.hands[0].displayTotal.isEmpty ? "$\(bot.chips)" : bot.hands[0].displayTotal))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive(bot) ? Color.white.opacity(0.15) : Color.clear)
                )
            }
        }
    }

    private func isActive(_ player: Player) -> Bool {
        engine.currentPlayer?.id == player.id
    }

    @ViewBuilder
    private var footer: some View {
        if let human = engine.players.first(where: { $0.id == humanID }) {
            if engine.phase == .payout, !engine.isRoundInProgress {
                VStack(spacing: 6) {
                    if human.chips > 0 {
                        Button("Next Hand") { engine.startNextRound() }
                            .buttonStyle(.borderedProminent)
                        Button("Cash Out") { cashOutAndLeave() }
                            .font(.caption2)
                    } else {
                        Button("Rebuy $\(buyIn)") { rebuy() }
                            .buttonStyle(.borderedProminent)
                            .disabled(bankroll.chips < buyIn)
                    }
                }
            } else if engine.phase == .insurance, engine.currentPlayer?.id == humanID {
                VStack(spacing: 6) {
                    Text("Dealer shows Ace")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        Button("Decline") { engine.decideInsurance(false, for: humanID) }
                            .tint(.red)
                        Button("Insure") { engine.decideInsurance(true, for: humanID) }
                            .tint(.green)
                    }
                }
                .buttonStyle(.bordered)
            } else if engine.phase == .playerTurns, engine.currentPlayer?.id == humanID {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Button("Hit") { engine.apply(.hit, by: humanID) }
                            .tint(BJTheme.gold)
                        Button("Stand") { engine.apply(.stand, by: humanID) }
                            .tint(.blue)
                    }
                    if engine.canDoubleDownNow || engine.canSplitNow || engine.canSurrenderNow {
                        HStack(spacing: 6) {
                            if engine.canDoubleDownNow {
                                Button("Double") { engine.apply(.doubleDown, by: humanID) }
                                    .tint(.orange)
                            }
                            if engine.canSplitNow {
                                Button("Split") { engine.apply(.split, by: humanID) }
                                    .tint(.purple)
                            }
                        }
                        .font(.caption2)
                    }
                    if engine.canSurrenderNow {
                        Button("Surrender") { engine.apply(.surrender, by: humanID) }
                            .font(.caption2)
                            .tint(.red)
                    }
                }
                .buttonStyle(.bordered)
            } else if engine.phase == .betting, human.hands.isEmpty, human.chips > 0 {
                VStack(spacing: 6) {
                    Stepper("Bet $\(betAmount)", value: $betAmount, in: engine.minBet...max(engine.minBet, min(engine.maxBet, human.chips)), step: engine.minBet)
                        .font(.caption2)
                    Button("Deal") { engine.placeBet(betAmount, for: humanID) }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private func rebuy() {
        guard bankroll.chips >= buyIn else { return }
        bankroll.applyDelta(-buyIn)
        engine.addChips(buyIn, to: humanID)
        engine.startNextRound()
    }

    private func cashOutAndLeave() {
        guard !hasSettled else { dismiss(); return }
        hasSettled = true
        if let human = engine.players.first(where: { $0.id == humanID }) {
            bankroll.applyDelta(human.chips)
        }
        GamePersistence.clearLocalGame()
        dismiss()
    }

    private func saveProgress() {
        guard !hasSettled else { return }
        guard let human = engine.players.first(where: { $0.id == humanID }), human.chips > 0 || engine.isRoundInProgress else {
            GamePersistence.clearLocalGame()
            return
        }
        GamePersistence.save(PersistedLocalGame(engine: engine.makeSnapshotForPersistence(), humanID: humanID, buyIn: buyIn))
    }

    private func runBotTurnIfNeeded() {
        guard engine.isRoundInProgress, engine.phase == .playerTurns,
              let current = engine.currentPlayer, current.isBot, let hand = engine.currentHand,
              let dealerUpCard = engine.dealer.upCard else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            guard engine.currentPlayer?.id == current.id else { return }
            let action = BlackjackBotAI.decideAction(hand: hand, dealerUpCard: dealerUpCard,
                                                      canDouble: engine.canDoubleDownNow, canSplit: engine.canSplitNow,
                                                      canSurrender: engine.canSurrenderNow)
            engine.apply(action, by: current.id)
        }
    }

    /// A gentle tap on the wrist when it becomes the player's turn -- easy
    /// to miss a screen glance while playing one-handed.
    private func notifyIfHumanTurn() {
        guard engine.currentPlayer?.id == humanID else { return }
        WKInterfaceDevice.current().play(.notification)
    }
}

/// Tiny avatar icon for the bot roster -- the watch's own copy of the same
/// idea as the phone's `AvatarBadge`, since that lives in an iOS-only file.
private struct WatchAvatarBadge: View {
    let avatarID: String
    var size: CGFloat = 12

    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.35))
            if avatarID == CustomCosmeticStore.customID(for: .avatar),
               let image = CustomCosmeticStore.shared.image(for: .avatar) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: AvatarPalette.symbol(for: avatarID))
                    .font(.system(size: size * 0.55))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct WatchCardView: View {
    let card: Card?
    var cardFaceID: String = CosmeticCatalog.defaultCardFace

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(card == nil ? Color.gray.opacity(0.3) : Color.white)
            .frame(width: 20, height: 28)
            .overlay {
                if let card {
                    VStack(spacing: 0) {
                        Text(card.rank.label).font(.system(size: 9, weight: .bold))
                        Text(card.suit.symbol).font(.system(size: 9))
                    }
                    .foregroundColor(CardFacePalette.inkColor(isRed: card.suit.isRed, for: cardFaceID))
                }
            }
    }
}
