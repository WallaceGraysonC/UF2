import SwiftUI

/// The retirement flow: confirm the score, choose a permanent perk, then see
/// what the run unlocked. Deliberately a two-step — closing up shop should
/// feel like a decision, not a button you brush past.
struct RetirementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game

    var onConfirm: () -> Void = {}

    @State private var profile: LegacyProfile = LegacyStore.load()
    @State private var chosenPerk: LegacyPerk?
    @State private var newlyUnlocked: [Cosmetic] = []
    @State private var didRetire = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if didRetire {
                    farewell
                } else {
                    confirmation
                }
            }
            .padding(20)
            .padding(.top, 26)
        }
        .background(Theme.paper)
    }

    // MARK: Before

    private var confirmation: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CLOSE UP SHOP")
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.ink)
                Text("Day \(game.day) · Level \(game.shopLevel) · \(game.museum.count) on the wall")
                    .font(Theme.mono(9, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }

            scoreBreakdown

            VStack(alignment: .leading, spacing: 7) {
                Text("TAKE ONE THING WITH YOU")
                    .font(Theme.display(13))
                    .foregroundStyle(Theme.ink)

                ForEach(LegacyPerk.allCases) { perk in
                    perkRow(perk)
                }
            }

            Button {
                retire()
            } label: {
                Text(chosenPerk == nil ? "CHOOSE A PERK" : "CLOSE UP SHOP FOR GOOD")
            }
            .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
            .disabled(chosenPerk == nil)
            .opacity(chosenPerk == nil ? 0.4 : 1)

            Button { dismiss() } label: { Text("NOT YET — KEEP TRADING") }
                .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
        }
    }

    private var scoreBreakdown: some View {
        VStack(spacing: 6) {
            row("Reputation", game.overallReputation * 12)
            row("The wall", game.museum.map(\.forgoneValue).reduce(0, +) * 2)
            row("Lifetime trade", game.lifetimeRevenue / 10)
            row("Staff brought on", game.staffTrainedCount * 60)
            row("Five-star nights", game.fiveStarDrops * 120)

            Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 3)

            HStack {
                Text("LEGACY SCORE")
                    .font(Theme.mono(10, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(game.legacyScore)")
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.amberDeep)
            }
        }
        .padding(14)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func row(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label)
                .font(Theme.mono(9))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text("\(value)")
                .font(Theme.mono(10, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
    }

    private func perkRow(_ perk: LegacyPerk) -> some View {
        let owned = profile.has(perk)
        let affordable = game.legacyScore >= perk.scoreRequired
        let selectable = !owned && affordable
        return Button {
            if selectable { chosenPerk = perk }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(chosenPerk == perk ? Theme.amberDeep : Color(hex: 0xD7D0BE))
                    .frame(width: 14, height: 14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(perk.rawValue.uppercased())
                        .font(Theme.mono(9, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(owned ? "Already yours" : perk.detail)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.inkSoft)
                }

                Spacer()

                if owned {
                    Text("HELD")
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(Theme.green)
                } else if !affordable {
                    Text("\(perk.scoreRequired)+")
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(Theme.red)
                }
            }
            .padding(10)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 5)
                .stroke(chosenPerk == perk ? Theme.amberDeep : Theme.line,
                        lineWidth: chosenPerk == perk ? 2 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .opacity(selectable ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!selectable)
    }

    // MARK: After

    private var farewell: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SHUTTERS DOWN")
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.ink)
                Text("Shop #\(profile.prestigeCount) closed. Everything on the wall goes with you.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSoft)
            }

            HStack {
                Text("BANKED")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("\(profile.bestLegacyScore) BEST · \(profile.totalLegacyScore) TOTAL")
                    .font(Theme.mono(10, weight: .bold))
                    .foregroundStyle(Theme.amberDeep)
            }
            .padding(12)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if newlyUnlocked.isEmpty {
                Text("Nothing new unlocked this time — the harder goals are still out there.")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    Text("UNLOCKED")
                        .font(Theme.display(13))
                        .foregroundStyle(Theme.ink)

                    ForEach(newlyUnlocked) { cosmetic in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(cosmetic.color)
                                .frame(width: 26, height: 26)
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 5) {
                                    Text(cosmetic.name.uppercased())
                                        .font(Theme.mono(9, weight: .bold))
                                        .foregroundStyle(Theme.ink)
                                    if cosmetic.isSecret {
                                        Text("SECRET")
                                            .font(Theme.mono(7, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Theme.red)
                                            .clipShape(RoundedRectangle(cornerRadius: 2))
                                    }
                                }
                                Text(cosmetic.flavour)
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Theme.cream)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.amberDeep, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
            }

            Button {
                dismiss()
                onConfirm()
            } label: {
                Text("OPEN SOMEWHERE NEW")
            }
            .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
        }
    }

    private func retire() {
        newlyUnlocked = game.closeUpShop(into: &profile, perk: chosenPerk)
        didRetire = true
    }
}

#Preview {
    RetirementSheet()
        .environment(GameState())
}
