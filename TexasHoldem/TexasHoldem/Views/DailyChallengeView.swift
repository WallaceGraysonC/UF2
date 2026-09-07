import SwiftUI

/// Today's challenges, split into two tracks: Daily goals for the cash
/// table, and tournament goals for Sit & Go. Both reset at midnight.
struct DailyChallengeView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @ObservedObject private var challengeManager = DailyChallengeManager.shared
    @ObservedObject private var achievementManager = AchievementManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var section: SectionMode = .daily

    /// The 3-way tab shown at the top of this screen. `.daily`/`.sitAndGo`
    /// map onto `ChallengeTrack` (which rotates and resets at midnight);
    /// `.achievements` is a separate, permanent list that never resets.
    private enum SectionMode: Hashable {
        case daily, sitAndGo, achievements
    }

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

                if section == .achievements {
                    Section {
                        ForEach(AchievementCatalog.all) { achievement in
                            AchievementRow(achievement: achievement, unlocked: achievementManager.isUnlocked(achievement))
                        }
                    } footer: {
                        Text("Permanent milestones -- unlike the challenges above, these never reset.")
                    }
                } else {
                    let track: ChallengeTrack = section == .daily ? .daily : .sitAndGo
                    Section {
                        ForEach(challengeManager.challenges(in: track)) { challenge in
                            ChallengeRow(challenge: challenge)
                        }
                    } footer: {
                        Text(track.scopeNote)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Picker("Section", selection: $section) {
                        Text(label(for: .daily)).tag(SectionMode.daily)
                        Text(label(for: .sitAndGo)).tag(SectionMode.sitAndGo)
                        Text("Achievements").tag(SectionMode.achievements)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .tint(PATheme.gold)
    }

    /// Marks a track whose rewards are sitting there waiting to be collected.
    private func label(for section: SectionMode) -> String {
        let track: ChallengeTrack = section == .daily ? .daily : .sitAndGo
        let ready = challengeManager.unclaimedCount(in: track)
        return ready > 0 ? "\(track.displayName) (\(ready))" : track.displayName
    }
}

private struct AchievementRow: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(unlocked ? AnyShapeStyle(PATheme.goldMaterial) : AnyShapeStyle(Color.white.opacity(0.08)))
                Image(systemName: achievement.icon)
                    .foregroundColor(unlocked ? PATheme.ink : .secondary)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title).font(.subheadline.bold())
                Text(achievement.detail).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if unlocked {
                Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
        .opacity(unlocked ? 1 : 0.6)
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
