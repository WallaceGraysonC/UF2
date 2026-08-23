import SwiftUI

/// Practice table against bots -- fully offline, no network required.
struct LocalGameView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine: PokerEngine
    private let humanID: String
    private let buyIn: Int
    @State private var hasSettled = false

    init(botCount: Int = 4, buyIn: Int = 2000) {
        let human = Player(id: "local-human", name: "You", chips: buyIn, isBot: false)
        let bots = (1...botCount).map { i in
            Player(id: "bot-\(i)", name: BotNames.random(), chips: buyIn, isBot: true)
        }
        _engine = StateObject(wrappedValue: PokerEngine(players: [human] + bots))
        self.humanID = human.id
        self.buyIn = buyIn
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                TableFeltView(communityCards: engine.communityCards, pot: engine.potTotal, feltID: bankroll.equippedFelt) {
                    ForEach(Array(engine.players.enumerated()), id: \.element.id) { index, player in
                        let offset = SeatLayout.offsets(count: engine.players.count)[index]
                        PlayerSeatView(
                            player: player,
                            isActive: engine.activePlayerIndex == index,
                            isDealer: engine.dealerIndex == index,
                            revealCards: player.id == humanID || engine.round == .showdown
                        )
                        .position(
                            x: geo.size.width / 2 + offset.x * geo.size.width * 0.38,
                            y: geo.size.height * 0.42 + offset.y * geo.size.height * 0.34
                        )
                    }
                }
                .frame(width: geo.size.width * 0.92, height: geo.size.height * 0.62)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.4)

                VStack {
                    header
                    Spacer()
                    if !engine.lastActionDescription.isEmpty {
                        Text(engine.lastActionDescription)
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                    footer
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            bankroll.applyDelta(-buyIn)
            if !engine.isHandInProgress { engine.startNextHand() }
        }
        .onDisappear { settleIfNeeded() }
        .onChange(of: engine.activePlayerIndex) { _ in runBotTurnIfNeeded() }
        .onChange(of: engine.round) { _ in runBotTurnIfNeeded() }
    }

    private var header: some View {
        HStack {
            Button {
                settleIfNeeded()
                dismiss()
            } label: {
                Image(systemName: "chevron.left").foregroundColor(.white)
            }
            Spacer()
            Text("Practice Table")
                .foregroundColor(.white)
                .font(.headline)
            Spacer()
            Color.clear.frame(width: 20)
        }
        .padding()
    }

    @ViewBuilder
    private var footer: some View {
        if let human = engine.players.first(where: { $0.id == humanID }), !engine.isHandInProgress {
            VStack(spacing: 10) {
                if !engine.showdownResults.isEmpty {
                    ForEach(engine.showdownResults) { result in
                        Text("\(result.playerName) wins $\(result.amountWon) — \(result.hand.category.displayName)")
                            .font(.footnote.bold())
                            .foregroundColor(.yellow)
                    }
                }
                if human.chips > 0 {
                    Button {
                        engine.startNextHand()
                    } label: {
                        Text("Next Hand").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 40)
                } else {
                    Button {
                        rebuy()
                    } label: {
                        Text("Rebuy for $\(buyIn)").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(bankroll.chips < buyIn)
                    .padding(.horizontal, 40)
                    if bankroll.chips < buyIn {
                        Text("Not enough chips — reset your bankroll in Settings.")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.bottom, 20)
        } else if let human = engine.players.first(where: { $0.id == humanID }), human.id == engine.currentPlayer()?.id {
            BettingControlsView(
                player: human,
                currentBet: engine.currentBet,
                minRaise: engine.minRaise,
                bigBlind: engine.bigBlind,
                onAction: { engine.apply($0, by: humanID) }
            )
            .padding(.bottom, 12)
        }
    }

    private func rebuy() {
        guard bankroll.chips >= buyIn else { return }
        bankroll.applyDelta(-buyIn)
        engine.addChips(buyIn, to: humanID)
        engine.startNextHand()
    }

    /// Reflects whatever chips are left in front of the player back into
    /// their persistent bankroll when they leave the table.
    private func settleIfNeeded() {
        guard !hasSettled else { return }
        hasSettled = true
        if let human = engine.players.first(where: { $0.id == humanID }) {
            bankroll.applyDelta(human.chips)
        }
    }

    private func runBotTurnIfNeeded() {
        guard engine.isHandInProgress, let current = engine.currentPlayer(), current.isBot else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard engine.currentPlayer()?.id == current.id else { return }
            let action = BotAI.decideAction(for: current, engine: engine)
            engine.apply(action, by: current.id)
        }
    }
}

enum BotNames {
    static let pool = ["Ace", "Riverboat Rae", "Chip", "Duke", "Sable", "Maverick", "Ivy", "Blaze"]
    static func random() -> String { pool.randomElement() ?? "Bot" }
}
