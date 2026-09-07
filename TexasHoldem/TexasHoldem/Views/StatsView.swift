import SwiftUI

/// Lifetime stats per game mode (or all of them combined), plus a recent
/// hand history feed. Purely a read-only personal record -- resetting it
/// here has no effect on chips, XP, or achievements already earned.
struct StatsView: View {
    @ObservedObject private var statsManager = StatsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: GameModeID?
    @State private var showResetConfirm = false

    private var stats: ModeStats {
        selectedMode.map { statsManager.stats(for: $0) } ?? statsManager.allModesCombined
    }

    private var filteredHistory: [HandHistoryEntry] {
        Array(statsManager.history(for: selectedMode).prefix(25))
    }

    private var showsTournamentSection: Bool {
        selectedMode == nil || (selectedMode?.isTournament ?? false)
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker("Game Mode", selection: $selectedMode) {
                        Text("All Modes").tag(GameModeID?.none)
                        ForEach(GameModeID.allCases) { mode in
                            Text(mode.displayName).tag(GameModeID?.some(mode))
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Hands") {
                    StatRow(label: "Hands Played", value: "\(stats.handsPlayed)")
                    StatRow(label: "Hands Won", value: "\(stats.handsWon)")
                    StatRow(label: "Win Rate", value: winRateText)
                    StatRow(label: "Biggest Pot Won", value: "$\(stats.biggestPotWon)")
                    StatRow(label: "Total Won", value: "$\(stats.totalWon)")
                }

                if showsTournamentSection {
                    Section {
                        StatRow(label: "Tournaments Played", value: "\(stats.tournamentsPlayed)")
                        StatRow(label: "Tournaments Won", value: "\(stats.tournamentsWon)")
                        if let best = stats.bestFinish {
                            StatRow(label: "Best Finish", value: "#\(best)")
                        }
                    } header: {
                        Text("Tournaments")
                    } footer: {
                        Text("\"Total Won\" above is how much you've brought in at showdown or by fold -- not a net profit/loss figure, which would also need tracking every hand you didn't win.")
                    }
                }

                Section("Recent Hands") {
                    if filteredHistory.isEmpty {
                        Text("No hands recorded yet.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredHistory) { entry in
                            HandHistoryRow(entry: entry, showsMode: selectedMode == nil)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Text(resetButtonLabel).frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Reset Stats?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { statsManager.reset(mode: selectedMode) }
            } message: {
                Text(resetAlertMessage)
            }
        }
        .tint(PATheme.gold)
    }

    private var winRateText: String {
        guard stats.handsPlayed > 0 else { return "—" }
        return String(format: "%.0f%%", Double(stats.handsWon) / Double(stats.handsPlayed) * 100)
    }

    private var resetButtonLabel: String {
        selectedMode.map { "Reset \($0.displayName) Stats" } ?? "Reset All Stats"
    }

    private var resetAlertMessage: String {
        if let selectedMode {
            return "This clears all recorded stats and hand history for \(selectedMode.displayName). This can't be undone, and won't touch your chips, XP, or achievements."
        }
        return "This clears ALL recorded stats and hand history, for every game mode. This can't be undone, and won't touch your chips, XP, or achievements."
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).bold().foregroundColor(PATheme.goldBright)
        }
    }
}

private struct HandHistoryRow: View {
    let entry: HandHistoryEntry
    var showsMode: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.summary).font(.subheadline)
                if showsMode {
                    Text(entry.mode.displayName).font(.caption2).foregroundColor(.secondary)
                }
            }
            Spacer()
            if entry.amountWon > 0 {
                Text("+$\(entry.amountWon)").font(.footnote.bold()).foregroundColor(.green)
            }
        }
        .padding(.vertical, 2)
    }
}
