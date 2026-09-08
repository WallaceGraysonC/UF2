import SwiftUI

struct OfficeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Studio.self) private var studio

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("THE OFFICE")
                        .font(Theme.display(22))
                        .foregroundStyle(Theme.ink)
                    Text("$\(studio.cash) · \(studio.employees.count) on the team")
                        .font(Theme.mono(10, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }

                if let next = studio.nextUpgrade {
                    upgradeCard(next)
                } else {
                    Text("Top floor. This is as big as it gets.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                }

                ladderOverview

                Button { dismiss() } label: { Text("BACK") }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
            }
            .padding(20)
            .padding(.top, 24)
        }
        .background(Theme.paper)
    }

    private func upgradeCard(_ upgrade: StudioUpgrade) -> some View {
        let ready = studio.canUpgrade(to: upgrade)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("NEXT — \(upgrade.title.uppercased())")
                    .font(Theme.display(14))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("LV. \(upgrade.level)")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.amberDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            Text(upgrade.detail)
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkSoft)

            requirementRow("$\(upgrade.cost) in the till", met: studio.cash >= upgrade.cost)
            requirementRow("\(upgrade.staffRequired) on the team", met: studio.employees.count >= upgrade.staffRequired)
            requirementRow("Grows to \(upgrade.deskCapacity) desks", met: true)

            Button {
                studio.performUpgrade()
                dismiss()
            } label: {
                Text(ready ? "BUILD IT — $\(upgrade.cost)" : "REQUIREMENTS NOT MET")
            }
            .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
            .disabled(!ready)
            .opacity(ready ? 1 : 0.4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ready ? Theme.green : Theme.line,
                                                          lineWidth: ready ? 2 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func requirementRow(_ label: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Text(met ? "✓" : "✕")
                .font(Theme.mono(11, weight: .bold))
                .foregroundStyle(met ? Theme.green : Theme.red)
                .frame(width: 14)
            Text(label)
                .font(Theme.mono(9))
                .foregroundStyle(met ? Theme.ink : Theme.inkSoft)
        }
    }

    private var ladderOverview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THE LADDER")
                .font(Theme.display(13))
                .foregroundStyle(Theme.ink)

            VStack(spacing: 0) {
                ForEach(StudioUpgrade.ladder) { rung in
                    let built = studio.studioLevel >= rung.level
                    HStack(spacing: 10) {
                        Text("\(rung.level)")
                            .font(Theme.mono(9, weight: .bold))
                            .foregroundStyle(built ? Theme.green : Theme.inkSoft)
                            .frame(width: 16)
                        Text(rung.title)
                            .font(.system(size: 11.5, weight: built ? .semibold : .regular))
                            .foregroundStyle(built ? Theme.ink : Theme.inkSoft)
                        Spacer()
                        Text(built ? "BUILT" : "$\(rung.cost)")
                            .font(Theme.mono(8, weight: .semibold))
                            .foregroundStyle(built ? Theme.green : Theme.inkSoft)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .overlay(Rectangle().fill(Theme.line.opacity(0.6)).frame(height: 1), alignment: .bottom)
                }
            }
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

#Preview {
    OfficeSheet().environment(Studio())
}
