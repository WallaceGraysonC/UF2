import SwiftUI
import GameKit

/// Live table played over Game Center with friends. The device with the
/// lexicographically-smallest player ID is elected host and runs the only
/// authoritative `BlackjackEngine`; everyone else renders whatever
/// `GameState` the host broadcasts and sends their actions to the host.
struct OnlineGameView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss

    let match: GKMatch
    private static let buyIn = 500
    private static let minBet = 10
    private static let maxBet = 500

    @StateObject private var multiplayer: MultiplayerMatch
    private let localID: String
    @State private var hasSettled = false
    @State private var showRulesGuide = false
    @State private var lastBetAmount: Int?

    init(match: GKMatch) {
        self.match = match
        GameCenterManager.shared.match = match

        let allIDs = ([GKLocalPlayer.local.gamePlayerID] + match.players.map { $0.gamePlayerID }).sorted()
        let localID = GKLocalPlayer.local.gamePlayerID
        self.localID = localID
        let isHost = allIDs.first == localID

        var engine: BlackjackEngine?
        if isHost {
            var host = Player(id: localID, name: GKLocalPlayer.local.displayName, chips: Self.buyIn,
                                   cardBackID: BankrollManager.shared.equippedCardBack,
                                   cardFaceID: BankrollManager.shared.equippedCardFace,
                                   avatarID: BankrollManager.shared.equippedAvatar,
                                   avatarFrameID: BankrollManager.shared.equippedAvatarFrame)
            host.seatIndex = 0
            var players = [host]
            players += match.players.enumerated().map { i, gkPlayer in
                var p = Player(id: gkPlayer.gamePlayerID, name: gkPlayer.displayName, chips: Self.buyIn)
                p.seatIndex = i + 1
                return p
            }
            engine = BlackjackEngine(players: players, minBet: Self.minBet, maxBet: Self.maxBet)
        }
        _multiplayer = StateObject(wrappedValue: MultiplayerMatch(isHost: isHost, engine: engine, localPlayerID: localID))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackdropView(id: bankroll.equippedBackdrop).ignoresSafeArea()
                if let state = multiplayer.latestState {
                    DealerAreaView(dealer: state.dealer, feltID: bankroll.equippedFelt, railID: bankroll.equippedRail, cardBackID: bankroll.equippedCardBack, cardFaceID: bankroll.equippedCardFace) { feltSize in
                        // The local player's own seat is drawn separately below,
                        // layered above the button panel -- everyone else stays at the table.
                        ForEach(Array(state.players.enumerated()), id: \.element.id) { index, player in
                            if player.id != localID {
                                let totalSeats = (state.players.map { $0.seatIndex }.max() ?? state.players.count - 1) + 1
                                let offset = SeatLayout.offsets(count: totalSeats)[player.seatIndex]
                                PlayerSeatView(
                                    player: player,
                                    isActive: state.activePlayerIndex == index,
                                    activeHandIndex: state.activeHandIndex,
                                    results: state.roundResults.filter { $0.playerID == player.id },
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
                } else {
                    ProgressView("Setting up table...").tint(.white).foregroundColor(.white)
                }

                VStack {
                    header
                    Spacer()
                    if let state = multiplayer.latestState, !state.lastActionDescription.isEmpty || currentHandBadgeText(state) != nil {
                        HStack(alignment: .top) {
                            if !state.lastActionDescription.isEmpty {
                                Text(state.lastActionDescription)
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(.ultraThinMaterial))
                                    .frame(maxWidth: 190, alignment: .leading)
                            }
                            Spacer()
                            if let text = currentHandBadgeText(state) {
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
                if let state = multiplayer.latestState,
                   let me = state.players.first(where: { $0.id == localID }),
                   let myIndex = state.players.firstIndex(where: { $0.id == localID }) {
                    PlayerSeatView(
                        player: me,
                        isActive: state.activePlayerIndex == myIndex,
                        activeHandIndex: state.activeHandIndex,
                        results: state.roundResults.filter { $0.playerID == localID }
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
            bankroll.applyDelta(-Self.buyIn)
            if multiplayer.isHost { multiplayer.requestNextRound() }
        }
        .onDisappear { settleIfNeeded() }
    }

    private func currentHandBadgeText(_ state: GameState) -> String? {
        guard state.phase == .playerTurns, state.currentPlayer?.id == localID, let hand = state.currentHand,
              !hand.cards.isEmpty else { return nil }
        return hand.displayTotal
    }

    private var header: some View {
        HStack {
            Button {
                settleIfNeeded()
                GameCenterManager.shared.disconnect()
                dismiss()
            } label: {
                Image(systemName: "chevron.left").foregroundColor(.white)
            }
            Spacer()
            Text("Friends Table").foregroundColor(.white).font(.headline)
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
        if let state = multiplayer.latestState, let me = state.players.first(where: { $0.id == localID }) {
            if state.phase == .payout, state.activePlayerIndex == nil {
                VStack(spacing: 10) {
                    let myResults = state.roundResults.filter { $0.playerID == localID }
                    ForEach(myResults) { result in
                        Text(result.summaryText)
                            .font(.footnote.bold())
                            .foregroundColor(.yellow)
                    }
                    if multiplayer.isHost {
                        Button("Next Hand") { multiplayer.requestNextRound() }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Text("Waiting for host to start the next hand...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.bottom, 20)
            } else if state.phase == .insurance, state.currentPlayer?.id == localID {
                InsuranceControlsView(insuranceCost: (me.hands.first?.bet ?? 0) / 2) { accept in
                    multiplayer.sendAction(.insurance(accept))
                }
                .padding(.bottom, 12)
            } else if state.phase == .playerTurns, state.currentPlayer?.id == localID {
                HandActionControlsView(
                    canDouble: state.canDoubleDownNow, canSplit: state.canSplitNow, canSurrender: state.canSurrenderNow,
                    onAction: { multiplayer.sendAction($0) }
                )
                .padding(.bottom, 12)
            } else if state.phase == .betting, me.hands.isEmpty, me.chips > 0 {
                BetBuilderView(chips: me.chips, minBet: state.minBet, maxBet: state.maxBet, defaultBet: lastBetAmount) { amount in
                    lastBetAmount = amount
                    multiplayer.sendAction(.placeBet(amount))
                }
                .padding(.bottom, 12)
            }
        }
    }

    private func settleIfNeeded() {
        guard !hasSettled else { return }
        hasSettled = true
        if let me = multiplayer.latestState?.players.first(where: { $0.id == localID }) {
            bankroll.applyDelta(me.chips)
        } else {
            bankroll.applyDelta(Self.buyIn)
        }
    }
}
