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

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 10) {
                        PocketAcesMark()
                            .frame(height: 64)
                            .padding(.bottom, 4)
                        Text("Pocket Aces")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Text("No ads. No pop-ups. No purchases.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Label("$\(bankroll.chips)", systemImage: "dollarsign.circle.fill")
                        .font(.title2.bold())
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 22).padding(.vertical, 9)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                        .overlay(Capsule().stroke(Color.yellow.opacity(0.25), lineWidth: 1))

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
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.yellow.opacity(0.15))
                Image(systemName: icon)
                    .foregroundColor(.yellow)
            }
            .frame(width: 34, height: 34)

            Text(title).font(.body.bold())
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.4))
        }
        .foregroundColor(.white)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
    }
}

/// Two overlapping ace cards -- the app's logo mark on the home screen.
private struct PocketAcesMark: View {
    var body: some View {
        ZStack {
            aceCard(suit: "♠", rotation: -10, xOffset: -16)
            aceCard(suit: "♥", rotation: 10, xOffset: 16)
        }
    }

    private func aceCard(suit: String, rotation: Double, xOffset: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white)
            .frame(width: 46, height: 64)
            .overlay(
                RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.15), lineWidth: 1)
            )
            .overlay(
                VStack(spacing: 2) {
                    Text("A").font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(suit).font(.system(size: 18))
                }
                .foregroundColor(suit == "♥" ? .red : .black)
            )
            .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 3)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset)
    }
}
