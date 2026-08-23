import Foundation
import Combine

/// Drives a single table of Texas Hold'em from hand to hand. This is the
/// authoritative game logic; in a multiplayer match the host device owns the
/// only live instance and broadcasts `GameState` snapshots to peers.
final class PokerEngine: ObservableObject {
    @Published private(set) var players: [Player]
    @Published private(set) var communityCards: [Card] = []
    @Published private(set) var round: BettingRound = .preFlop
    @Published private(set) var dealerIndex: Int
    @Published private(set) var activePlayerIndex: Int?
    @Published private(set) var currentBet: Int = 0
    @Published private(set) var minRaise: Int
    @Published private(set) var handNumber: Int = 0
    @Published private(set) var lastActionDescription: String = ""
    @Published private(set) var showdownResults: [ShowdownResult] = []
    @Published private(set) var isHandInProgress: Bool = false

    let smallBlind: Int
    let bigBlind: Int

    private var deck = Deck()
    private var pots: [PotShare] = []
    private var playersActedThisRound: Set<String> = []

    var potTotal: Int { pots.reduce(0) { $0 + $1.amount } + players.reduce(0) { $0 + $1.currentBet } }

    init(players: [Player], smallBlind: Int = 25, bigBlind: Int = 50, dealerIndex: Int = 0) {
        self.players = players
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
        self.minRaise = bigBlind
        self.dealerIndex = dealerIndex
    }

    /// Rebuilds an engine exactly where a previous session left off --
    /// including cards already dealt and cards still left in the deck --
    /// so a player can back out of a hand and pick it back up later.
    convenience init(resuming snapshot: EngineSnapshot) {
        self.init(players: snapshot.players, smallBlind: snapshot.smallBlind, bigBlind: snapshot.bigBlind, dealerIndex: snapshot.dealerIndex)
        communityCards = snapshot.communityCards
        round = snapshot.round
        activePlayerIndex = snapshot.activePlayerIndex
        currentBet = snapshot.currentBet
        minRaise = snapshot.minRaise
        handNumber = snapshot.handNumber
        lastActionDescription = snapshot.lastActionDescription
        showdownResults = snapshot.showdownResults
        isHandInProgress = snapshot.isHandInProgress
        deck = Deck(cards: snapshot.deckRemaining)
        pots = snapshot.pots
        playersActedThisRound = Set(snapshot.playersActedThisRound)
    }

    // MARK: - Hand lifecycle

    func startNextHand() {
        players.removeAll { $0.chips <= 0 }
        guard players.count >= 2 else {
            lastActionDescription = "Not enough players with chips to continue."
            isHandInProgress = false
            return
        }

        handNumber += 1
        isHandInProgress = true
        deck = Deck()
        communityCards = []
        pots = []
        showdownResults = []
        round = .preFlop

        for i in players.indices { players[i].resetForNewHand() }

        dealerIndex = dealerIndex % players.count
        postBlinds()
        dealHoleCards()

        activePlayerIndex = nextToAct(after: firstToActIndex(for: .preFlop))
        currentBet = bigBlind
        minRaise = bigBlind
        playersActedThisRound = []
    }

    private func postBlinds() {
        let sbIndex = players.count == 2 ? dealerIndex : (dealerIndex + 1) % players.count
        let bbIndex = players.count == 2 ? (dealerIndex + 1) % players.count : (dealerIndex + 2) % players.count
        players[sbIndex].bet(smallBlind)
        players[bbIndex].bet(bigBlind)
        lastActionDescription = "\(players[sbIndex].name) posts small blind, \(players[bbIndex].name) posts big blind."
    }

    private func dealHoleCards() {
        for i in players.indices {
            players[i].holeCards = deck.deal(2)
        }
    }

    private func firstToActIndex(for round: BettingRound) -> Int {
        if round == .preFlop {
            return players.count == 2 ? dealerIndex : (dealerIndex + 3) % players.count
        }
        return (dealerIndex + 1) % players.count
    }

    // MARK: - Actions

    func currentPlayer() -> Player? {
        guard let idx = activePlayerIndex else { return nil }
        return players[idx]
    }

    func availableActions(for player: Player) -> [String] {
        guard !player.isFolded, !player.isAllIn else { return [] }
        var actions = ["fold"]
        if player.currentBet == currentBet {
            actions.append("check")
        } else {
            actions.append("call")
        }
        if player.chips > 0 {
            actions.append(currentBet == 0 ? "bet" : "raise")
        }
        return actions
    }

    func apply(_ action: PlayerAction, by playerID: String) {
        guard let idx = players.firstIndex(where: { $0.id == playerID }) else { return }
        guard idx == activePlayerIndex else { return }

        switch action {
        case .fold:
            players[idx].isFolded = true
            lastActionDescription = "\(players[idx].name) folds."
        case .check:
            lastActionDescription = "\(players[idx].name) checks."
        case .call:
            let toCall = currentBet - players[idx].currentBet
            players[idx].bet(toCall)
            lastActionDescription = "\(players[idx].name) calls \(toCall)."
        case .bet(let amount), .raise(let amount):
            let target = max(amount, currentBet + minRaise)
            let delta = target - players[idx].currentBet
            let raiseAmount = target - currentBet
            players[idx].bet(delta)
            minRaise = max(minRaise, raiseAmount)
            currentBet = players[idx].currentBet
            playersActedThisRound = [playerID]
            lastActionDescription = "\(players[idx].name) bets to \(currentBet)."
        case .allIn:
            let delta = players[idx].chips
            players[idx].bet(delta)
            if players[idx].currentBet > currentBet {
                minRaise = max(minRaise, players[idx].currentBet - currentBet)
                currentBet = players[idx].currentBet
                playersActedThisRound = [playerID]
            }
            lastActionDescription = "\(players[idx].name) is all in!"
        }

        players[idx].hasActedThisRound = true
        playersActedThisRound.insert(playerID)

        advanceTurn()
    }

    // MARK: - Turn / round progression

    private func activePlayers() -> [Player] {
        players.filter { !$0.isFolded }
    }

    private func playersStillToAct() -> [Player] {
        players.filter { !$0.isFolded && !$0.isAllIn }
    }

    private func advanceTurn() {
        if activePlayers().count == 1 {
            finishHandByFold()
            return
        }

        let contenders = playersStillToAct()
        let allMatched = contenders.allSatisfy { $0.currentBet == currentBet && playersActedThisRound.contains($0.id) }

        if contenders.isEmpty || allMatched {
            advanceRound()
            return
        }

        activePlayerIndex = nextToAct(after: activePlayerIndex ?? dealerIndex)
    }

    private func nextToAct(after index: Int) -> Int? {
        guard !players.isEmpty else { return nil }
        var i = index
        for _ in 0..<players.count {
            i = (i + 1) % players.count
            let p = players[i]
            if !p.isFolded && !p.isAllIn { return i }
        }
        return nil
    }

    private func advanceRound() {
        collectBetsIntoPots()

        guard playersStillToAct().count >= 2 || (playersStillToAct().count >= 1 && activePlayers().count > 1) else {
            // Everyone remaining is all-in; run out the board.
            runOutBoardAndShowdown()
            return
        }

        switch round {
        case .preFlop:
            round = .flop
            communityCards += deck.deal(3)
        case .flop:
            round = .turn
            communityCards += deck.deal(1)
        case .turn:
            round = .river
            communityCards += deck.deal(1)
        case .river:
            round = .showdown
            resolveShowdown()
            return
        case .showdown:
            return
        }

        currentBet = 0
        minRaise = bigBlind
        playersActedThisRound = []
        for i in players.indices { players[i].currentBet = 0; players[i].hasActedThisRound = false }
        activePlayerIndex = nextToAct(after: dealerIndex)
    }

    private func runOutBoardAndShowdown() {
        collectBetsIntoPots()
        while round != .river {
            switch round {
            case .preFlop: round = .flop; communityCards += deck.deal(3)
            case .flop: round = .turn; communityCards += deck.deal(1)
            case .turn: round = .river; communityCards += deck.deal(1)
            default: break
            }
        }
        round = .showdown
        resolveShowdown()
    }

    private func collectBetsIntoPots() {
        var contributors = players.filter { $0.currentBet > 0 || $0.totalBetThisHand > 0 }
        while contributors.contains(where: { $0.currentBet > 0 }) {
            let smallestBet = contributors.filter { $0.currentBet > 0 }.map { $0.currentBet }.min() ?? 0
            guard smallestBet > 0 else { break }
            var potAmount = 0
            var eligible: Set<String> = []
            for i in contributors.indices where contributors[i].currentBet > 0 {
                let take = min(smallestBet, contributors[i].currentBet)
                potAmount += take
                contributors[i].currentBet -= take
                if !players.first(where: { $0.id == contributors[i].id })!.isFolded {
                    eligible.insert(contributors[i].id)
                }
            }
            pots.append(PotShare(id: pots.count, amount: potAmount, eligiblePlayerIDs: eligible))
            for c in contributors {
                if let idx = players.firstIndex(where: { $0.id == c.id }) {
                    players[idx].currentBet = c.currentBet
                }
            }
        }
        for i in players.indices { players[i].currentBet = 0 }
    }

    private func finishHandByFold() {
        collectBetsIntoPots()
        guard let winner = activePlayers().first,
              let winnerIdx = players.firstIndex(where: { $0.id == winner.id }) else { return }
        let winnings = pots.reduce(0) { $0 + $1.amount }
        players[winnerIdx].chips += winnings
        showdownResults = [ShowdownResult(playerID: winner.id, playerName: winner.name,
                                           hand: HandRank(category: .highCard, tiebreakers: []),
                                           amountWon: winnings)]
        lastActionDescription = "\(winner.name) wins \(winnings) (all others folded)."
        round = .showdown
        activePlayerIndex = nil
        isHandInProgress = false
        rotateDealer()
    }

    private func resolveShowdown() {
        var results: [ShowdownResult] = []
        let contenders = activePlayers()

        for pot in pots {
            let eligible = contenders.filter { pot.eligiblePlayerIDs.contains($0.id) }
            guard !eligible.isEmpty else { continue }
            let ranked = eligible.map { player -> (Player, HandRank) in
                (player, HandEvaluator.bestHand(from: player.holeCards + communityCards))
            }
            let best = ranked.map { $0.1 }.max()!
            let winners = ranked.filter { $0.1 == best }
            let share = pot.amount / winners.count
            var remainder = pot.amount % winners.count
            for (player, hand) in winners {
                guard let idx = players.firstIndex(where: { $0.id == player.id }) else { continue }
                var amount = share
                if remainder > 0 { amount += 1; remainder -= 1 }
                players[idx].chips += amount
                if let existingIdx = results.firstIndex(where: { $0.playerID == player.id }) {
                    results[existingIdx].amountWon += amount
                } else {
                    results.append(ShowdownResult(playerID: player.id, playerName: player.name, hand: hand, amountWon: amount))
                }
            }
        }

        showdownResults = results
        lastActionDescription = results.map { "\($0.playerName) wins \($0.amountWon) with \($0.hand.category.displayName)" }.joined(separator: "; ")
        activePlayerIndex = nil
        isHandInProgress = false
        rotateDealer()
    }

    private func rotateDealer() {
        guard !players.isEmpty else { return }
        dealerIndex = (dealerIndex + 1) % players.count
    }

    /// Best current hand description for `playerID`, e.g. "Two Pair", based
    /// on their hole cards plus whatever community cards are showing. Used
    /// to teach the player what they're holding as the board comes out.
    /// Returns nil before enough cards are dealt to form a 5-card hand.
    func handDescription(for playerID: String) -> String? {
        guard let player = players.first(where: { $0.id == playerID }), player.holeCards.count == 2 else { return nil }
        let allCards = player.holeCards + communityCards
        guard allCards.count >= 5 else { return nil }
        return HandEvaluator.bestHand(from: allCards).category.displayName
    }

    /// Tops up a player's stack outside of a hand, e.g. a rebuy funded from
    /// the persistent bankroll after busting out.
    func addChips(_ amount: Int, to playerID: String) {
        guard let idx = players.firstIndex(where: { $0.id == playerID }) else { return }
        players[idx].chips += amount
    }

    /// A full snapshot suitable for saving to disk and resuming later --
    /// unlike `snapshot(for:)`, this keeps every hole card since it never
    /// leaves the device.
    func makeSnapshotForPersistence() -> EngineSnapshot {
        EngineSnapshot(
            players: players, communityCards: communityCards, round: round,
            dealerIndex: dealerIndex, activePlayerIndex: activePlayerIndex,
            currentBet: currentBet, minRaise: minRaise, handNumber: handNumber,
            lastActionDescription: lastActionDescription, showdownResults: showdownResults,
            isHandInProgress: isHandInProgress, deckRemaining: deck.cards, pots: pots,
            playersActedThisRound: Array(playersActedThisRound),
            smallBlind: smallBlind, bigBlind: bigBlind
        )
    }

    // MARK: - Snapshot for networking

    /// Builds a state snapshot to send to one participant. Other players'
    /// hole cards are stripped out until showdown so a peer can't read
    /// opponents' cards off the network traffic.
    func snapshot(for viewerID: String) -> GameState {
        var visiblePlayers = players
        if round != .showdown {
            for i in visiblePlayers.indices where visiblePlayers[i].id != viewerID {
                visiblePlayers[i].holeCards = []
            }
        }
        return GameState(players: visiblePlayers, communityCards: communityCards, round: round,
                          potTotal: potTotal, dealerIndex: dealerIndex, activePlayerIndex: activePlayerIndex,
                          currentBet: currentBet, minRaise: minRaise, smallBlind: smallBlind, bigBlind: bigBlind,
                          handNumber: handNumber, lastActionDescription: lastActionDescription)
    }
}
