import SwiftUI

struct EmployeesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Studio.self) private var studio
    @State private var selectedTab: AppTab = .employees

    var body: some View {
        VStack(spacing: 0) {
            hud
            content
            StudioStatBar()
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.paper)
        .onChange(of: selectedTab) { _, newValue in
            if newValue != .employees { dismiss() }
        }
    }

    private var hud: some View {
        HStack {
            Button { dismiss() } label: {
                Text("‹ BACK").font(Theme.mono(10, weight: .semibold))
            }
            Spacer()
            HUDStatView(value: "\(studio.employees.count)/\(studio.deskCapacity)", label: "DESKS", valueSize: 14)
            Spacer()
            HUDStatView(value: "$\(studio.dailyWageBill)", label: "DAILY WAGES", valueSize: 14)
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
                Text("THE TEAM")
                    .font(Theme.display(14))
                    .foregroundStyle(Theme.ink)

                ForEach(studio.employees) { employee in
                    EmployeeCard(employee: employee)
                }

                hiringSection

                if !studio.shippedGames.isEmpty {
                    shippedSection
                }
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
                Button { studio.refreshHiringBoard() } label: {
                    Text("REFRESH")
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .padding(.top, 8)

            if studio.employees.count >= studio.deskCapacity {
                Text("Desks are full — upgrade the office for more room.")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.red)
            }

            ForEach(studio.hiringBoard) { candidate in
                CandidateCard(candidate: candidate,
                             affordable: studio.canHire(candidate),
                             onHire: { studio.hire(candidate) })
            }
        }
    }

    private var shippedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SHIPPED GAMES")
                .font(Theme.display(13))
                .foregroundStyle(Theme.ink)
                .padding(.top, 8)

            ForEach(studio.shippedGames.reversed()) { game in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(game.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("\(game.genre.rawValue) · \(game.topic.rawValue)")
                            .font(Theme.mono(8))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(repeating: "★", count: game.stars))
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.amberDeep)
                        Text("$\(game.lifetimeSales)")
                            .font(Theme.mono(9, weight: .bold))
                            .foregroundStyle(Theme.green)
                    }
                }
                .padding(10)
                .background(Theme.cream)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
    }
}

private struct EmployeeCard: View {
    let employee: Employee

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(employee.name.uppercased())
                    .font(Theme.display(14))
                    .foregroundStyle(Theme.ink)
                Text("FAVOURS \(employee.favoriteGenre.rawValue.uppercased())")
                    .font(Theme.mono(7.5, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            statPair(employee: employee)
            Text("$\(employee.dailyWage)/DAY")
                .font(Theme.mono(9, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(11)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func statPair(employee: Employee) -> some View {
        HStack(spacing: 6) {
            statChip("DES", employee.design, Theme.amberDeep)
            statChip("TCH", employee.tech, Theme.steel)
            statChip("SPD", employee.speed, Theme.teal)
        }
    }

    private func statChip(_ label: String, _ value: Int, _ tint: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(Theme.mono(11, weight: .bold))
                .foregroundStyle(tint)
            Text(label)
                .font(Theme.mono(6, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
    }
}

private struct CandidateCard: View {
    let candidate: Employee
    let affordable: Bool
    let onHire: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.name.uppercased())
                    .font(Theme.display(13))
                    .foregroundStyle(Theme.ink)
                Text("DES \(candidate.design) · TCH \(candidate.tech) · SPD \(candidate.speed)")
                    .font(Theme.mono(8, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Button(action: onHire) {
                Text(affordable ? "HIRE $\(candidate.signingFee)" : "TOO DEAR")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(affordable ? Theme.amberDeep : Theme.inkSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .disabled(!affordable)
        }
        .padding(11)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    EmployeesView().environment(Studio())
}
