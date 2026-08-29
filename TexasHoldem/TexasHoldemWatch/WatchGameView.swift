import SwiftUI

/// Compact bot-practice table for watchOS: your two cards, the five
/// community cards, current hand type, and Fold / Check-Call / Bet.
struct WatchGameView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine: PokerEngine
    private let humanID: String
    private let buyIn: Int
    private let resumedFromSave: Bool
    @State private var hasSettled = false

    init(botCount: Int = 3, buyIn: Int = 500) {
        if let saved = GamePersistence.loadLocalGame() {
            _engine = StateObject(wrappedValue: PokerEngine(resuming: saved.engine))
            humanID = saved.humanID
            self.buyIn = saved.buyIn
            resumedFromSave = true
        } else {
            let human = Player(id: "watch-human", name: "You", chips: buyIn, isBot: false)
            let bots = (1...botCount).map { Player(id: "watch-bot-\($0)", name: BotNames.random(), chips: buyIn, isBot: true) }
            _engine = StateObject(wrappedValue: PokerEngine(players: [human] + bots))
            humanID = human.id
            self.buyIn = buyIn
            resumedFromSave = false
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Pot $\(engine.potTotal)")
                    .font(.caption.bold())

                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { i in
                        WatchCardView(card: i < engine.communityCards.count ? engine.communityCards[i] : nil)
                    }
                }

                if let handText = engine.handDescription(for: humanID) {
                    Text(handText)
                        .font(.caption2.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Capsule().fill(Color.yellow))
                }

                if let human = engine.players.first(where: { $0.id == humanID }) {
                    HStack(spacing: 3) {
                        ForEach(human.holeCards) { card in
                            WatchCardView(card: card)
                        }
                    }
                    Text("You: $\(human.chips)")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }

                if !engine.lastActionDescription.isEmpty {
                    Text(engine.lastActionDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                footer
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            if !resumedFromSave {
                bankroll.applyDelta(-buyIn)
                engine.startNextHand()
            } else {
                runBotTurnIfNeeded()
            }
        }
        .onDisappear { saveProgress() }
        .onChange(of: engine.activePlayerIndex) { _ in runBotTurnIfNeeded() }
        .onChange(of: engine.round) { _ in runBotTurnIfNeeded() }
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
}

private struct WatchCardView: View {
    let card: Card?

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
                    .foregroundColor(card.suit.isRed ? .red : .black)
                }
            }
    }
}
