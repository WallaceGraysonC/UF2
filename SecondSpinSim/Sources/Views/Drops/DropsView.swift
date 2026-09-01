import SwiftUI

/// Plan a Drop, watch one in prep, and read the write-up it earned.
/// This is the only project that scores you in public.
struct DropsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game
    @State private var selectedTab: AppTab = .drops

    @State private var chosenTheme: DropTheme = .staffPicks
    @State private var chosenCuratorIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            hud
            content
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.paper)
        .onChange(of: selectedTab) { _, newValue in
            if newValue != .drops { dismiss() }
        }
    }

    private var hud: some View {
        HStack {
            Button { dismiss() } label: {
                Text("‹ BACK").font(Theme.mono(10, weight: .semibold))
            }
            Spacer()
            HUDStatView(value: "$\(game.cash)", label: "CASH", valueSize: 14)
            Spacer()
            HUDStatView(value: game.activeDrop?.dayLabel ?? "IDLE", label: "DROP", valueSize: 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 54)
        .padding(.bottom, 12)
        .background(Theme.ink)
        .foregroundStyle(Theme.cream)
    }

    @ViewBuilder
    private var content: some View {
        if let drop = game.activeDrop {
            dropInPrep(drop)
        } else {
            planner
        }
    }

    // MARK: Plan

    private var planner: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let result = game.lastDropResult {
                    ReviewCard(result: result)
                }

                Text("PLAN A DROP")
                    .font(Theme.display(14))
                    .foregroundStyle(Theme.ink)

                VStack(spacing: 7) {
                    ForEach(DropTheme.allCases) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: chosenTheme == theme,
                            affordable: game.canAfford(theme),
                            onTap: { chosenTheme = theme }
                        )
                    }
                }

                Text("ASSIGN CURATORS")
                    .font(Theme.display(13))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 4)

                if game.curators.isEmpty {
                    Text("No Curators on the roster — hire one before running a Drop.")
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.red)
                } else {
                    VStack(spacing: 6) {
                        ForEach(game.curators) { curator in
                            CuratorToggleRow(
                                curator: curator,
                                isSelected: chosenCuratorIDs.contains(curator.id),
                                onTap: { toggle(curator.id) }
                            )
                        }
                    }
                }

                Button {
                    game.startDrop(theme: chosenTheme, curatorIDs: Array(chosenCuratorIDs))
                    chosenCuratorIDs = []
                } label: {
                    Text(startLabel)
                }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
                .disabled(!canStart)
                .opacity(canStart ? 1 : 0.4)
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
    }

    private var canStart: Bool {
        !chosenCuratorIDs.isEmpty && game.canAfford(chosenTheme)
    }

    private var startLabel: String {
        if chosenCuratorIDs.isEmpty { return "ASSIGN A CURATOR" }
        if !game.canAfford(chosenTheme) { return "NOT ENOUGH CASH" }
        return "START PREP — $\(chosenTheme.cost)"
    }

    private func toggle(_ id: UUID) {
        if chosenCuratorIDs.contains(id) {
            chosenCuratorIDs.remove(id)
        } else {
            chosenCuratorIDs.insert(id)
        }
    }

    // MARK: In prep

    private func dropInPrep(_ drop: CuratedDrop) -> some View {
        VStack(spacing: 14) {
            Text(drop.theme.rawValue.uppercased())
                .font(Theme.display(15))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(drop.theme.blurb)
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Text(drop.dayLabel)
                    .font(Theme.display(19))
                    .foregroundStyle(Theme.amberDeep)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0xD7D0BE))
                        Capsule().fill(Theme.amberDeep)
                            .frame(width: geo.size.width * drop.progress)
                    }
                }
                .frame(height: 9)

                pointsRow("DESIGN", drop.designPoints, target: drop.theme.expectation, color: Theme.amberDeep)
                pointsRow("HYPE", drop.hypePoints, target: drop.theme.expectation, color: Theme.teal)

                Text("Design decides the write-up. Hype decides how many people see it.")
                    .font(Theme.mono(8))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
            .padding(16)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
    }

    private func pointsRow(_ label: String, _ value: Double, target: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(Theme.mono(8, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 48, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0xD7D0BE))
                    Capsule().fill(color)
                        .frame(width: geo.size.width * min(1.0, value / max(1, target)))
                }
            }
            .frame(height: 6)

            Text("\(Int(value))")
                .font(Theme.mono(9, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 28, alignment: .trailing)
        }
    }
}

// MARK: - Components

private struct ReviewCard: View {
    let result: DropResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("THE LOCAL ZINE")
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(Theme.red)
                Spacer()
                Text(String(repeating: "★", count: result.stars)
                     + String(repeating: "☆", count: 5 - result.stars))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.amberDeep)
            }

            Text(result.review)
                .font(.system(size: 12.5))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Text("TURNOUT \(result.turnout)")
                    .font(Theme.mono(8, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Text("TOOK $\(result.revenue)")
                    .font(Theme.mono(8, weight: .semibold))
                    .foregroundStyle(Theme.green)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.red, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct ThemeCard: View {
    let theme: DropTheme
    let isSelected: Bool
    let affordable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(theme.rawValue.uppercased())
                        .font(Theme.display(12))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Text("$\(theme.cost)")
                        .font(Theme.mono(10, weight: .bold))
                        .foregroundStyle(affordable ? Theme.green : Theme.red)
                }

                Text(theme.blurb)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    tag("\(theme.prepDays)D PREP")
                    tag(theme.format.abbreviation)
                    tag("DRAWS \(theme.draws.count)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .background(Theme.cream)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Theme.amberDeep : Theme.line,
                            lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(Theme.mono(7.5, weight: .semibold))
            .foregroundStyle(Theme.inkSoft)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.line, lineWidth: 1))
    }
}

private struct CuratorToggleRow: View {
    let curator: StaffMember
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(isSelected ? Theme.amberDeep : Color(hex: 0xD7D0BE))
                    .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(curator.name.uppercased())
                        .font(Theme.mono(10, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("DESIGN \(curator.design) · HYPE \(curator.hype) · FATIGUE \(curator.fatigue)")
                        .font(Theme.mono(8))
                        .foregroundStyle(curator.fatigue >= 60 ? Theme.red : Theme.inkSoft)
                }

                Spacer()

                Text(curator.specialization.abbreviation)
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(curator.specialization.binColor)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .padding(10)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DropsView()
        .environment(GameState())
}
