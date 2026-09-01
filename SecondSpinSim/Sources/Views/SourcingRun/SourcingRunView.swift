import SwiftUI

struct SourcingRunView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game
    @State private var selectedTab: AppTab = .source
    @State private var isGraded = false

    var locationName: String = "ESTATE SALE — WESTSIDE"
    var runProgress: String = "DAY 2/3"
    var itemName: String = "Laserdisc — \"Night Tide\" (1961)"
    var itemDetail: String = "Criterion pressing"
    var conditionValue: Double = 0.64

    /// Buyers are the role that runs Sourcing.
    private var staff: [StaffMember] { game.staff.filter { $0.role == .buyer } }

    private var grade: ConditionGrade { ConditionGrade(value: conditionValue) }

    var body: some View {
        VStack(spacing: 0) {
            hud
            content
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.paper)
        .onChange(of: selectedTab) { _, newValue in
            if newValue != .source {
                dismiss()
            }
        }
    }

    // MARK: HUD

    private var hud: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("‹ BACK")
                    .font(Theme.mono(10, weight: .semibold))
            }
            Spacer()
            HUDStatView(value: runProgress, label: "RUN", valueSize: 14)
            Spacer()
            HUDStatView(value: "×\(staff.count)", label: "STAFF", valueSize: 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 54)
        .padding(.bottom, 12)
        .background(Theme.ink)
        .foregroundStyle(Theme.cream)
    }

    // MARK: Content

    private var content: some View {
        VStack(spacing: 16) {
            Text(locationName)
                .font(Theme.display(13))
                .foregroundStyle(Theme.ink)

            itemCard

            staffStrip
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var itemCard: some View {
        VStack(spacing: 12) {
            RecordDiscView()
                .frame(width: 84, height: 84)

            VStack(spacing: 2) {
                Text(itemName)
                    .font(.system(size: 13, weight: .semibold))
                    .multilineTextAlignment(.center)
                Text(itemDetail)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkSoft)
            }

            gradeMeter

            HStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text("SKIP")
                }
                .buttonStyle(GhostButtonStyle())

                Button {
                    withAnimation(.easeOut(duration: 0.2)) { isGraded = true }
                } label: {
                    Text(isGraded ? "GRADED" : "GRADE IT")
                }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
                .disabled(isGraded)
            }
        }
        .padding(16)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var gradeMeter: some View {
        VStack(spacing: 5) {
            HStack {
                Text("POOR").font(Theme.mono(8)).foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("MINT").font(Theme.mono(8)).foregroundStyle(Theme.inkSoft)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: 0xD7D0BE))
                    Capsule()
                        .fill(grade.color)
                        .frame(width: geo.size.width * conditionValue)
                }
            }
            .frame(height: 9)

            if isGraded {
                Text("\(grade.label) — grail candidate")
                    .font(Theme.display(12))
                    .foregroundStyle(Theme.red)
                    .transition(.opacity)
            }
        }
    }

    private var staffStrip: some View {
        HStack(spacing: 8) {
            ForEach(staff) { member in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(member.name.uppercased()) · \(member.role.rawValue)")
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: 0xD7D0BE))
                            Capsule().fill(Theme.teal)
                                .frame(width: geo.size.width * (Double(member.raritySense) / 99.0))
                        }
                    }
                    .frame(height: 4)
                }
                .padding(7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cream)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}

/// Simple vinyl/laserdisc stand-in — a couple of concentric rings and a label hole.
private struct RecordDiscView: View {
    var body: some View {
        ZStack {
            Circle().fill(Theme.ink)
            Circle().stroke(Theme.inkSoft.opacity(0.5), lineWidth: 1).padding(10)
            Circle().stroke(Theme.inkSoft.opacity(0.5), lineWidth: 1).padding(22)
            Circle().fill(Theme.cream).frame(width: 18, height: 18)
        }
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }
}

private struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.display(13))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xB7AF97), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

#Preview {
    SourcingRunView()
        .environment(GameState())
}
