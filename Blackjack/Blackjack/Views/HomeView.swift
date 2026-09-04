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
    @State private var showTournament = false
    @State private var showVIP = false
    @State private var showVIPLockedAlert = false

    private static let tournamentConfig = LocalGameView.TournamentConfig(
        limitLevels: [(5, 25), (10, 50), (25, 100), (50, 200), (75, 300), (100, 500)],
        handsPerLevel: 8
    )
    private static let vipTournamentConfig = LocalGameView.TournamentConfig(
        limitLevels: [(50, 500), (100, 1000), (200, 2000), (500, 5000)],
        handsPerLevel: 10
    )

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                BJTheme.feltBackground
                    .ignoresSafeArea()

                GeometryReader { geo in
                    ScrollView {
                        VStack(spacing: 32) {
                    Spacer(minLength: 24)

                    VStack(spacing: 10) {
                        TwentyOneMark()
                            .frame(height: 82)
                            .padding(.bottom, 8)
                        Text("Pocket 21")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Text("No ads. No pop-ups. No purchases.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Label("$\(bankroll.chips)", systemImage: "dollarsign.circle.fill")
                        .font(.title2.bold())
                        .foregroundColor(BJTheme.goldBright)
                        .padding(.horizontal, 22).padding(.vertical, 9)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                        .overlay(Capsule().stroke(BJTheme.gold.opacity(0.35), lineWidth: 1))

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

                    VStack(spacing: 10) {
                        Text("OTHER GAME MODES")
                            .font(.caption2.bold())
                            .tracking(1.2)
                            .foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button { showCustomTable = true } label: {
                            MenuButtonLabel(title: "Custom Table Setup", icon: "slider.horizontal.3")
                        }
                        Button { showTournament = true } label: {
                            MenuButtonLabel(title: "Tournament", icon: "trophy.fill")
                        }
                        Button { showDailyChallenge = true } label: {
                            MenuButtonLabel(title: "Daily Challenge", icon: "calendar.badge.clock")
                        }
                        Button {
                            if bankroll.isVIPUnlocked { showVIP = true } else { showVIPLockedAlert = true }
                        } label: {
                            MenuButtonLabel(
                                title: "VIP High Stakes",
                                icon: bankroll.isVIPUnlocked ? "crown.fill" : "lock.fill",
                                dimmed: !bankroll.isVIPUnlocked
                            )
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 24)

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
            .fullScreenCover(isPresented: $showCustomTable) { CustomTableSetupView() }
            .fullScreenCover(isPresented: $showTournament) {
                LocalGameView(botCount: 5, buyIn: 500, minBet: 5, maxBet: 25,
                              enableResume: false, tableTitle: "Tournament", tournament: Self.tournamentConfig)
            }
            .fullScreenCover(isPresented: $showVIP) {
                LocalGameView(botCount: 5, buyIn: 5000, minBet: 50, maxBet: 500,
                              enableResume: false, tableTitle: "VIP High Stakes", tournament: Self.vipTournamentConfig)
            }
            .alert("VIP High Stakes Locked", isPresented: $showVIPLockedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Reach Level \(BankrollManager.vipUnlockLevel) to unlock VIP High Stakes. You're Level \(bankroll.level) — keep playing hands to earn XP.")
            }
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

private struct MenuButtonLabel: View {
    let title: String
    let icon: String
    var dimmed: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(BJTheme.goldMaterial.opacity(0.22))
                Image(systemName: icon)
                    .foregroundColor(BJTheme.goldBright)
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

/// A ten and an ace tucked into a gold pocket, reading 21 at a glance --
/// the app's logo mark. Gradient card stock and pocket leather, a
/// foreshortened tilt, and cast shadows so it reads as an actual object
/// sitting on the screen rather than a flat glyph.
private struct TwentyOneMark: View {
    var body: some View {
        ZStack {
            card(rank: "10", suit: "♦", ink: BJTheme.crimsonDeep, rotation: -15, xOffset: -15)
            card(rank: "A", suit: "♠", ink: BJTheme.ink, rotation: 15, xOffset: 15)
            pocket
        }
    }

    private var pocket: some View {
        UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 5,
                                bottomTrailingRadius: 5, topTrailingRadius: 22, style: .continuous)
            .fill(BJTheme.goldMaterial)
            .frame(width: 96, height: 44)
            .overlay(alignment: .top) {
                // Rim highlight -- a fold in the leather/foil catching light
                Capsule()
                    .fill(BJTheme.goldBright.opacity(0.65))
                    .frame(width: 60, height: 1.6)
                    .offset(y: 3)
            }
            .overlay {
                Text("21")
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundColor(BJTheme.ink)
            }
            .overlay(
                UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 5,
                                        bottomTrailingRadius: 5, topTrailingRadius: 22, style: .continuous)
                    .stroke(BJTheme.goldDeep.opacity(0.7), lineWidth: 1)
            )
            .materialShadow(radius: 8, y: 5)
            .offset(y: 16)
    }

    private func card(rank: String, suit: String, ink: Color, rotation: Double, xOffset: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(BJTheme.cardMaterial)
            .frame(width: 42, height: 60)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(rank).font(.system(size: 13, weight: .bold, design: .serif))
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
