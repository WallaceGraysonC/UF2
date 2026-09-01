import SwiftUI

/// The between-runs screen: what every shop you've closed added up to, the
/// perks you carry, and the cosmetics gallery. Lives on the main menu because
/// it outlives any single run.
struct LegacyView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: LegacyProfile
    @State private var selectedSlot: CosmeticSlot = .floor

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                perksSection
                gallery
                Button { dismiss() } label: { Text("BACK") }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
            }
            .padding(20)
            .padding(.top, 24)
        }
        .background(Theme.stageBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LEGACY")
                .font(Theme.display(24))
                .foregroundStyle(Theme.cream)

            if profile.prestigeCount == 0 {
                Text("No shops closed yet. Reach level 10, put something on the Museum Wall, and you can retire whenever you like.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("\(profile.prestigeCount) shop\(profile.prestigeCount == 1 ? "" : "s") closed · best \(profile.bestLegacyScore) · \(profile.totalLegacyScore) banked")
                    .font(Theme.mono(9, weight: .semibold))
                    .foregroundStyle(Theme.amber)
            }
        }
    }

    private var perksSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("PERKS HELD")
                .font(Theme.display(13))
                .foregroundStyle(Theme.cream)

            if profile.perks.isEmpty {
                Text("None yet — you pick one each time you close up shop.")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(profile.perks) { perk in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(perk.rawValue.uppercased())
                            .font(Theme.mono(9, weight: .bold))
                            .foregroundStyle(Theme.amber)
                        Text(perk.detail)
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.amber.opacity(0.4), lineWidth: 1))
                }
            }
        }
    }

    // MARK: Cosmetics

    private var gallery: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THE SHOP")
                .font(Theme.display(13))
                .foregroundStyle(Theme.cream)

            slotPicker

            VStack(spacing: 7) {
                ForEach(visibleCosmetics) { cosmetic in
                    cosmeticRow(cosmetic)
                }
                if hiddenCount > 0 {
                    Text("\(hiddenCount) secret \(hiddenCount == 1 ? "piece" : "pieces") still hidden in this slot.")
                        .font(Theme.mono(8, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                .foregroundStyle(Theme.inkSoft.opacity(0.5))
                        )
                }
            }
        }
    }

    private var slotPicker: some View {
        HStack(spacing: 6) {
            ForEach(CosmeticSlot.allCases) { slot in
                Button {
                    selectedSlot = slot
                } label: {
                    Text(slot.rawValue.uppercased())
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(selectedSlot == slot ? Theme.ink : Theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(selectedSlot == slot ? Theme.amber : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 4)
                            .stroke(selectedSlot == slot ? Theme.amber : Theme.inkSoft.opacity(0.5),
                                    lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Secrets stay out of the list until they're earned.
    private var visibleCosmetics: [Cosmetic] {
        CosmeticCatalog.inSlot(selectedSlot).filter { !$0.isSecret || profile.isUnlocked($0) }
    }

    private var hiddenCount: Int {
        CosmeticCatalog.inSlot(selectedSlot).filter { $0.isSecret && !profile.isUnlocked($0) }.count
    }

    private func cosmeticRow(_ cosmetic: Cosmetic) -> some View {
        let unlocked = profile.isUnlocked(cosmetic)
        let equipped = profile.equippedCosmetic(in: cosmetic.slot).id == cosmetic.id
        return Button {
            if unlocked {
                profile.equip(cosmetic)
                LegacyStore.save(profile)
            }
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(cosmetic.color)
                    .frame(width: 28, height: 28)
                    .opacity(unlocked ? 1 : 0.25)

                VStack(alignment: .leading, spacing: 2) {
                    Text(cosmetic.name.uppercased())
                        .font(Theme.mono(9, weight: .bold))
                        .foregroundStyle(unlocked ? Theme.cream : Theme.inkSoft)
                    Text(unlocked ? cosmetic.flavour : cosmetic.unlock.describe)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if equipped {
                    Text("ON")
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Theme.amber)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                } else if !unlocked {
                    Text("LOCKED")
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .padding(10)
            .overlay(RoundedRectangle(cornerRadius: 5)
                .stroke(equipped ? Theme.amber : Theme.inkSoft.opacity(0.4), lineWidth: equipped ? 2 : 1))
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }
}

#Preview {
    LegacyView(profile: .constant(LegacyProfile()))
}
