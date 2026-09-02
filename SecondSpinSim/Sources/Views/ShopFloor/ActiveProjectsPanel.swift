import SwiftUI

/// The centrepiece: whatever is in production right now, with its accumulated
/// point totals on show. This is the thing the room is working toward, so it
/// sits above the desks rather than being buried on a tab.
struct ActiveProjectsPanel: View {
    @Environment(GameState.self) private var game

    var body: some View {
        VStack(spacing: 6) {
            if let drop = game.activeDrop {
                projectCard(
                    title: drop.name.uppercased(),
                    subtitle: "\(drop.theme.rawValue) × \(drop.angle.rawValue)",
                    progress: drop.progress,
                    dayLabel: drop.dayLabel,
                    tint: Theme.plum,
                    points: [
                        ("DESIGN", drop.designPoints, drop.theme.expectation),
                        ("HYPE", drop.hypePoints, drop.theme.expectation)
                    ],
                    badge: drop.affinity.label,
                    badgeTint: drop.affinity.color
                )
            }

            if let run = game.activeRun {
                projectCard(
                    title: run.location.rawValue.uppercased(),
                    subtitle: "\(run.buyerIDs.count) out digging",
                    progress: run.progress,
                    dayLabel: run.dayLabel,
                    tint: Theme.amberDeep,
                    points: [
                        ("VOLUME", run.volumePoints, 99 * Double(run.totalDays)),
                        ("RARITY", run.rarityPoints, 99 * Double(run.totalDays)),
                        ("HAGGLE", run.negotiationPoints, 99 * Double(run.totalDays))
                    ],
                    badge: nil,
                    badgeTint: nil
                )
            }

            if game.activeDrop == nil && game.activeRun == nil {
                idleCard
            }
        }
    }

    private var idleCard: some View {
        HStack(spacing: 8) {
            Text("NOTHING IN PRODUCTION")
                .font(Theme.mono(9, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text("SOURCE OR PLAN A DROP")
                .font(Theme.mono(7.5, weight: .semibold))
                .foregroundStyle(Theme.inkSoft.opacity(0.8))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .foregroundStyle(Color(hex: 0xB7AF97))
        )
    }

    private func projectCard(
        title: String,
        subtitle: String,
        progress: Double,
        dayLabel: String,
        tint: Color,
        points: [(String, Double, Double)],
        badge: String?,
        badgeTint: Color?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(title)
                    .font(Theme.display(12))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                if let badge, let badgeTint {
                    Text(badge)
                        .font(Theme.mono(6.5, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(badgeTint)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                Spacer()
                Text(dayLabel)
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(tint)
            }

            Text(subtitle)
                .font(Theme.mono(7))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)

            // The accumulating totals — the numbers you watch climb.
            HStack(spacing: 6) {
                ForEach(points, id: \.0) { label, value, target in
                    pointChip(label: label, value: value, target: target, tint: tint)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0xD7D0BE))
                    Capsule().fill(tint).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 5)
        }
        .padding(10)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(tint, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func pointChip(label: String, value: Double, target: Double, tint: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(Int(value))")
                .font(Theme.display(14))
                .foregroundStyle(tint)
                // Ticks up rather than jumping when a day lands.
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.5), value: value)
            Text(label)
                .font(Theme.mono(6, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
