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
    private static let buyIn = 2000

    @StateObject private var multiplayer: MultiplayerMatch
    private let localID: String
    @State private var hasSettled = false

    init(match: GKMatch) {
        self.match = match
        GameCenterManager.shared.match = match

        let allIDs = ([GKLocalPlayer.local.gamePlayerID] + match.players.map { $0.gamePlayerID }).sorted()
        let localID = GKLocalPlayer.local.gamePlayerID
        self.localID = localID
        let isHost = allIDs.first == localID

        var engine: PokerEngine?
        if isHost {
            var players = [Player(id: localID, name: GKLocalPlayer.local.displayName, chips: Self.buyIn)]
            players += match.players.map { Player(id: $0.gamePlayerID, name: $0.displayName, chips: Self.buyIn) }
            engine = PokerEngine(players: players)
        }
        _multiplayer = StateObject(wrappedValue: MultiplayerMatch(isHost: isHost, engine: engine, localPlayerID: localID))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                if let state = multiplayer.latestState {
                    TableFeltView(communityCards: state.communityCards, pot: state.potTotal, feltID: bankroll.equippedFelt) {
                        ForEach(Array(state.players.enumerated()), id: \.element.id) { index, player in
                            let offset = SeatLayout.offsets(count: state.players.count)[index]
                            PlayerSeatView(
                                player: player,
                                isActive: state.activePlayerIndex == index,
                                isDealer: state.dealerIndex == index,
                                revealCards: player.id == localID || state.round == .showdown
                            )
                            .position(
                                x: geo.size.width / 2 + offset.x * geo.size.width * 0.38,
                                y: geo.size.height * 0.42 + offset.y * geo.size.height * 0.34
                            )
                        }
                    }
                    .frame(width: geo.size.width * 0.92, height: geo.size.height * 0.62)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.4)
                } else {
                    ProgressView("Setting up table...").tint(.white).foregroundColor(.white)
                }

                VStack {
                    header
                    Spacer()
                    if let state = multiplayer.latestState, !state.lastActionDescription.isEmpty {
                        Text(state.lastActionDescription)
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
            Color.clear.frame(width: 20)
        }
        .padding()
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
