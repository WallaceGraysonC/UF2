import SwiftUI

/// Practice table against bots -- fully offline, no network required.
struct LocalGameView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var engine: PokerEngine
    private let humanID: String
    /// The table's nominal stake -- what a full buy-in or rebuy costs.
    private let buyIn: Int
    /// What was actually taken from the bankroll to sit down, which is less
    /// than `buyIn` when the player couldn't cover a full stack.
    private let seatedBuyIn: Int
    private let resumedFromSave: Bool
    private let enableResume: Bool
    private let tableTitle: String
    /// When false this is a free sandbox table: no buy-in is taken from the
    /// bankroll to sit down, rebuys are free, and chips won here stay at the
    /// table rather than banking out (otherwise a free table would be an
    /// unlimited source of chips).
    private let usesBankroll: Bool
    /// When set, this is a Sit & Go: no rebuys, blinds escalate over time,
    /// and busting/winning ends the session with a placement screen instead
    /// of returning to the felt.
    private let tournament: TournamentConfig?
    /// Which bucket this table's hands/tournaments are recorded under in
    /// `StatsManager` -- independent of `usesBankroll`/`challengeTrack`, so
    /// even the free Custom Table gets its own stats.
    private let mode: GameModeID
    /// How the bots at this table play. Only Custom Table Setup and the
    /// Game Modes screen expose a picker for this; the default Play vs Bots
    /// quick-start always plays at `.normal`.
    private let difficulty: BotDifficulty
    @State private var hasSettled = false
    @State private var showHandGuide = false

    struct TournamentConfig {
        let blindLevels: [(small: Int, big: Int)]
        let handsPerLevel: Int
    }

    init(botCount: Int = 4, buyIn: Int = 500, smallBlind: Int = 10, bigBlind: Int = 20,
         enableResume: Bool = true, tableTitle: String = "",
         usesBankroll: Bool = true, tournament: TournamentConfig? = nil,
         mode: GameModeID = .playVsBots, difficulty: BotDifficulty = .normal) {
        self.enableResume = enableResume
        self.tableTitle = tableTitle
        self.usesBankroll = usesBankroll
        self.tournament = tournament
        self.mode = mode
        self.difficulty = difficulty
        if enableResume, let saved = GamePersistence.loadLocalGame() {
            _engine = StateObject(wrappedValue: PokerEngine(resuming: saved.engine))
            self.humanID = saved.humanID
            self.buyIn = saved.buyIn
            self.seatedBuyIn = 0 // already paid for when the table was first joined
            self.resumedFromSave = true
        } else {
            // Sit down for what's actually in the bankroll, not the nominal
            // buy-in. Deducting a full buy-in you can't cover used to clamp
            // the balance at zero while still seating a full stack, which
            // conjured chips out of nothing.
            let seated = usesBankroll ? min(buyIn, BankrollManager.shared.chips) : buyIn
            var human = Player(id: "local-human", name: "You", chips: seated, isBot: false,
                                cardBackID: BankrollManager.shared.equippedCardBack,
                                cardFaceID: BankrollManager.shared.equippedCardFace,
                                avatarID: BankrollManager.shared.equippedAvatar,
                                avatarFrameID: BankrollManager.shared.equippedAvatarFrame)
            human.seatIndex = 0
            let botNames = BotNames.randomNames(count: botCount)
            let bots = (1...botCount).map { i -> Player in
                var bot = Player(id: "bot-\(i)", name: botNames[i - 1], chips: buyIn, isBot: true,
                       cardBackID: BankrollManager.shared.equippedCardBack,
                       cardFaceID: BankrollManager.shared.equippedCardFace,
                       avatarID: BotNames.randomAvatar())
                bot.seatIndex = i
                return bot
            }
            _engine = StateObject(wrappedValue: PokerEngine(players: [human] + bots, smallBlind: smallBlind, bigBlind: bigBlind))
            self.humanID = human.id
            self.buyIn = buyIn
            self.seatedBuyIn = seated
            self.resumedFromSave = false
        }
    }

    /// The table's fixed seat count, established when players first sat down
    /// -- seats are positioned against this instead of the live (shrinking)
    /// player count, so a bust just empties a seat instead of reshuffling
    /// everyone else around a smaller oval.
    private var totalSeats: Int {
        (engine.players.map { $0.seatIndex }.max() ?? engine.players.count - 1) + 1
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackdropView(id: bankroll.equippedBackdrop).ignoresSafeArea()
                TableFeltView(communityCards: engine.communityCards, pot: engine.potTotal, feltID: bankroll.equippedFelt, railID: bankroll.equippedRail, cardBackID: bankroll.equippedCardBack, cardFaceID: bankroll.equippedCardFace) { feltSize in
                    // The human's own seat is drawn separately below, layered
                    // above the button panel -- everyone else stays in the oval.
                    ForEach(Array(engine.players.enumerated()), id: \.element.id) { index, player in
                        if player.id != humanID {
                            let offset = SeatLayout.offsets(count: totalSeats)[player.seatIndex]
                            PlayerSeatView(
                                player: player,
                                isActive: engine.activePlayerIndex == index,
                                isDealer: engine.dealerIndex == index,
                                revealCards: engine.round == .showdown,
                                isWinner: engine.showdownResults.contains { $0.playerID == player.id },
                                compact: SeatLayout.usesCompactSeats(count: totalSeats)
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
                    footer
                }

                // Last-action text and the hand-type badge live in the dead
                // felt space between the community cards and the hero's own
                // cards -- NOT stacked against the footer, since the hero's
                // seat below is independently positioned to overlap the
                // footer's top edge, and a footer-adjacent row would fight
                // it for the same strip of screen (as it visibly did when
                // both lived here). Centered and narrow rather than
                // full-width: at 4+ seats, `SeatLayout` places the two
                // bottom-side bots at this same height (just left/right of
                // center, per its own doc comment), so this has to stay
                // inside the clear channel between them instead of
                // stretching edge-to-edge.
                if !engine.lastActionDescription.isEmpty || engine.handDescription(for: humanID) != nil {
                    VStack(spacing: 6) {
                        if !engine.lastActionDescription.isEmpty {
                            Text(engine.lastActionDescription)
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(.ultraThinMaterial))
                        }
                        if let handText = engine.handDescription(for: humanID) {
                            HandTypeBadge(text: handText)
                        }
                    }
                    .frame(maxWidth: 170)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.565)
                    .allowsHitTesting(false)
                }

                // Hero seat: drawn last so it layers in front of the button
                // panel below it, overlapping its top edge slightly.
                if let human = engine.players.first(where: { $0.id == humanID }),
                   let humanIndex = engine.players.firstIndex(where: { $0.id == humanID }) {
                    PlayerSeatView(
                        player: human,
                        isActive: engine.activePlayerIndex == humanIndex,
                        isDealer: engine.dealerIndex == humanIndex,
                        revealCards: true,
                        isWinner: engine.showdownResults.contains { $0.playerID == humanID }
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
                if usesBankroll { bankroll.applyDelta(-seatedBuyIn) }
                // Sitting down with an empty bankroll seats the human for
                // $0 (see `seated` above). Starting a hand anyway would
                // immediately run into `startNextHand()`'s own "remove
                // anyone who busted last hand" cleanup -- which, applied to
                // a player who hasn't played a single hand yet, just erases
                // them from their own table with no feedback: no seat, no
                // cards, no footer, nothing to tap. Skipping straight to a
                // hand here instead leaves `isHandInProgress` false, which
                // is exactly the state the footer already knows how to
                // render as a Rebuy / Top Up prompt.
                if seatedBuyIn > 0 {
                    engine.startNextHand()
                }
            } else {
                runBotTurnIfNeeded()
            }
        }
        .onDisappear { saveProgress() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { saveProgress() }
        }
        .onChange(of: engine.activePlayerIndex) { _, _ in
            runBotTurnIfNeeded()
            notifyIfHumanTurn()
        }
        .onChange(of: engine.round) { _, _ in runBotTurnIfNeeded() }
        .onChange(of: engine.isHandInProgress) { _, inProgress in
            if !inProgress { handleHandEnd() }
        }
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
            // The main vs-bots table needs no label -- it's the default
            // table, and the header reads cleaner without it. The other
            // modes pass a title so you can tell which one you're in.
            if !tableTitle.isEmpty {
                Text(tableTitle)
                    .foregroundColor(.white)
                    .font(.headline)
            }
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
            if let tournament {
                tournamentFooter(human: human, tournament: tournament)
            } else {
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
                            Text(usesBankroll ? "Cash Out" : "Leave Table").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                    .padding(.horizontal, 40)
                } else {
                    Button {
                        rebuy()
                    } label: {
                        Text(rebuyLabel).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(usesBankroll && bankroll.chips == 0)
                    .padding(.horizontal, 40)
                    if usesBankroll, bankroll.chips == 0 {
                        Button("Top up to $\(BankrollManager.bankrollTopUpFloor)") {
                            bankroll.topUpBankroll()
                        }
                        .font(.footnote.bold())
                        .foregroundColor(PATheme.goldBright)
                    }
                }
            }
            .padding(.bottom, 20)
            }
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

    @ViewBuilder
    private func tournamentFooter(human: Player, tournament: TournamentConfig) -> some View {
        VStack(spacing: 10) {
            if !engine.showdownResults.isEmpty {
                ForEach(engine.showdownResults) { result in
                    Text("\(result.playerName) wins $\(result.amountWon) — \(result.hand.category.displayName)")
                        .font(.footnote.bold())
                        .foregroundColor(.yellow)
                }
            }
            if human.chips <= 0 {
                let placement = engine.players.filter { $0.chips > 0 }.count + 1
                Text("Eliminated — you placed #\(placement)")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Button("Done") {
                    finishTournament(placement: placement)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
            } else if engine.players.count == 1 {
                Text("You won the tournament!")
                    .font(.headline.bold())
                    .foregroundColor(PATheme.goldBright)
                Button("Collect Winnings") {
                    finishTournament(placement: 1)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
            } else {
                Button("Next Hand") { engine.startNextHand() }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 40)
            }
        }
        .padding(.bottom, 20)
    }

    /// Settles a finished Sit & Go: the winner's whole stack converts back
    /// into the persistent bankroll (the buy-ins from every bot at the
    /// table), everyone else just keeps the XP for how far they got.
    private func finishTournament(placement: Int) {
        guard !hasSettled else { return }
        hasSettled = true
        if countsTowardProgress {
            if placement == 1, let human = engine.players.first(where: { $0.id == humanID }) {
                bankroll.applyDelta(human.chips)
                bankroll.addXP(300)
            } else {
                bankroll.addXP(max(50, 300 / placement))
            }
        }
        if challengeTrack == .sitAndGo {
            DailyChallengeManager.shared.recordTournamentFinish(placement: placement,
                                                                bigBlindReached: engine.bigBlind)
        }
        StatsManager.shared.recordTournamentFinish(mode: mode, placement: placement)
        AchievementManager.shared.checkAll()
        if placement == 1 {
            Haptics.wonPot()
        } else {
            Haptics.bustedOut()
        }
        GamePersistence.clearLocalGame()
    }

    /// Bumps the blinds to the next tournament level based on hands played
    /// so far, if one is configured.
    private func applyBlindEscalation(_ tournament: TournamentConfig) {
        guard tournament.handsPerLevel > 0, !tournament.blindLevels.isEmpty else { return }
        let levelIndex = min(engine.handNumber / tournament.handsPerLevel, tournament.blindLevels.count - 1)
        let level = tournament.blindLevels[levelIndex]
        if level.small != engine.smallBlind || level.big != engine.bigBlind {
            engine.setBlinds(small: level.small, big: level.big)
        }
    }

    /// Whether hands played here count toward XP and the Daily Challenges.
    /// Only the tables that cost chips to sit down at do: Play vs Bots, Sit &
    /// Go, and VIP High Stakes. The free Custom Table is a sandbox, and
    /// progress earned somewhere with no buy-in and no limit isn't worth
    /// anything -- you could grind out every challenge and the VIP unlock
    /// without ever putting a chip at risk.
    private var countsTowardProgress: Bool { usesBankroll }

    private var rebuyLabel: String {
        guard usesBankroll else { return "Rebuy" }
        let amount = min(buyIn, bankroll.chips)
        return amount > 0 ? "Rebuy for $\(amount)" : "Out of chips"
    }

    /// Which challenge track this table feeds. The cash table advances the
    /// Daily challenges; the tournaments advance the Sit & Go ones.
    private var challengeTrack: ChallengeTrack? {
        guard countsTowardProgress else { return nil }
        return tournament == nil ? .daily : .sitAndGo
    }

    /// Fires once per completed hand: feeds the XP and Daily Challenge
    /// systems, and escalates tournament blinds if applicable.
    private func handleHandEnd() {
        guard engine.handNumber > 0 else { return }
        if countsTowardProgress { bankroll.addXP(10) }
        if challengeTrack == .daily { DailyChallengeManager.shared.recordHandPlayed() }

        let won = engine.showdownResults.first(where: { $0.playerID == humanID })
        if let result = won {
            if countsTowardProgress { bankroll.addXP(20) }
            if challengeTrack == .daily {
                DailyChallengeManager.shared.recordHandWon()
                DailyChallengeManager.shared.recordPotWon(amount: result.amountWon)
                DailyChallengeManager.shared.recordShowdownWin(category: result.hand.category)
            }
            AchievementManager.shared.recordShowdownWin(category: result.hand.category)
            if difficulty == .hard { AchievementManager.shared.recordHardBotWin() }
            Haptics.wonPot()
        }

        StatsManager.shared.recordHand(
            mode: mode, won: won != nil, amountWon: won?.amountWon ?? 0,
            summary: won.map { "Won $\($0.amountWon) — \($0.hand.category.displayName)" } ?? "Lost the hand"
        )
        AchievementManager.shared.checkAll()

        if let tournament {
            applyBlindEscalation(tournament)
        }
    }

    private func rebuy() {
        var amount = buyIn
        if usesBankroll {
            // Short rebuy rather than nothing, so a thin bankroll still gets
            // you back in the hand -- but never more than you actually hold.
            amount = min(buyIn, bankroll.chips)
            guard amount > 0 else { return }
            bankroll.applyDelta(-amount)
        }
        engine.addChips(amount, to: humanID)
        engine.startNextHand()
    }

    /// Cashes the player's stack back into their persistent bankroll and
    /// clears the saved table -- use this for a deliberate "I'm done" exit,
    /// as opposed to `saveProgress()` which just pauses the hand.
    private func cashOutAndLeave() {
        guard !hasSettled else { dismiss(); return }
        hasSettled = true
        if usesBankroll, let human = engine.players.first(where: { $0.id == humanID }) {
            bankroll.applyDelta(human.chips)
        }
        if enableResume { GamePersistence.clearLocalGame() }
        dismiss()
    }

    /// Saves the table exactly as it stands so the player can back out (or
    /// have the app backgrounded/killed) and resume the same hand later.
    /// Chips already bought in stay "at the table" until a Cash Out. Only
    /// the classic "Play vs Bots" table participates in resume, so the
    /// other game modes never collide with its single save slot.
    private func saveProgress() {
        guard enableResume, !hasSettled else { return }
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
            let action = BotAI.decideAction(for: current, engine: engine, difficulty: difficulty)
            engine.apply(action, by: current.id)
        }
    }

    /// A light tap the moment it becomes the player's turn -- there are no
    /// sound-effect assets in this project, so haptics stand in for the
    /// "psst, you're up" cue a sound would normally give.
    private func notifyIfHumanTurn() {
        guard engine.currentPlayer()?.id == humanID else { return }
        Haptics.yourTurn()
    }
}
