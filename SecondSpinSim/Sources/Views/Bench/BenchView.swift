import SwiftUI

struct BenchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game
    @State private var selectedTab: AppTab = .bench

    private var benchSlots: Int { game.benchCapacity }

    private var techs: [StaffMember] { game.techs }

    var body: some View {
        VStack(spacing: 0) {
            hud
            content
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.paper)
        .onChange(of: selectedTab) { _, newValue in
            if newValue != .bench { dismiss() }
        }
    }

    // MARK: HUD

    private var hud: some View {
        HStack {
            Button { dismiss() } label: {
                Text("‹ BACK").font(Theme.mono(10, weight: .semibold))
            }
            Spacer()
            HUDStatView(value: "\(game.benchJobs.count)/\(benchSlots)", label: "BENCH", valueSize: 14)
            Spacer()
            HUDStatView(value: "\(staffedCount)", label: "STAFFED", valueSize: 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 54)
        .padding(.bottom, 12)
        .background(Theme.ink)
        .foregroundStyle(Theme.cream)
    }

    private var staffedCount: Int {
        game.benchJobs.filter { $0.assignedTechID != nil }.count
    }

    // MARK: Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BACKROOM BENCH")
                .font(Theme.display(14))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(game.benchJobs) { job in
                        RestorationJobRow(
                            job: job,
                            techs: techs,
                            assignedTech: game.staffMember(id: job.assignedTechID),
                            onAssign: { techID in game.assign(techID: techID, to: job.id) }
                        )
                    }
                    if game.benchJobs.count < benchSlots {
                        emptySlotRow
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .padding(.top, 14)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var emptySlotRow: some View {
        Text("OPEN BENCH SLOT — send a haul here from a Sourcing Run")
            .font(Theme.mono(9, weight: .semibold))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(Color(hex: 0xB7AF97))
            )
    }
}

private struct RestorationJobRow: View {
    let job: RestorationJob
    let techs: [StaffMember]
    let assignedTech: StaffMember?
    let onAssign: (UUID?) -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(job.format.binColor)
                .frame(width: 34, height: 34)
                .overlay(
                    Text(job.format.abbreviation)
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(job.itemName)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(job.grade.label)
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(job.grade.color)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: 0xD7D0BE))
                            Capsule().fill(Theme.teal).frame(width: geo.size.width * job.progress)
                        }
                    }
                    .frame(height: 5)
                }

                assignMenu
            }
        }
        .padding(10)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var assignMenu: some View {
        Menu {
            Button("Unassigned") { onAssign(nil) }
            ForEach(techs) { tech in
                Button("\(tech.name) — restoration \(tech.restoration)") { onAssign(tech.id) }
            }
        } label: {
            Text(assignedTech.map { "\($0.name.uppercased()) · TECH" } ?? "UNASSIGNED — TAP TO STAFF")
                .font(Theme.mono(8, weight: .semibold))
                .foregroundStyle(assignedTech == nil ? Theme.red : Theme.inkSoft)
        }
    }
}

#Preview {
    BenchView()
        .environment(GameState())
}
