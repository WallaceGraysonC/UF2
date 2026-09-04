import Foundation
import Combine

/// Drives a single blackjack table from round to round. This is the
/// authoritative game logic; in a multiplayer table the host device owns
/// the only live instance and broadcasts `GameState` snapshots to peers.
///
/// Unlike Hold'em, players never play against each other -- each seat's
/// hand(s) are settled independently against the dealer, so there's no
/// pot to split and no side-pot accounting. What replaces that complexity
/// here is per-hand bookkeeping: a player can be holding up to
/// `maxHandsPerPlayer` hands at once after splitting pairs.
final class BlackjackEngine: ObservableObject {
    @Published private(set) var players: [Player]
    @Published private(set) var dealer = DealerHand()
    @Published private(set) var phase: RoundPhase = .betting
    @Published private(set) var activePlayerIndex: Int?
    @Published private(set) var activeHandIndex: Int = 0
    @Published private(set) var roundNumber: Int = 0
    @Published private(set) var lastActionDescription: String = ""
    @Published private(set) var roundResults: [RoundResult] = []
    @Published private(set) var isRoundInProgress: Bool = false

    private(set) var minBet: Int
    private(set) var maxBet: Int
    private var shoe: Shoe

    /// Standard casino cap: an original hand plus three splits.
    static let maxHandsPerPlayer = 4

    init(players: [Player], minBet: Int = 10, maxBet: Int = 500, deckCount: Int = 6) {
        self.players = players
        self.minBet = minBet
        self.maxBet = maxBet
        self.shoe = Shoe(deckCount: deckCount)
    }

    /// Rebuilds an engine exactly where a previous session left off --
    /// including the exact remaining shoe order -- so a player can back out
    /// of a round and pick it back up later.
    convenience init(resuming snapshot: EngineSnapshot) {
        self.init(players: snapshot.players, minBet: snapshot.minBet, maxBet: snapshot.maxBet, deckCount: snapshot.deckCount)
        dealer = snapshot.dealer
        phase = snapshot.phase
        activePlayerIndex = snapshot.activePlayerIndex
        activeHandIndex = snapshot.activeHandIndex
        roundNumber = snapshot.roundNumber
        lastActionDescription = snapshot.lastActionDescription
        roundResults = snapshot.roundResults
        isRoundInProgress = snapshot.isRoundInProgress
        shoe = Shoe(cards: snapshot.shoeRemaining, deckCount: snapshot.deckCount)
    }

    /// Raises the table limits for a tournament's next level. Takes effect
    /// at the next `startNextRound()`.
    func setLimits(min: Int, max: Int) {
        minBet = min
        maxBet = max
    }

    // MARK: - Round lifecycle

    func startNextRound() {
        // Drop anyone who busted out of chips during the previous round --
        // there's no mid-tournament rebuy, and a cash table shouldn't keep
        // dealing cards to a seat that can never bet again. Without this,
        // a tournament's "one player left" win condition could never fire.
        players.removeAll { $0.isEliminated }
        guard !players.isEmpty else {
            lastActionDescription = "Not enough players with chips to continue."
            isRoundInProgress = false
            activePlayerIndex = nil
            return
        }
        if shoe.needsReshuffle { shoe.reshuffleFresh() }

        roundNumber += 1
        for i in players.indices { players[i].resetForNewRound() }
        dealer = DealerHand()
        roundResults = []
        phase = .betting
        activePlayerIndex = nil
        activeHandIndex = 0
        isRoundInProgress = true
        lastActionDescription = ""

        // Bots bet immediately; the human bets via placeBet(_:for:) from the UI.
        for i in players.indices where players[i].isBot && !players[i].isEliminated {
            let amount = BlackjackBotAI.decideBet(chips: players[i].chips, minBet: minBet, maxBet: maxBet)
            placeBetInternal(amount, playerIndex: i)
        }
    }

    func placeBet(_ amount: Int, for playerID: String) {
        guard phase == .betting, let idx = players.firstIndex(where: { $0.id == playerID }) else { return }
        placeBetInternal(amount, playerIndex: idx)
        if allEligiblePlayersHaveBet { dealInitialCards() }
    }

    private func placeBetInternal(_ amount: Int, playerIndex: Int) {
        guard players[playerIndex].hands.isEmpty, !players[playerIndex].isEliminated else { return }
        let clamped = min(max(amount, minBet), min(maxBet, players[playerIndex].chips))
        guard clamped > 0 else { return }
        let actual = players[playerIndex].deduct(clamped)
        players[playerIndex].hands = [BlackjackHand(id: "\(players[playerIndex].id)-0", bet: actual)]
    }

    private var eligiblePlayerIndices: [Int] { players.indices.filter { !players[$0].isEliminated } }
    private var allEligiblePlayersHaveBet: Bool {
        eligiblePlayerIndices.allSatisfy { !players[$0].hands.isEmpty }
    }

    private func dealInitialCards() {
        let seated = players.indices.filter { !players[$0].hands.isEmpty }
        guard !seated.isEmpty else { return }
        for _ in 0..<2 {
            for i in seated { players[i].hands[0].cards.append(dealCard()) }
            dealer.cards.append(dealCard())
        }
        lastActionDescription = "Cards dealt."
        offerInsuranceIfNeeded()
    }

    private func dealCard() -> Card { shoe.deal() ?? Card(rank: .two, suit: .clubs) }

    // MARK: - Insurance / dealer peek

    private var dealerShowsAce: Bool { dealer.upCard?.rank == .ace }

    private func offerInsuranceIfNeeded() {
        guard dealerShowsAce else { proceedPastPeek(); return }
        phase = .insurance
        for i in players.indices where !players[i].hands.isEmpty && players[i].isBot {
            applyInsuranceDecision(BlackjackBotAI.decideInsurance(), playerIndex: i)
        }
        if let humanIdx = players.firstIndex(where: { !$0.hands.isEmpty && !$0.isBot && !$0.hasDecidedInsurance }) {
            activePlayerIndex = humanIdx
        } else {
            proceedPastPeek()
        }
    }

    func decideInsurance(_ accept: Bool, for playerID: String) {
        guard phase == .insurance, let idx = players.firstIndex(where: { $0.id == playerID }),
              !players[idx].hasDecidedInsurance else { return }
        applyInsuranceDecision(accept, playerIndex: idx)
        // Advance to the next undecided seat (relevant in multiplayer with
        // more than one human at the table) rather than just checking
        // whether everyone's done -- otherwise a second player's insurance
        // prompt would never actually appear.
        if let nextIdx = players.firstIndex(where: { !$0.hands.isEmpty && !$0.hasDecidedInsurance }) {
            activePlayerIndex = nextIdx
        } else {
            proceedPastPeek()
        }
    }

    private func applyInsuranceDecision(_ accept: Bool, playerIndex: Int) {
        if accept, let bet = players[playerIndex].hands.first?.bet {
            let actual = players[playerIndex].deduct(bet / 2)
            players[playerIndex].insuranceBet = actual
        }
        players[playerIndex].hasDecidedInsurance = true
    }

    /// Checks the dealer's hidden hole card for blackjack -- the moment
    /// that ends the round outright if the up card is an ace or a ten-value
    /// card, before any player gets to act.
    private func proceedPastPeek() {
        guard dealerShowsAce || (dealer.upCard?.rank.blackjackValue ?? 0) == 10 else {
            beginPlayerTurns()
            return
        }
        if dealer.isBlackjack {
            resolveDealerBlackjack()
        } else {
            beginPlayerTurns()
        }
    }

    private func resolveDealerBlackjack() {
        dealer.holeCardRevealed = true
        activePlayerIndex = nil
        var results: [RoundResult] = []
        for i in players.indices where !players[i].hands.isEmpty {
            let hand = players[i].hands[0]
            let outcome: HandOutcome = hand.isBlackjack ? .push : .lose
            let returned = hand.isBlackjack ? hand.bet : 0
            if returned > 0 { players[i].chips += returned }
            results.append(RoundResult(playerID: players[i].id, playerName: players[i].name, handIndex: 0,
                                        outcome: outcome, amountReturned: returned, handTotal: hand.total))
            if players[i].insuranceBet > 0 {
                players[i].chips += players[i].insuranceBet * 3 // stake back plus 2:1
            }
        }
        roundResults = results
        lastActionDescription = "Dealer has Blackjack."
        phase = .payout
        isRoundInProgress = false
    }

    // MARK: - Player turns

    private func beginPlayerTurns() {
        phase = .playerTurns
        activePlayerIndex = players.indices.first { !players[$0].hands.isEmpty }
        activeHandIndex = 0
        advanceToNextActionableHand()
    }

    var currentPlayer: Player? {
        guard let idx = activePlayerIndex, players.indices.contains(idx) else { return nil }
        return players[idx]
    }

    var currentHand: BlackjackHand? {
        guard let player = currentPlayer, player.hands.indices.contains(activeHandIndex) else { return nil }
        return player.hands[activeHandIndex]
    }

    var canDoubleDownNow: Bool {
        guard phase == .playerTurns, let hand = currentHand, let player = currentPlayer else { return false }
        return hand.cards.count == 2 && !hand.isDoubled && !hand.isSplitAceHand && player.chips >= hand.bet
    }

    var canSplitNow: Bool {
        guard phase == .playerTurns, let hand = currentHand, let player = currentPlayer,
              hand.cards.count == 2, hand.cards[0].rank == hand.cards[1].rank else { return false }
        return player.hands.count < Self.maxHandsPerPlayer && player.chips >= hand.bet
    }

    var canSurrenderNow: Bool {
        guard phase == .playerTurns, let hand = currentHand else { return false }
        return hand.canBeNatural && hand.cards.count == 2
    }

    func apply(_ action: PlayerAction, by playerID: String) {
        guard phase == .playerTurns, let idx = activePlayerIndex, players.indices.contains(idx),
              players[idx].id == playerID, players[idx].hands.indices.contains(activeHandIndex) else { return }

        var hand = players[idx].hands[activeHandIndex]
        switch action {
        case .hit:
            let card = dealCard()
            hand.cards.append(card)
            players[idx].hands[activeHandIndex] = hand
            lastActionDescription = "\(players[idx].name) hits and draws \(card.rank.label)\(card.suit.symbol) — \(hand.displayTotal)."
            if hand.isResolved { advanceToNextActionableHand() }

        case .stand:
            hand.isStood = true
            players[idx].hands[activeHandIndex] = hand
            lastActionDescription = "\(players[idx].name) stands on \(hand.displayTotal)."
            advanceToNextActionableHand()

        case .doubleDown:
            guard canDoubleDownNow else { return }
            let extra = players[idx].deduct(hand.bet)
            hand.bet += extra
            hand.isDoubled = true
            let card = dealCard()
            hand.cards.append(card)
            players[idx].hands[activeHandIndex] = hand
            lastActionDescription = "\(players[idx].name) doubles down, draws \(card.rank.label)\(card.suit.symbol) — \(hand.displayTotal)."
            advanceToNextActionableHand()

        case .split:
            guard canSplitNow else { return }
            performSplit(playerIndex: idx, handIndex: activeHandIndex)
            lastActionDescription = "\(players[idx].name) splits."
            if players[idx].hands[activeHandIndex].isResolved { advanceToNextActionableHand() }

        case .surrender:
            guard canSurrenderNow else { return }
            hand.isSurrendered = true
            players[idx].hands[activeHandIndex] = hand
            lastActionDescription = "\(players[idx].name) surrenders."
            advanceToNextActionableHand()

        case .placeBet, .insurance:
            return // wrong phase, no-op
        }
    }

    private func performSplit(playerIndex: Int, handIndex: Int) {
        let hand = players[playerIndex].hands[handIndex]
        let extraBet = players[playerIndex].deduct(hand.bet)
        let isAceSplit = hand.cards[0].rank == .ace

        var handA = BlackjackHand(id: hand.id + "a", cards: [hand.cards[0]], bet: hand.bet, canBeNatural: false, isSplitAceHand: isAceSplit)
        var handB = BlackjackHand(id: hand.id + "b", cards: [hand.cards[1]], bet: extraBet, canBeNatural: false, isSplitAceHand: isAceSplit)
        handA.cards.append(dealCard())
        handB.cards.append(dealCard())

        players[playerIndex].hands.replaceSubrange(handIndex...handIndex, with: [handA, handB])
    }

    /// Moves to the next hand that still needs a decision -- the next hand
    /// for the same player after a split, or the first hand of the next
    /// seated player, or the dealer's turn once nobody's left to act.
    private func advanceToNextActionableHand() {
        guard var pIdx = activePlayerIndex else { moveToDealerTurn(); return }
        var hIdx = activeHandIndex
        while pIdx < players.count {
            guard !players[pIdx].hands.isEmpty else { pIdx += 1; hIdx = 0; continue }
            guard hIdx < players[pIdx].hands.count else { pIdx += 1; hIdx = 0; continue }
            if players[pIdx].hands[hIdx].isResolved {
                hIdx += 1
            } else {
                activePlayerIndex = pIdx
                activeHandIndex = hIdx
                return
            }
        }
        activePlayerIndex = nil
        moveToDealerTurn()
    }

    // MARK: - Dealer turn / payout

    private func moveToDealerTurn() {
        phase = .dealerTurn
        activePlayerIndex = nil
        dealer.holeCardRevealed = true

        // A hand still "live" is one that could still beat or lose to
        // whatever the dealer draws -- surrendered/busted hands are already
        // settled, and a natural blackjack is paid independent of the
        // dealer's final total (already confirmed not to be a push).
        let anyLiveHands = players.contains { player in
            player.hands.contains { !$0.isBusted && !$0.isSurrendered && !$0.isBlackjack }
        }
        if anyLiveHands {
            while dealer.total < 17 { dealer.cards.append(dealCard()) }
        }
        lastActionDescription = dealer.isBusted ? "Dealer busts with \(dealer.total)." : "Dealer stands with \(dealer.displayTotal)."
        resolveRound()
    }

    private func resolveRound() {
        var results: [RoundResult] = []
        for i in players.indices {
            for h in players[i].hands.indices {
                let hand = players[i].hands[h]
                guard hand.bet > 0 else { continue }
                let outcome: HandOutcome
                var returned = 0
                if hand.isSurrendered {
                    outcome = .surrender
                    returned = hand.bet / 2
                } else if hand.isBusted {
                    outcome = .bust
                } else if hand.isBlackjack {
                    outcome = .blackjack
                    returned = hand.bet + hand.bet * 3 / 2
                } else if dealer.isBusted || hand.total > dealer.total {
                    outcome = .win
                    returned = hand.bet * 2
                } else if hand.total == dealer.total {
                    outcome = .push
                    returned = hand.bet
                } else {
                    outcome = .lose
                }
                if returned > 0 { players[i].chips += returned }
                results.append(RoundResult(playerID: players[i].id, playerName: players[i].name, handIndex: h,
                                            outcome: outcome, amountReturned: returned, handTotal: hand.total))
            }
        }
        roundResults = results
        phase = .payout
        isRoundInProgress = false
    }

    /// Tops up a player's stack outside of a round, e.g. a rebuy funded from
    /// the persistent bankroll after busting out.
    func addChips(_ amount: Int, to playerID: String) {
        guard let idx = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[idx].chips += amount
    }

    // MARK: - Snapshots

    func makeSnapshotForPersistence() -> EngineSnapshot {
        EngineSnapshot(
            players: players, dealer: dealer, phase: phase,
            activePlayerIndex: activePlayerIndex, activeHandIndex: activeHandIndex,
            roundNumber: roundNumber, lastActionDescription: lastActionDescription,
            roundResults: roundResults, isRoundInProgress: isRoundInProgress,
            shoeRemaining: shoe.cards, deckCount: shoe.deckCount, minBet: minBet, maxBet: maxBet
        )
    }

    /// Builds a state snapshot to broadcast to a multiplayer peer. Every
    /// player's hand is public in blackjack, so -- unlike Hold'em hole
    /// cards -- nothing about a player needs to be hidden viewer-by-viewer;
    /// only the dealer's hole card is masked until it's actually revealed.
    func snapshot(for viewerID: String) -> GameState {
        GameState(players: players, dealer: DealerHand(cards: dealer.visibleCards, holeCardRevealed: dealer.holeCardRevealed),
                   phase: phase, activePlayerIndex: activePlayerIndex, activeHandIndex: activeHandIndex,
                   minBet: minBet, maxBet: maxBet, roundNumber: roundNumber,
                   lastActionDescription: lastActionDescription, roundResults: roundResults)
    }
}

private extension Player {
    /// Puts chips at risk (a bet, a double, an insurance side bet),
    /// capping at the player's stack, and returns how much was actually
    /// taken.
    @discardableResult
    mutating func deduct(_ amount: Int) -> Int {
        let actual = min(amount, chips)
        chips -= actual
        return actual
    }
}
