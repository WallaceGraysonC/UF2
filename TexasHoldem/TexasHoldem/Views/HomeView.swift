import SwiftUI
import GameKit

struct HomeView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @EnvironmentObject var gameCenter: GameCenterManager

    @State private var showStore = false
    @State private var showSettings = false
    @State private var showMatchmaking = false
    @State private var activeMatch: GKMatch?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LinearGradient(colors: [.black, Color(red: 0.05, green: 0.2, blue: 0.12)],
                                startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    VStack(spacing: 6) {
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.white)
                        Text("Texas Hold'em")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("No ads. No pop-ups. No purchases.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Label("$\(bankroll.chips)", systemImage: "dollarsign.circle.fill")
                        .font(.title2.bold())
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.08)))

                    VStack(spacing: 14) {
                        NavigationLink(value: Destination.local) {
                            MenuButtonLabel(
                                title: GamePersistence.hasSavedLocalGame ? "Resume Game" : "Play vs Bots",
                                icon: GamePersistence.hasSavedLocalGame ? "arrow.clockwise" : "cpu"
                            )
                        }

                        Button {
                            if !gameCenter.isAuthenticated { gameCenter.authenticate() }
                            showMatchmaking = true
                        } label: {
                            MenuButtonLabel(title: "Play with Friends", icon: "person.2.fill")
                        }

                        Button { showStore = true } label: {
                            MenuButtonLabel(title: "Store", icon: "cart.fill")
                        }

                        Button { showSettings = true } label: {
                            MenuButtonLabel(title: "Settings", icon: "gearshape.fill")
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    if bankroll.chips <= 0 {
                        Button("Out of chips? Reset bankroll") {
                            bankroll.resetBankroll()
                        }
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 12)
                    }
                }
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .local:
                    LocalGameView()
                case .online:
                    if let activeMatch {
                        OnlineGameView(match: activeMatch)
                    }
                }
            }
            .sheet(isPresented: $showStore) { StoreView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .fullScreenCover(isPresented: $showMatchmaking) {
                MatchmakingView(
                    onMatchFound: { match in
                        activeMatch = match
                        showMatchmaking = false
                        path.append(Destination.online)
                    },
                    onCancelOrError: { showMatchmaking = false }
                )
                .ignoresSafeArea()
            }
        }
        .onAppear { gameCenter.authenticate() }
    }
}

private enum Destination: Hashable {
    case local
    case online
}

private struct MenuButtonLabel: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title).bold()
            Spacer()
            Image(systemName: "chevron.right").font(.caption)
        }
        .foregroundColor(.white)
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.1)))
    }
}
