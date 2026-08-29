import SwiftUI

/// Practice table against bots -- fully offline, no network required.
struct LocalGameView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var engine: PokerEngine
    private let humanID: String
    private let buyIn: Int
    private let resumedFromSave: Bool
    @State private var hasSettled = false
    @State private var showHandGuide = false

    init(botCount: Int = 4, buyIn: Int = 500) {
        if let saved = GamePersistence.loadLocalGame() {
            _engine = StateObject(wrappedValue: PokerEngine(resuming: saved.engine))
            self.humanID = saved.humanID
            self.buyIn = saved.buyIn
            self.resumedFromSave = true
        } else {
            let human = Player(id: "local-human", name: "You", chips: buyIn, isBot: false,
                                cardBackID: BankrollManager.shared.equippedCardBack,
                                avatarID: BankrollManager.shared.equippedAvatar)
            let bots = (1...botCount).map { i in
                Player(id: "bot-\(i)", name: BotNames.random(), chips: buyIn, isBot: true,
                       cardBackID: BankrollManager.shared.equippedCardBack,
                       avatarID: BotNames.randomAvatar())
            }
            _engine = StateObject(wrappedValue: PokerEngine(players: [human] + bots))
            self.humanID = human.id
            self.buyIn = buyIn
            self.resumedFromSave = false
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackdropPalette.gradient(for: bankroll.equippedBackdrop).ignoresSafeArea()
                TableFeltView(communityCards: engine.communityCards, pot: engine.potTotal, feltID: bankroll.equippedFelt, railID: bankroll.equippedRail, cardBackID: bankroll.equippedCardBack) { feltSize in
                    // The human's own seat is drawn separately below, layered
                    // above the button panel -- everyone else stays in the oval.
                    ForEach(Array(engine.players.enumerated()), id: \.element.id) { index, player in
                        if player.id != humanID {
                            let offset = SeatLayout.offsets(count: engine.players.count)[index]
                            PlayerSeatView(
                                player: player,
                                isActive: engine.activePlayerIndex == index,
                                isDealer: engine.dealerIndex == index,
                                revealCards: engine.round == .showdown
                            )
                            .position(
                                x: feltSize.width / 2 + offset.x * feltSize.width * 0.42,
                                y: feltSize.height / 2 + offset.y * feltSize.height * 0.44
                            )
                        }
                    }
                }
                .frame(width: geo.size.width * 0.98, height: geo.size.height * 0.80)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.45)

                VStack {
                    header
                    Spacer()
                    if !engine.lastActionDescription.isEmpty || engine.handDescription(for: humanID) != nil {
                        HStack(alignment: .top) {
                            if !engine.lastActionDescription.isEmpty {
                                Text(engine.lastActionDescription)
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(.ultraThinMaterial))
                                    .frame(maxWidth: 190, alignment: .leading)
                            }
                            Spacer()
                            if let handText = engine.handDescription(for: humanID) {
                                HandTypeBadge(text: handText)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                    }
                    footer
                }

                // Hero seat: drawn last so it layers in front of the button
                // panel below it, overlapping its top edge slightly.
                if let human = engine.players.first(where: { $0.id == humanID }),
                   let humanIndex = engine.players.firstIndex(where: { $0.id == humanID }) {
                    PlayerSeatView(
                        player: human,
                        isActive: engine.activePlayerIndex == humanIndex,
                        isDealer: engine.dealerIndex == humanIndex,
                        revealCards: true
                    )
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 128)
                    // Purely visual -- never intercept taps meant for the
                    // buttons underneath it where it overlaps them.
                    .allowsHitTesting(false)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if !resumedFromSave {
                bankroll.applyDelta(-buyIn)
                engine.startNextHand()
            } else {
                runBotTurnIfNeeded()
            }
        }
        .onDisappear { saveProgress() }
        .onChange(of: scenePhase) { newPhase in
            if newPhase != .active { saveProgress() }
        }
        .onChange(of: engine.activePlayerIndex) { _ in runBotTurnIfNeeded() }
        .onChange(of: engine.round) { _ in runBotTurnIfNeeded() }
    }

    private var header: some View {
        HStack {
            Button {
                saveProgress()
                dismiss()
            } label: {
                Image(systemName: "chevron.left").foregroundColor(.white)
            }
            Spacer()
            Text("Practice Table")
                .foregroundColor(.white)
                .font(.headline)
            Spacer()
            Button { showHandGuide = true } label: {
                Label("Hands", systemImage: "questionmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(PATheme.goldBright)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(PATheme.gold.opacity(0.5), lineWidth: 1))
            }
        }
        .padding()
        .sheet(isPresented: $showHandGuide) { HandRankingsGuideView() }
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
                    HStack(spacing: 12) {
                        Button {
                            engine.startNextHand()
                        } label: {
                            Text("Next Hand").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            cashOutAndLeave()
                        } label: {
                            Text("Cash Out").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
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

    /// Cashes the player's stack back into their persistent bankroll and
    /// clears the saved table -- use this for a deliberate "I'm done" exit,
    /// as opposed to `saveProgress()` which just pauses the hand.
    private func cashOutAndLeave() {
        guard !hasSettled else { dismiss(); return }
        hasSettled = true
        if let human = engine.players.first(where: { $0.id == humanID }) {
            bankroll.applyDelta(human.chips)
        }
        GamePersistence.clearLocalGame()
        dismiss()
    }

    /// Saves the table exactly as it stands so the player can back out (or
    /// have the app backgrounded/killed) and resume the same hand later.
    /// Chips already bought in stay "at the table" until a Cash Out.
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard engine.currentPlayer()?.id == current.id else { return }
            let action = BotAI.decideAction(for: current, engine: engine)
            engine.apply(action, by: current.id)
        }
    }
}

enum BotNames {
    static let pool = ["Ace", "Riverboat Rae", "Chip", "Duke", "Sable", "Maverick", "Ivy", "Blaze"]
    private static let avatarPool = ["avatar.shark", "avatar.robot", "avatar.fox", "avatar.wizard", "avatar.astronaut", "avatar.dragon"]
    static func random() -> String { pool.randomElement() ?? "Bot" }
    static func randomAvatar() -> String { avatarPool.randomElement() ?? CosmeticCatalog.defaultAvatar }
}
