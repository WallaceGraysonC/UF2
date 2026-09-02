import SwiftUI
import GameKit

/// Live table played over Game Center with friends. The device with the
/// lexicographically-smallest player ID is elected host and runs the only
/// authoritative `PokerEngine`; everyone else renders whatever `GameState`
/// the host broadcasts and sends their actions to the host.
struct OnlineGameView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss

    let match: GKMatch
    private static let buyIn = 500

    @StateObject private var multiplayer: MultiplayerMatch
    private let localID: String
    @State private var hasSettled = false
    @State private var showHandGuide = false

    init(match: GKMatch) {
        self.match = match
        GameCenterManager.shared.match = match

        let allIDs = ([GKLocalPlayer.local.gamePlayerID] + match.players.map { $0.gamePlayerID }).sorted()
        let localID = GKLocalPlayer.local.gamePlayerID
        self.localID = localID
        let isHost = allIDs.first == localID

        var engine: PokerEngine?
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
            engine = PokerEngine(players: players)
        }
        _multiplayer = StateObject(wrappedValue: MultiplayerMatch(isHost: isHost, engine: engine, localPlayerID: localID))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                BackdropView(id: bankroll.equippedBackdrop).ignoresSafeArea()
                if let state = multiplayer.latestState {
                    TableFeltView(communityCards: state.communityCards, pot: state.potTotal, feltID: bankroll.equippedFelt, railID: bankroll.equippedRail, cardBackID: bankroll.equippedCardBack, cardFaceID: bankroll.equippedCardFace) { feltSize in
                        // The local player's own seat is drawn separately below,
                        // layered above the button panel -- everyone else stays in the oval.
                        ForEach(Array(state.players.enumerated()), id: \.element.id) { index, player in
                            if player.id != localID {
                                let totalSeats = (state.players.map { $0.seatIndex }.max() ?? state.players.count - 1) + 1
                                let offset = SeatLayout.offsets(count: totalSeats)[player.seatIndex]
                                PlayerSeatView(
                                    player: player,
                                    isActive: state.activePlayerIndex == index,
                                    isDealer: state.dealerIndex == index,
                                    revealCards: state.round == .showdown,
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
                    if let state = multiplayer.latestState,
                       !state.lastActionDescription.isEmpty || state.handDescription(for: localID) != nil {
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
                            if let handText = state.handDescription(for: localID) {
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
                if let state = multiplayer.latestState,
                   let me = state.players.first(where: { $0.id == localID }),
                   let myIndex = state.players.firstIndex(where: { $0.id == localID }) {
                    PlayerSeatView(
                        player: me,
                        isActive: state.activePlayerIndex == myIndex,
                        isDealer: state.dealerIndex == myIndex,
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
            bankroll.applyDelta(-Self.buyIn)
            if multiplayer.isHost { multiplayer.requestNewHand() }
        }
        .onDisappear { settleIfNeeded() }
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
        if let state = multiplayer.latestState {
            if state.round == .showdown, state.activePlayerIndex == nil {
                VStack(spacing: 10) {
                    if multiplayer.isHost {
                        Button("Next Hand") { multiplayer.requestNewHand() }
                            .buttonStyle(.borderedProminent)
                    } else {
                        Text("Waiting for host to start the next hand...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.bottom, 20)
            } else if let me = state.players.first(where: { $0.id == localID }),
                      state.activePlayerIndex == state.players.firstIndex(where: { $0.id == localID }) {
                BettingControlsView(
                    player: me,
                    currentBet: state.currentBet,
                    minRaise: state.minRaise,
                    bigBlind: state.bigBlind,
                    onAction: { multiplayer.sendAction($0) }
                )
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
