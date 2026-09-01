import SwiftUI

/// The level-up screen. Shows every gate on the next rung with a tick or a
/// cross, so it's always obvious what's still missing — cash is never the
/// only thing standing between you and the next section.
struct UpgradeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                if let next = game.nextUpgrade {
                    upgradeCard(next)
                } else {
                    Text("Level 10. The Museum Wall is up and the shop is everything it's going to be.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                }

                ladderOverview

                Button { dismiss() } label: { Text("BACK TO THE FLOOR") }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
            }
            .padding(20)
            .padding(.top, 20)
        }
        .background(Theme.paper)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("SHOP LEVEL \(game.shopLevel)")
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink)
            Text("$\(game.cash) · \(game.staff.count) staff")
                .font(Theme.mono(10, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private func upgradeCard(_ upgrade: ShopUpgrade) -> some View {
        let ready = game.canUpgrade(to: upgrade)
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
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 5) {
                ForEach(game.requirements(for: upgrade)) { requirement in
                    HStack(spacing: 8) {
                        Text(requirement.met ? "✓" : "✕")
                            .font(Theme.mono(11, weight: .bold))
                            .foregroundStyle(requirement.met ? Theme.green : Theme.red)
                            .frame(width: 14)
                        Text(requirement.label)
                            .font(Theme.mono(9))
                            .foregroundStyle(requirement.met ? Theme.ink : Theme.inkSoft)
                        Spacer()
                    }
                }
            }
            .padding(.top, 2)

            Button {
                game.performUpgrade()
                dismiss()
            } label: {
                Text(ready ? "BUILD IT — $\(upgrade.cash)" : "REQUIREMENTS NOT MET")
            }
            .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
            .disabled(!ready)
            .opacity(ready ? 1 : 0.4)
            .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ready ? Theme.green : Theme.line,
                                                          lineWidth: ready ? 2 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    /// The whole ladder, so the player can see what they're building toward.
    private var ladderOverview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THE LADDER")
                .font(Theme.display(13))
                .foregroundStyle(Theme.ink)

            VStack(spacing: 0) {
                ForEach(ShopUpgrade.ladder) { rung in
                    let built = game.shopLevel >= rung.level
                    HStack(spacing: 10) {
                        Text("\(rung.level)")
                            .font(Theme.mono(9, weight: .bold))
                            .foregroundStyle(built ? Theme.green : Theme.inkSoft)
                            .frame(width: 16)

                        Text(rung.title)
                            .font(.system(size: 11.5, weight: built ? .semibold : .regular))
                            .foregroundStyle(built ? Theme.ink : Theme.inkSoft)

                        Spacer()

                        Text(built ? "BUILT" : "$\(rung.cash) · \(rung.staffRequired) STAFF")
                            .font(Theme.mono(8, weight: .semibold))
                            .foregroundStyle(built ? Theme.green : Theme.inkSoft)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .overlay(Rectangle().fill(Theme.line.opacity(0.6)).frame(height: 1),
                             alignment: .bottom)
                }
            }
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

#Preview {
    UpgradeSheet()
        .environment(GameState())
}
