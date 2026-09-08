import SwiftUI

/// The always-on strip above the tab bar: whatever's in development with its
/// live progress, then the counters that matter.
struct StudioStatBar: View {
    @Environment(Studio.self) private var studio

    var body: some View {
        HStack(spacing: 0) {
            projectBlock

            Rectangle().fill(Theme.line.opacity(0.35)).frame(width: 1, height: 26)

            HStack(spacing: 0) {
                counter(label: "TEAM", value: "\(studio.employees.count)", tint: Theme.steel)
                counter(label: "SHIPPED", value: "\(studio.shippedGames.count)", tint: Theme.green)
                counter(label: "FANS", value: "\(studio.fans)", tint: Theme.plum)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.cream)
        .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .top)
    }

    private var projectBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(projectLabel)
                .font(Theme.mono(7.5, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
            Text(projectPercent)
                .font(Theme.display(15))
                .foregroundStyle(projectTint)
        }
        .frame(width: 90, alignment: .leading)
    }

    private var projectLabel: String {
        if studio.needsShipDecision { return "READY" }
        if studio.currentProject != nil { return "IN DEV" }
        return "STUDIO"
    }

    private var projectPercent: String {
        if studio.needsShipDecision { return "SHIP IT" }
        if let project = studio.currentProject { return "\(Int(project.progress * 100))%" }
        return "IDLE"
    }

    private var projectTint: Color {
        if studio.needsShipDecision { return Theme.amberDeep }
        if studio.currentProject != nil { return Theme.plum }
        return Theme.inkSoft
    }

    private func counter(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.display(14))
                .foregroundStyle(tint)
            Text(label)
                .font(Theme.mono(6.5, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }
}
