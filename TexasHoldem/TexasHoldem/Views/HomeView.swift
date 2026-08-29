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
                PATheme.feltBackground
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 10) {
                        PocketAcesMark()
                            .frame(height: 82)
                            .padding(.bottom, 8)
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
                        .foregroundColor(PATheme.goldBright)
                        .padding(.horizontal, 22).padding(.vertical, 9)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                        .overlay(Capsule().stroke(PATheme.gold.opacity(0.35), lineWidth: 1))

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

                    if bankroll.canTopUpBankroll {
                        Button("Low on chips? Get $\(BankrollManager.bankrollTopUpAmount)") {
                            bankroll.topUpBankroll()
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
                Circle().fill(PATheme.goldMaterial.opacity(0.22))
                Image(systemName: icon)
                    .foregroundColor(PATheme.goldBright)
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.04)],
                                   startPoint: .top, endPoint: .bottom)
                )
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .materialShadow(radius: 6, y: 3)
    }
}

/// Two aces tucked into a gold pocket -- the app's logo mark. Gradient card
/// stock and pocket leather, a foreshortened tilt, and cast shadows so it
/// reads as an actual object sitting on the screen rather than a flat glyph.
private struct PocketAcesMark: View {
    var body: some View {
        ZStack {
            aceCard(suit: "♠", ink: PATheme.ink, rotation: -15, xOffset: -15)
            aceCard(suit: "♥", ink: PATheme.crimsonDeep, rotation: 15, xOffset: 15)
            pocket
        }
    }

    private var pocket: some View {
        UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 5,
                                bottomTrailingRadius: 5, topTrailingRadius: 22, style: .continuous)
            .fill(PATheme.goldMaterial)
            .frame(width: 96, height: 44)
            .overlay(alignment: .top) {
                // Rim highlight -- a fold in the leather/foil catching light
                Capsule()
                    .fill(PATheme.goldBright.opacity(0.65))
                    .frame(width: 60, height: 1.6)
                    .offset(y: 3)
            }
            .overlay(
                UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 5,
                                        bottomTrailingRadius: 5, topTrailingRadius: 22, style: .continuous)
                    .stroke(PATheme.goldDeep.opacity(0.7), lineWidth: 1)
            )
            .materialShadow(radius: 8, y: 5)
            .offset(y: 16)
    }

    private func aceCard(suit: String, ink: Color, rotation: Double, xOffset: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(PATheme.cardMaterial)
            .frame(width: 42, height: 60)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("A").font(.system(size: 14, weight: .bold, design: .serif))
                    Text(suit).font(.system(size: 14))
                }
                .foregroundColor(ink)
                .padding(.leading, 6).padding(.top, 5)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.32))
                    .frame(width: 30, height: 5)
                    .offset(y: 5)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
            )
            .materialShadow(radius: 5, y: 3)
            .scaleEffect(x: 1, y: 0.95)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: -7)
    }
}
