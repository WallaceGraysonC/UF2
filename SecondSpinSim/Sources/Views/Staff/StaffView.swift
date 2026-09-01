import SwiftUI

struct StaffView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game
    @State private var selectedTab: AppTab = .staff

    var body: some View {
        VStack(spacing: 0) {
            hud
            content
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.paper)
        .onChange(of: selectedTab) { _, newValue in
            if newValue != .staff { dismiss() }
        }
    }

    private var hud: some View {
        HStack {
            Button { dismiss() } label: {
                Text("‹ BACK").font(Theme.mono(10, weight: .semibold))
            }
            Spacer()
            HUDStatView(value: "\(game.staff.count)", label: "ROSTER", valueSize: 14)
            Spacer()
            HUDStatView(value: "$\(game.dailyWageBill)", label: "DAILY WAGES", valueSize: 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 54)
        .padding(.bottom, 12)
        .background(Theme.ink)
        .foregroundStyle(Theme.cream)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("STAFF")
                    .font(Theme.display(14))
                    .foregroundStyle(Theme.ink)

                ForEach(game.staff) { member in
                    StaffCard(
                        member: member,
                        canTrain: game.canTrain(member),
                        onTrain: { stat in game.sendToConvention(member, for: stat) }
                    )
                }

                hiringSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
    }

    private var hiringSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HIRING BOARD")
                    .font(Theme.display(13))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button { game.refreshHiringBoard() } label: {
                    Text("REFRESH")
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .padding(.top, 8)

            if game.hiringBoard.isEmpty {
                Text("Nobody's looking right now. Refresh, or level up the shop to draw better people.")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(game.hiringBoard) { candidate in
                    CandidateCard(
                        candidate: candidate,
                        affordable: game.canHire(candidate),
                        onHire: { game.hire(candidate) }
                    )
                }
            }
        }
    }
}

private struct CandidateCard: View {
    let candidate: StaffMember
    let affordable: Bool
    let onHire: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(candidate.name.uppercased())
                        .font(Theme.display(14))
                        .foregroundStyle(Theme.ink)
                    Text("\(candidate.role.rawValue.uppercased()) · \(candidate.primaryStat.label) \(candidate.primaryStat.value)")
                        .font(Theme.mono(8, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Text(candidate.specialization.abbreviation)
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(candidate.specialization.binColor)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            HStack {
                Text("SIGNING $\(candidate.signingFee) · $\(candidate.dailyWage)/DAY")
                    .font(Theme.mono(8, weight: .semibold))
                    .foregroundStyle(affordable ? Theme.inkSoft : Theme.red)
                Spacer()
                Button(action: onHire) {
                    Text(affordable ? "HIRE" : "TOO DEAR")
                        .font(Theme.mono(9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(affordable ? Theme.amberDeep : Theme.inkSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .disabled(!affordable)
            }
        }
        .padding(11)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct StaffCard: View {
    let member: StaffMember
    let canTrain: Bool
    let onTrain: (TrainableStat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(member.name.uppercased())
                        .font(Theme.display(15))
                        .foregroundStyle(Theme.ink)
                    Text("\(member.role.rawValue.uppercased()) · \(member.role.duty)")
                        .font(Theme.mono(8, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                specializationChip
            }

            statRow("VOLUME", member.volume)
            statRow("RARITY", member.raritySense)
            statRow("NEGOTIATION", member.negotiation)
            statRow("RESTORATION", member.restoration)
            statRow("DESIGN", member.design)
            statRow("HYPE", member.hype)

            HStack {
                fatigueBadge
                Spacer()
                Text("$\(member.dailyWage)/DAY")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.top, 2)

            trainingControl
        }
        .padding(12)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    /// Conventions take the staffer off the floor for three days, so this
    /// shows a countdown rather than a button while one is running.
    @ViewBuilder
    private var trainingControl: some View {
        if member.isTraining {
            HStack {
                Text("AT A CONVENTION")
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(Theme.amberDeep)
                Spacer()
                Text("\(member.trainingDaysRemaining)D LEFT")
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.amberDeep, lineWidth: 1))
        } else {
            Menu {
                ForEach(TrainableStat.allCases) { stat in
                    Button("\(stat.rawValue) — now \(member.value(of: stat))") {
                        onTrain(stat)
                    }
                }
            } label: {
                Text(canTrain ? "SEND TO A CONVENTION — $\(GameState.trainingCost)" : "CAN'T AFFORD TRAINING")
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(canTrain ? Theme.teal : Theme.inkSoft)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 4)
                        .stroke(canTrain ? Theme.teal : Theme.line, lineWidth: 1))
            }
            .disabled(!canTrain)
        }
    }

    private var specializationChip: some View {
        Text(member.specialization.abbreviation)
            .font(Theme.mono(8, weight: .bold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(member.specialization.binColor)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var fatigueBadge: some View {
        let spent = member.fatigue >= 60
        return Text("FATIGUE \(member.fatigue)")
            .font(Theme.mono(8, weight: .bold))
            .foregroundStyle(spent ? Theme.red : Theme.inkSoft)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(spent ? Theme.red : Theme.line, lineWidth: 1)
            )
    }

    private func statRow(_ label: String, _ value: Int) -> some View {
        let isPrimary = member.primaryStat.label == label
            || (label == "RARITY" && member.primaryStat.label == "RARITY SENSE")
        return HStack(spacing: 8) {
            Text(label)
                .font(Theme.mono(8, weight: isPrimary ? .bold : .regular))
                .foregroundStyle(isPrimary ? Theme.ink : Theme.inkSoft)
                .frame(width: 78, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0xD7D0BE))
                    Capsule()
                        .fill(isPrimary ? Theme.amberDeep : Theme.teal)
                        .frame(width: geo.size.width * (Double(value) / 99.0))
                }
            }
            .frame(height: 5)

            Text("\(value)")
                .font(Theme.mono(9, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 20, alignment: .trailing)
        }
    }
}

#Preview {
    StaffView()
        .environment(GameState())
}
