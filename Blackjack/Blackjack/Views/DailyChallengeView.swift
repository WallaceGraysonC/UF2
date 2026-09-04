import SwiftUI

/// Today's challenges, split into two tracks: Daily goals for the cash
/// table, and Tournament goals for the elimination format. Both reset at
/// midnight.
struct DailyChallengeView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @ObservedObject private var challengeManager = DailyChallengeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var track: ChallengeTrack = .daily

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Label("Level \(bankroll.level)", systemImage: "star.fill")
                            .foregroundColor(BJTheme.goldBright)
                        Spacer()
                        let progress = bankroll.xpProgress
                        Text("\(progress.current) / \(progress.needed) XP")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    ForEach(challengeManager.challenges(in: track)) { challenge in
                        ChallengeRow(challenge: challenge)
                    }
                } footer: {
                    Text(track.scopeNote)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Picker("Track", selection: $track) {
                        ForEach(ChallengeTrack.allCases, id: \.self) { option in
                            Text(label(for: option)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .tint(BJTheme.gold)
    }

    /// Marks a track whose rewards are sitting there waiting to be collected.
    private func label(for track: ChallengeTrack) -> String {
        let ready = challengeManager.unclaimedCount(in: track)
        return ready > 0 ? "\(track.displayName) (\(ready))" : track.displayName
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
                .tint(complete ? .green : BJTheme.gold)
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
                    .tint(BJTheme.gold)
            }
        }
        .padding(.vertical, 4)
    }
}
