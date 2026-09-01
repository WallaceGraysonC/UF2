import SwiftUI

struct BenchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: AppTab = .bench

    var benchSlots: Int = 4
    var jobs: [RestorationJob] = [
        RestorationJob(itemName: "Blondie — Parallel Lines", format: .vinyl, startGrade: .good, progress: 0.7, assignedTechName: "Priya"),
        RestorationJob(itemName: "Night Tide (Criterion LD)", format: .laserdisc, startGrade: .fair, progress: 0.3, assignedTechName: "Priya"),
        RestorationJob(itemName: "Chrono Trigger (cart only)", format: .game, startGrade: .poor, progress: 0.1, assignedTechName: nil),
        RestorationJob(itemName: "The Warriors (VHS, clamshell)", format: .vhs, startGrade: .veryGood, progress: 0.9, assignedTechName: nil)
    ]

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
            HUDStatView(value: "\(jobs.count)/\(benchSlots)", label: "BENCH", valueSize: 14)
            Spacer()
            HUDStatView(value: "\(jobs.filter { $0.assignedTechName != nil }.count)", label: "STAFFED", valueSize: 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 54)
        .padding(.bottom, 12)
        .background(Theme.ink)
        .foregroundStyle(Theme.cream)
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
                    ForEach(jobs) { job in
                        RestorationJobRow(job: job)
                    }
                    if jobs.count < benchSlots {
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
        Text("OPEN BENCH SLOT — send a haul here from the Ledger")
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
                    Text(job.startGrade.label)
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(job.startGrade.color)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: 0xD7D0BE))
                            Capsule().fill(Theme.teal).frame(width: geo.size.width * job.progress)
                        }
                    }
                    .frame(height: 5)
                }

                Text(job.assignedTechName.map { "\($0.uppercased()) · TECH" } ?? "UNASSIGNED")
                    .font(Theme.mono(8, weight: .semibold))
                    .foregroundStyle(job.assignedTechName == nil ? Theme.red : Theme.inkSoft)
            }
        }
        .padding(10)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    BenchView()
}
