import SwiftUI

/// The centrepiece: the project in development, its point totals, the
/// classic Design↔Tech focus dial, and the ship button once it's ready.
struct ProjectPanel: View {
    @Environment(Studio.self) private var studio

    var onStartProject: () -> Void
    var onShip: () -> Void

    var body: some View {
        @Bindable var studio = studio

        if let project = studio.currentProject {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text(project.name.uppercased())
                        .font(Theme.display(13))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(project.affinity.label)
                        .font(Theme.mono(6.5, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(project.affinity.color)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    Spacer()
                    Text(studio.needsShipDecision ? "READY" : "DAY \(project.daysElapsed)/\(project.size.devDays)")
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(Theme.plum)
                }

                Text("\(project.genre.rawValue) · \(project.topic.rawValue) · \(project.size.rawValue) · \(project.platform.rawValue)")
                    .font(Theme.mono(7))
                    .foregroundStyle(Theme.inkSoft)

                HStack(spacing: 6) {
                    pointChip(label: "DESIGN", value: project.designPoints, tint: Theme.amberDeep)
                    pointChip(label: "TECH", value: project.techPoints, tint: Theme.steel)
                    if project.unfixedBugCount > 0 {
                        VStack(spacing: 1) {
                            Text("\(project.unfixedBugCount)")
                                .font(Theme.display(14))
                                .foregroundStyle(Theme.red)
                            Text("BUGS")
                                .font(Theme.mono(6, weight: .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Theme.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0xD7D0BE))
                        Capsule().fill(Theme.plum).frame(width: geo.size.width * project.progress)
                    }
                }
                .frame(height: 6)

                if !studio.needsShipDecision {
                    focusDial
                } else {
                    Button(action: onShip) {
                        Text("SHIP IT")
                    }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
                }
            }
            .padding(10)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.plum, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Button(action: onStartProject) {
                HStack(spacing: 8) {
                    Text("START A NEW PROJECT")
                        .font(Theme.mono(9, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("PICK GENRE + TOPIC")
                        .font(Theme.mono(7.5, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .foregroundStyle(Theme.amberDeep)
                )
            }
            .buttonStyle(.plain)
        }
    }

    /// The classic GDS dial: bias the team's effort toward Design or Tech.
    private var focusDial: some View {
        @Bindable var studio = studio
        return VStack(spacing: 3) {
            HStack {
                Text("TECH")
                    .font(Theme.mono(7, weight: .bold))
                    .foregroundStyle(Theme.steel)
                Spacer()
                Text("FOCUS")
                    .font(Theme.mono(6.5, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("DESIGN")
                    .font(Theme.mono(7, weight: .bold))
                    .foregroundStyle(Theme.amberDeep)
            }
            Slider(value: Binding(
                get: { studio.currentProject?.focusBias ?? 0.5 },
                set: { studio.currentProject?.focusBias = $0 }
            ), in: 0...1)
            .tint(Theme.plum)
        }
    }

    private func pointChip(label: String, value: Double, tint: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(Int(value))")
                .font(Theme.display(14))
                .foregroundStyle(tint)
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
