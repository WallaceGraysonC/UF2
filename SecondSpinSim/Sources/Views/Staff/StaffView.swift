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
        VStack(alignment: .leading, spacing: 10) {
            Text("STAFF")
                .font(Theme.display(14))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(game.staff) { member in
                        StaffCard(member: member)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .padding(.top, 14)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct StaffCard: View {
    let member: StaffMember

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
        }
        .padding(12)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
