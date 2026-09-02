import SwiftUI
import WatchKit
import UIKit

/// Compact bot-practice table for watchOS: your two cards, the five
/// community cards, a live bot roster, current hand type, and
/// Fold / Check-Call / Bet -- styled with whatever cosmetics are equipped
/// on the phone (they sync over automatically via `BankrollManager`'s
/// iCloud key-value store, same account, same data).
struct WatchGameView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine: PokerEngine
    private let humanID: String
    private let buyIn: Int
    private let resumedFromSave: Bool
    @State private var hasSettled = false
    @State private var showHandGuide = false

    init(botCount: Int = 3, buyIn: Int = 500) {
        if let saved = GamePersistence.loadLocalGame() {
            _engine = StateObject(wrappedValue: PokerEngine(resuming: saved.engine))
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
            _engine = StateObject(wrappedValue: PokerEngine(players: [human] + bots))
            humanID = human.id
            self.buyIn = buyIn
            resumedFromSave = false
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                botRoster

                Text("Pot $\(engine.potTotal)")
                    .font(.caption.bold())
                    .foregroundColor(PATheme.goldBright)

                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { i in
                        WatchCardView(card: i < engine.communityCards.count ? engine.communityCards[i] : nil,
                                      cardFaceID: bankroll.equippedCardFace)
                    }
                }

                if let handText = engine.handDescription(for: humanID) {
                    Text(handText)
                        .font(.caption2.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Capsule().fill(PATheme.goldMaterial))
                }

                if let human = engine.players.first(where: { $0.id == humanID }) {
                    HStack(spacing: 3) {
                        ForEach(human.holeCards) { card in
                            WatchCardView(card: card, cardFaceID: bankroll.equippedCardFace)
                        }
                    }
                    Text("You: $\(human.chips)")
                        .font(.caption2)
                        .foregroundColor(PATheme.goldBright)
                }

                if !engine.showdownResults.isEmpty {
                    ForEach(engine.showdownResults) { result in
                        Text("\(result.playerName) +$\(result.amountWon)\n\(result.hand.category.displayName)")
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
                    showHandGuide = true
                } label: {
                    Label("Hands", systemImage: "questionmark.circle")
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
                engine.startNextHand()
            } else {
                runBotTurnIfNeeded()
            }
        }
        .onDisappear { saveProgress() }
        .onChange(of: engine.activePlayerIndex) { _, _ in
            runBotTurnIfNeeded()
            notifyIfHumanTurn()
        }
        .onChange(of: engine.round) { _, _ in runBotTurnIfNeeded() }
        .sheet(isPresented: $showHandGuide) { WatchHandRankingsView() }
    }

    /// A compact, always-visible row of every bot still at the table --
    /// name, stack, and status -- so the player has table awareness beyond
    /// just their own cards on a screen too small for full seats.
    private var botRoster: some View {
        VStack(spacing: 2) {
            ForEach(engine.players.filter { $0.id != humanID }) { bot in
                HStack(spacing: 4) {
                    if engine.dealerIndex < engine.players.count, engine.players[engine.dealerIndex].id == bot.id {
                        Text("D")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(PATheme.ink)
                            .padding(2)
                            .background(Circle().fill(PATheme.goldMaterial))
                    }
                    WatchAvatarBadge(avatarID: bot.avatarID, size: 12)
                    Text(bot.name)
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer()
                    Text(bot.isFolded ? "Folded" : bot.isAllIn ? "All In" : "$\(bot.chips)")
                        .font(.caption2)
                        .foregroundColor(bot.isFolded ? .gray : bot.isAllIn ? .orange : .secondary)
                }
                .opacity(bot.isFolded ? 0.5 : 1)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive(bot) ? Color.white.opacity(0.15) : Color.clear)
                )
            }
        }
    }

    private func isActive(_ player: Player) -> Bool {
        guard let idx = engine.activePlayerIndex, engine.players.indices.contains(idx) else { return false }
        return engine.players[idx].id == player.id
    }

    @ViewBuilder
    private var footer: some View {
        if let human = engine.players.first(where: { $0.id == humanID }), !engine.isHandInProgress {
            VStack(spacing: 6) {
                if human.chips > 0 {
                    Button("Next Hand") { engine.startNextHand() }
                        .buttonStyle(.borderedProminent)
                    Button("Cash Out") { cashOutAndLeave() }
                        .font(.caption2)
                } else {
                    Button("Rebuy $\(buyIn)") { rebuy() }
                        .buttonStyle(.borderedProminent)
                        .disabled(bankroll.chips < buyIn)
                }
            }
        } else if let human = engine.players.first(where: { $0.id == humanID }), human.id == engine.currentPlayer()?.id {
            let toCall = engine.currentBet - human.currentBet
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Button("Fold") { engine.apply(.fold, by: humanID) }
                        .tint(.red)
                    Button(toCall == 0 ? "Check" : "Call \(toCall)") {
                        engine.apply(toCall == 0 ? .check : .call, by: humanID)
                    }
                    .tint(.green)
                }
                Button(engine.currentBet == 0 ? "Bet \(engine.bigBlind * 2)" : "Raise") {
                    let target = engine.currentBet == 0 ? engine.bigBlind * 2 : engine.currentBet + engine.minRaise
                    engine.apply(engine.currentBet == 0 ? .bet(target) : .raise(target), by: humanID)
                }
                Button("All In") { engine.apply(.allIn, by: humanID) }
                    .font(.caption2)
                    .tint(.orange)
            }
            .buttonStyle(.bordered)
        }
    }

    private func rebuy() {
        guard bankroll.chips >= buyIn else { return }
        bankroll.applyDelta(-buyIn)
        engine.addChips(buyIn, to: humanID)
        engine.startNextHand()
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
        guard let human = engine.players.first(where: { $0.id == humanID }), human.chips > 0 || engine.isHandInProgress else {
            GamePersistence.clearLocalGame()
            return
        }
        GamePersistence.save(PersistedLocalGame(engine: engine.makeSnapshotForPersistence(), humanID: humanID, buyIn: buyIn))
    }

    private func runBotTurnIfNeeded() {
        guard engine.isHandInProgress, let current = engine.currentPlayer(), current.isBot else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            guard engine.currentPlayer()?.id == current.id else { return }
            engine.apply(BotAI.decideAction(for: current, engine: engine), by: current.id)
        }
    }

    /// A gentle tap on the wrist when it becomes the player's turn -- easy
    /// to miss a screen glance while playing one-handed.
    private func notifyIfHumanTurn() {
        guard engine.currentPlayer()?.id == humanID else { return }
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
