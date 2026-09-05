import SwiftUI

/// Practice table against bots -- fully offline, no network required.
struct LocalGameView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var engine: BlackjackEngine
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
    /// When set, this is a Tournament: no rebuys, table limits escalate
    /// over time, and busting/winning ends the session with a placement
    /// screen instead of returning to the felt.
    private let tournament: TournamentConfig?
    @State private var hasSettled = false
    @State private var showRulesGuide = false
    /// Remembers what the human bet last round so the bet builder can
    /// default to "same as last time" -- most players re-bet the same
    /// amount round after round.
    @State private var lastBetAmount: Int?

    struct TournamentConfig {
        let limitLevels: [(min: Int, max: Int)]
        let handsPerLevel: Int
    }

    init(botCount: Int = 4, buyIn: Int = 500, minBet: Int = 10, maxBet: Int = 500,
         enableResume: Bool = true, tableTitle: String = "",
         usesBankroll: Bool = true, tournament: TournamentConfig? = nil) {
        self.enableResume = enableResume
        self.tableTitle = tableTitle
        self.usesBankroll = usesBankroll
        self.tournament = tournament
        if enableResume, let saved = GamePersistence.loadLocalGame() {
            _engine = StateObject(wrappedValue: BlackjackEngine(resuming: saved.engine))
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
            let names = BotNames.uniqueNames(count: botCount)
            let bots = (1...botCount).map { i -> Player in
                var bot = Player(id: "bot-\(i)", name: names[i - 1], chips: buyIn, isBot: true,
                       cardBackID: BankrollManager.shared.equippedCardBack,
                       cardFaceID: BankrollManager.shared.equippedCardFace,
                       avatarID: BotNames.randomAvatar())
                bot.seatIndex = i
                return bot
            }
            _engine = StateObject(wrappedValue: BlackjackEngine(players: [human] + bots, minBet: minBet, maxBet: maxBet))
            self.humanID = human.id
            self.buyIn = buyIn
            self.seatedBuyIn = seated
            self.resumedFromSave = false
        }
    }

    /// The table's fixed seat count, established when players first sat down
    /// -- seats are positioned against this instead of the live (shrinking)
    /// player count, so a bust just empties a seat instead of reshuffling
    /// everyone else around a smaller table.
    private var totalSeats: Int {
        (engine.players.map { $0.seatIndex }.max() ?? engine.players.count - 1) + 1
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackdropView(id: bankroll.equippedBackdrop).ignoresSafeArea()
                DealerAreaView(dealer: engine.dealer, feltID: bankroll.equippedFelt, railID: bankroll.equippedRail, cardBackID: bankroll.equippedCardBack, cardFaceID: bankroll.equippedCardFace) { feltSize in
                    // The human's own seat is drawn separately below, layered
                    // above the button panel -- everyone else stays at the table.
                    ForEach(Array(engine.players.enumerated()), id: \.element.id) { index, player in
                        if player.id != humanID {
                            let offset = SeatLayout.offsets(count: totalSeats)[player.seatIndex]
                            PlayerSeatView(
                                player: player,
                                isActive: engine.activePlayerIndex == index,
                                activeHandIndex: engine.activeHandIndex,
                                results: engine.roundResults.filter { $0.playerID == player.id },
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
                    if !engine.lastActionDescription.isEmpty || currentHandBadgeText != nil {
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
                            if let text = currentHandBadgeText {
                                HandValueBadge(text: text)
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
                        activeHandIndex: engine.activeHandIndex,
                        results: engine.roundResults.filter { $0.playerID == humanID }
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
                engine.startNextRound()
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
            if engine.phase == .playerTurns, engine.currentPlayer?.id == humanID { Haptics.yourTurn() }
        }
        .onChange(of: engine.phase) { _, _ in runBotTurnIfNeeded() }
        .onChange(of: engine.isRoundInProgress) { _, inProgress in
            if !inProgress { handleRoundEnd() }
        }
    }

    /// What the human is currently holding, for the badge above the table --
    /// their active hand's total while acting, else nothing.
    private var currentHandBadgeText: String? {
        guard engine.phase == .playerTurns, engine.currentPlayer?.id == humanID, let hand = engine.currentHand,
              !hand.cards.isEmpty else { return nil }
        return hand.displayTotal
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
            Button { showRulesGuide = true } label: {
                Label("Rules", systemImage: "questionmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(BJTheme.goldBright)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(BJTheme.gold.opacity(0.5), lineWidth: 1))
            }
        }
        .padding()
        .sheet(isPresented: $showRulesGuide) { BlackjackRulesGuideView() }
    }

    @ViewBuilder
    private var footer: some View {
        if let human = engine.players.first(where: { $0.id == humanID }) {
            if engine.phase == .payout, !engine.isRoundInProgress {
                if let tournament {
                    tournamentFooter(human: human, tournament: tournament)
                } else {
                    payoutFooter(human: human)
                }
            } else if engine.phase == .insurance, engine.currentPlayer?.id == humanID {
                InsuranceControlsView(insuranceCost: (human.hands.first?.bet ?? 0) / 2) { accept in
                    engine.decideInsurance(accept, for: humanID)
                }
                .padding(.bottom, 12)
            } else if engine.phase == .playerTurns, engine.currentPlayer?.id == humanID {
                HandActionControlsView(
                    canDouble: engine.canDoubleDownNow, canSplit: engine.canSplitNow, canSurrender: engine.canSurrenderNow,
                    onAction: { engine.apply($0, by: humanID) }
                )
                .padding(.bottom, 12)
            } else if engine.phase == .betting, human.hands.isEmpty, human.chips > 0 {
                BetBuilderView(chips: human.chips, minBet: engine.minBet, maxBet: engine.maxBet, defaultBet: lastBetAmount) { amount in
                    lastBetAmount = amount
                    engine.placeBet(amount, for: humanID)
                }
                .padding(.bottom, 12)
            }
        }
    }

    @ViewBuilder
    private func payoutFooter(human: Player) -> some View {
        VStack(spacing: 10) {
            let humanResults = engine.roundResults.filter { $0.playerID == humanID }
            ForEach(humanResults) { result in
                Text(result.summaryText)
                    .font(.footnote.bold())
                    .foregroundColor(.yellow)
            }
            if human.chips > 0 {
                HStack(spacing: 12) {
                    Button { engine.startNextRound() } label: {
                        Text("Next Hand").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button { cashOutAndLeave() } label: {
                        Text(usesBankroll ? "Cash Out" : "Leave Table").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                .padding(.horizontal, 40)
            } else {
                Button { rebuy() } label: {
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
                    .foregroundColor(BJTheme.goldBright)
                }
            }
        }
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func tournamentFooter(human: Player, tournament: TournamentConfig) -> some View {
        VStack(spacing: 10) {
            let humanResults = engine.roundResults.filter { $0.playerID == humanID }
            ForEach(humanResults) { result in
                Text(result.summaryText)
                    .font(.footnote.bold())
                    .foregroundColor(.yellow)
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
                    .foregroundColor(BJTheme.goldBright)
                Button("Collect Winnings") {
                    finishTournament(placement: 1)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
            } else {
                Button("Next Hand") { engine.startNextRound() }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 40)
            }
        }
        .padding(.bottom, 20)
    }

    /// Settles a finished Tournament: the winner's whole stack converts back
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
        if challengeTrack == .tournament {
            DailyChallengeManager.shared.recordTournamentFinish(placement: placement, minBetReached: engine.minBet)
        }
        GamePersistence.clearLocalGame()
    }

    /// Bumps the table limits to the next tournament level based on hands
    /// played so far, if one is configured.
    private func applyLimitEscalation(_ tournament: TournamentConfig) {
        guard tournament.handsPerLevel > 0, !tournament.limitLevels.isEmpty else { return }
        let levelIndex = min(engine.roundNumber / tournament.handsPerLevel, tournament.limitLevels.count - 1)
        let level = tournament.limitLevels[levelIndex]
        if level.min != engine.minBet || level.max != engine.maxBet {
            engine.setLimits(min: level.min, max: level.max)
        }
    }

    /// Whether hands played here count toward XP and the Daily Challenges.
    /// Only the tables that cost chips to sit down at do: Play vs Bots,
    /// Tournament, and VIP High Stakes. The free Custom Table is a sandbox,
    /// and progress earned somewhere with no buy-in and no limit isn't
    /// worth anything -- you could grind out every challenge and the VIP
    /// unlock without ever putting a chip at risk.
    private var countsTowardProgress: Bool { usesBankroll }

    private var rebuyLabel: String {
        guard usesBankroll else { return "Rebuy" }
        let amount = min(buyIn, bankroll.chips)
        return amount > 0 ? "Rebuy for $\(amount)" : "Out of chips"
    }

    /// Which challenge track this table feeds. The cash table advances the
    /// Daily challenges; the tournaments advance the Tournament ones.
    private var challengeTrack: ChallengeTrack? {
        guard countsTowardProgress else { return nil }
        return tournament == nil ? .daily : .tournament
    }

    /// Fires once per completed round: feeds the XP and Daily Challenge
    /// systems, and escalates tournament limits if applicable.
    private func handleRoundEnd() {
        guard engine.roundNumber > 0 else { return }
        if countsTowardProgress { bankroll.addXP(10) }
        if challengeTrack == .daily { DailyChallengeManager.shared.recordHandPlayed() }

        let humanResults = engine.roundResults.filter { $0.playerID == humanID }
        let won = humanResults.contains { $0.outcome == .win || $0.outcome == .blackjack }
        if won {
            Haptics.wonHand()
        } else if engine.players.first(where: { $0.id == humanID })?.chips == 0 {
            Haptics.bustedOut()
        }

        for result in humanResults {
            guard result.outcome == .win || result.outcome == .blackjack else { continue }
            if countsTowardProgress { bankroll.addXP(result.outcome == .blackjack ? 30 : 20) }
            if challengeTrack == .daily {
                DailyChallengeManager.shared.recordHandWon(amount: result.amountReturned)
                if result.outcome == .blackjack { DailyChallengeManager.shared.recordBlackjackWin() }
            }
        }
        if let tournament { applyLimitEscalation(tournament) }
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
        engine.startNextRound()
    }

    /// Cashes the player's stack back into their persistent bankroll and
    /// clears the saved table -- use this for a deliberate "I'm done" exit,
    /// as opposed to `saveProgress()` which just pauses the round.
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
    /// have the app backgrounded/killed) and resume the same round later.
    /// Chips already bought in stay "at the table" until a Cash Out. Only
    /// the classic "Play vs Bots" table participates in resume, so the
    /// other game modes never collide with its single save slot.
    private func saveProgress() {
        guard enableResume, !hasSettled else { return }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard engine.currentPlayer?.id == current.id else { return }
            let action = BlackjackBotAI.decideAction(hand: hand, dealerUpCard: dealerUpCard,
                                                      canDouble: engine.canDoubleDownNow, canSplit: engine.canSplitNow,
                                                      canSurrender: engine.canSurrenderNow)
            engine.apply(action, by: current.id)
        }
    }
}
