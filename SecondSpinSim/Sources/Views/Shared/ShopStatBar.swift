import SwiftUI

/// The always-on strip above the tab bar, modelled on the persistent stat
/// readout Kairosoft keeps at the bottom of the screen: whatever project is
/// running with its live percentage, then the counters that matter.
struct ShopStatBar: View {
    @Environment(GameState.self) private var game

    var body: some View {
        HStack(spacing: 0) {
            projectBlock

            Rectangle().fill(Theme.line.opacity(0.35)).frame(width: 1, height: 26)

            HStack(spacing: 0) {
                counter(label: "STOCK", value: "\(game.shelvedInventory.count)", tint: Theme.steel)
                counter(label: "GRAILS", value: "\(grailCount)", tint: Theme.red)
                counter(label: "BENCH", value: "\(game.benchJobs.count)", tint: Theme.teal)
                counter(label: "REP", value: "\(game.overallReputation)", tint: Theme.plum)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Theme.cream)
        .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .top)
    }

    private var grailCount: Int {
        game.shelvedInventory.filter(\.isRare).count
    }

    /// Whichever project is live gets the headline percentage.
    private var projectBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(projectLabel)
                .font(Theme.mono(7.5, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
            Text(projectPercent)
                .font(Theme.display(15))
                .foregroundStyle(projectTint)
        }
        .frame(width: 78, alignment: .leading)
    }

    private var projectLabel: String {
        if game.activeDrop != nil { return "DROP PREP" }
        if game.activeRun != nil { return "SOURCING" }
        if !game.pendingHaul.isEmpty { return "TO GRADE" }
        return "SHOP"
    }

    private var projectPercent: String {
        if let drop = game.activeDrop { return "\(Int(drop.progress * 100))%" }
        if let run = game.activeRun { return "\(Int(run.progress * 100))%" }
        if !game.pendingHaul.isEmpty { return "\(game.pendingHaul.count)" }
        return "OPEN"
    }

    private var projectTint: Color {
        if game.activeDrop != nil { return Theme.plum }
        if game.activeRun != nil { return Theme.amberDeep }
        if !game.pendingHaul.isEmpty { return Theme.red }
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
