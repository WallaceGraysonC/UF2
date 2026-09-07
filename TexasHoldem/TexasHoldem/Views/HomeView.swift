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

    @State private var showCustomTable = false
    @State private var showDailyChallenge = false
    @State private var showGameModes = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                PATheme.feltBackground
                    .ignoresSafeArea()

                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 14) {
                    Spacer(minLength: 8)

                    VStack(spacing: 4) {
                        PocketAcesMark()
                            .frame(height: 50)
                            .padding(.bottom, 10)
                        Text("Pocket Aces")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Text("No ads. No pop-ups. No purchases.")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Label("$\(bankroll.chips)", systemImage: "dollarsign.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(PATheme.goldBright)
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                        .overlay(Capsule().stroke(PATheme.gold.opacity(0.35), lineWidth: 1))

                    NavigationLink(value: Destination.local) {
                        CompactMenuButtonLabel(
                            title: GamePersistence.hasSavedLocalGame ? "Resume Game" : "Play vs Bots",
                            icon: GamePersistence.hasSavedLocalGame ? "arrow.clockwise" : "cpu"
                        )
                    }
                    .padding(.horizontal, 28)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        Button { showCustomTable = true } label: {
                            GridMenuTile(title: "Custom Table", icon: "slider.horizontal.3")
                        }
                        Button {
                            if !gameCenter.isAuthenticated { gameCenter.authenticate() }
                            showMatchmaking = true
                        } label: {
                            GridMenuTile(title: "Play with Friends", icon: "person.2.fill")
                        }
                        Button { showStore = true } label: {
                            GridMenuTile(title: "Store", icon: "cart.fill")
                        }
                        Button { showDailyChallenge = true } label: {
                            GridMenuTile(title: "Daily Challenge", icon: "calendar.badge.clock")
                        }
                        Button { showSettings = true } label: {
                            GridMenuTile(title: "Settings", icon: "gearshape.fill")
                        }
                        Button { showGameModes = true } label: {
                            GridMenuTile(title: "Game Modes", icon: "square.grid.2x2.fill")
                        }
                    }
                    .padding(.horizontal, 28)

                    Spacer(minLength: 8)

                    if bankroll.canTopUpBankroll {
                        Button("Low on chips? Top up to $\(BankrollManager.bankrollTopUpFloor)") {
                            bankroll.topUpBankroll()
                        }
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 12)
                    }
                        }
                        .frame(minHeight: geo.size.height)
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
            .sheet(isPresented: $showDailyChallenge) { DailyChallengeView() }
            .sheet(isPresented: $showGameModes) { GameModesView() }
            .fullScreenCover(isPresented: $showCustomTable) { CustomTableSetupView() }
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
        // Game Center auth can pop a system sign-in sheet and involves a
        // network round trip -- deferred off the launch path and only
        // triggered when the player actually taps "Play with Friends".
    }
}

private enum Destination: Hashable {
    case local
    case online
}

struct MenuButtonLabel: View {
    let title: String
    let icon: String
    var dimmed: Bool = false

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
        .opacity(dimmed ? 0.55 : 1)
    }
}

/// A slimmer full-width row -- smaller icon badge, tighter padding -- used
/// for the single primary action (Resume Game / Play vs Bots) above the
/// mode grid.
struct CompactMenuButtonLabel: View {
    let title: String
    let icon: String
    var dimmed: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(PATheme.goldMaterial.opacity(0.22))
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundColor(PATheme.goldBright)
            }
            .frame(width: 26, height: 26)

            Text(title).font(.subheadline.bold())
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(
                    LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.04)],
                                   startPoint: .top, endPoint: .bottom)
                )
        )
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .materialShadow(radius: 4, y: 2)
        .opacity(dimmed ? 0.55 : 1)
    }
}

/// A 2-column grid tile -- icon over a short label -- used for the
/// secondary game modes so they fit on screen without scrolling.
struct GridMenuTile: View {
    let title: String
    let icon: String
    var dimmed: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(PATheme.goldMaterial.opacity(0.22))
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(PATheme.goldBright)
            }
            .frame(width: 40, height: 40)

            Text(title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.04)],
                                   startPoint: .top, endPoint: .bottom)
                )
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .materialShadow(radius: 4, y: 2)
        .opacity(dimmed ? 0.55 : 1)
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
