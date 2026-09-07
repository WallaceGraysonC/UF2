import SwiftUI

/// The specialty table formats beyond the default Play vs Bots table,
/// grouped into their own screen (a "folder" off the home screen) instead
/// of crowding the main menu list.
struct GameModesView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss

    @State private var difficulty: BotDifficulty = .normal
    @State private var showSitGo = false
    @State private var showTurboSitGo = false
    @State private var showVIP = false
    @State private var showVIPLockedAlert = false

    private static let sitGoTournament = LocalGameView.TournamentConfig(
        blindLevels: [(10, 20), (15, 30), (25, 50), (50, 100), (75, 150), (100, 200)],
        handsPerLevel: 8
    )
    /// Same blind ladder as Sit & Go but escalating twice as fast and
    /// jumping harder each level -- a full session in a fraction of the
    /// hands, the classic "turbo" trade-off.
    private static let turboSitGoTournament = LocalGameView.TournamentConfig(
        blindLevels: [(10, 20), (25, 50), (50, 100), (100, 200), (200, 400), (400, 800)],
        handsPerLevel: 4
    )
    private static let vipTournament = LocalGameView.TournamentConfig(
        blindLevels: [(100, 200), (150, 300), (250, 500), (500, 1000)],
        handsPerLevel: 10
    )

    var body: some View {
        NavigationStack {
            ZStack {
                PATheme.feltBackground.ignoresSafeArea()

                VStack(spacing: 14) {
                    Picker("Bot Difficulty", selection: $difficulty) {
                        ForEach(BotDifficulty.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 6)

                    Button { showSitGo = true } label: {
                        MenuButtonLabel(title: "Sit & Go", icon: "trophy.fill")
                    }

                    Button { showTurboSitGo = true } label: {
                        MenuButtonLabel(title: "Turbo Sit & Go", icon: "bolt.fill")
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

                    Spacer()
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
            }
            .navigationTitle("Game Modes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .fullScreenCover(isPresented: $showSitGo) {
            LocalGameView(botCount: 5, buyIn: 500, smallBlind: 10, bigBlind: 20,
                          enableResume: false, tableTitle: "Sit & Go", tournament: Self.sitGoTournament,
                          mode: .sitAndGo, difficulty: difficulty)
        }
        .fullScreenCover(isPresented: $showTurboSitGo) {
            LocalGameView(botCount: 5, buyIn: 500, smallBlind: 10, bigBlind: 20,
                          enableResume: false, tableTitle: "Turbo Sit & Go", tournament: Self.turboSitGoTournament,
                          mode: .turboSitAndGo, difficulty: difficulty)
        }
        .fullScreenCover(isPresented: $showVIP) {
            LocalGameView(botCount: 5, buyIn: 5000, smallBlind: 100, bigBlind: 200,
                          enableResume: false, tableTitle: "VIP High Stakes", tournament: Self.vipTournament,
                          mode: .vipHighStakes, difficulty: difficulty)
        }
        .alert("VIP High Stakes Locked", isPresented: $showVIPLockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Reach Level \(BankrollManager.vipUnlockLevel) to unlock VIP High Stakes. You're Level \(bankroll.level) — keep playing hands to earn XP.")
        }
    }
}
