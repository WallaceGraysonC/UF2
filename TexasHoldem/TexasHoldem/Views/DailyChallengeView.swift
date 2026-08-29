import SwiftUI

/// Shows today's three challenges and lets the player claim rewards for
/// completed ones. Challenges reset at midnight local time.
struct DailyChallengeView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @ObservedObject private var challengeManager = DailyChallengeManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Label("Level \(bankroll.level)", systemImage: "star.fill")
                            .foregroundColor(PATheme.goldBright)
                        Spacer()
                        let progress = bankroll.xpProgress
                        Text("\(progress.current) / \(progress.needed) XP")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                Section("Today's Challenges") {
                    ForEach(challengeManager.challenges) { challenge in
                        ChallengeRow(challenge: challenge)
                    }
                }
            }
            .navigationTitle("Daily Challenges")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .tint(PATheme.gold)
    }
}

private struct ChallengeRow: View {
    @ObservedObject private var challengeManager = DailyChallengeManager.shared
    let challenge: DailyChallenge

    private var progressValue: Int { challengeManager.progressValue(for: challenge) }
    private var complete: Bool { challengeManager.isComplete(challenge) }
    private var claimed: Bool { challengeManager.isClaimed(challenge) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(challenge.title).font(.subheadline.bold())
            Text(challenge.detail).font(.caption).foregroundColor(.secondary)
            ProgressView(value: Double(progressValue), total: Double(challenge.target))
                .tint(complete ? .green : PATheme.gold)
            HStack {
                Label("\(challenge.xpReward) XP", systemImage: "star.fill")
                Label("$\(challenge.chipReward)", systemImage: "dollarsign.circle")
            }
            .font(.caption2)
            .foregroundColor(.secondary)

            if claimed {
                Text("Claimed").font(.caption.bold()).foregroundColor(.green)
            } else if complete {
                Button("Claim Reward") { challengeManager.claim(challenge) }
                    .buttonStyle(.borderedProminent)
                    .tint(PATheme.gold)
            }
        }
        .padding(.vertical, 4)
    }
}
