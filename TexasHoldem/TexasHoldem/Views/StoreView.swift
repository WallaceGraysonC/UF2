import SwiftUI
import PhotosUI
import UIKit

/// Cosmetics shop. Every item is purchased with the free virtual chip
/// currency earned at the table -- there is no real-money purchase path
/// anywhere in this screen. Pricier items also require having reached a
/// certain lifetime chip peak (won at the table, not just topped up) --
/// see `BankrollManager.isUnlocked(_:)`. Each category also has a free
/// "Custom Photo" slot, unlocked the same way at a high lifetime peak, that
/// lets the player upload their own image instead of a built-in style.
struct StoreView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedKind: CosmeticKind = .cardBack

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(PATheme.goldMaterial.opacity(0.22))
                            Image(systemName: "cart.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(PATheme.goldBright)
                        }
                        .frame(width: 34, height: 34)

                        Text("Store")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 2)

                    Label("$\(bankroll.chips)", systemImage: "dollarsign.circle.fill")
                        .font(.title3.bold())
                        .foregroundColor(PATheme.goldBright)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                        .overlay(Capsule().stroke(PATheme.gold.opacity(0.35), lineWidth: 1))

                    VStack(spacing: 2) {
                        Text("Spends your main game chips only — the Apple Watch app keeps its own separate practice chips, untouched by the store.")
                        (Text(Image(systemName: "applewatch")) + Text(" marks looks that also show up on the watch. Custom Photo uploads never cross over."))
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                    categoryPicker

                    if selectedKind.crossesOverToWatch {
                        Label("Also appears on the Apple Watch app", systemImage: "applewatch")
                            .font(.caption2.bold())
                            .foregroundColor(PATheme.goldBright)
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.15))

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                        ForEach(CosmeticCatalog.items(of: selectedKind)) { item in
                            CosmeticCard(item: item)
                        }
                    }
                    .padding()
                }
            }
            .tint(PATheme.gold)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    /// A dropdown in place of a horizontally-scrolling row of pills, so all
    /// 8 categories are reachable in one tap instead of a horizontal swipe.
    private var categoryPicker: some View {
        Menu {
            ForEach(CosmeticKind.allCases, id: \.self) { kind in
                Button {
                    selectedKind = kind
                } label: {
                    if kind.crossesOverToWatch {
                        Label(kind.displayName, systemImage: "applewatch")
                    } else {
                        Text(kind.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                if selectedKind.crossesOverToWatch {
                    Image(systemName: "applewatch")
                        .font(.caption)
                }
                Text(selectedKind.displayName)
                    .font(.headline.bold())
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(Capsule().fill(PATheme.goldMaterial.opacity(0.22)))
            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
    }
}

private struct CosmeticCard: View {
    @EnvironmentObject var bankroll: BankrollManager
    @ObservedObject private var customStore = CustomCosmeticStore.shared
    let item: Cosmetic
    @State private var pickerItem: PhotosPickerItem?

    private var isCustomSlot: Bool { item.id == CustomCosmeticStore.customID(for: item.kind) }
    private var hasCustomImage: Bool { customStore.hasImage(for: item.kind) }

    var owned: Bool { bankroll.owns(item) }
    var unlocked: Bool { bankroll.isUnlocked(item) }
    var equipped: Bool {
        switch item.kind {
        case .cardBack: return bankroll.equippedCardBack == item.id
        case .cardFace: return bankroll.equippedCardFace == item.id
        case .tableFelt: return bankroll.equippedFelt == item.id
        case .tableRail: return bankroll.equippedRail == item.id
        case .tableBackdrop: return bankroll.equippedBackdrop == item.id
        case .chipSet: return bankroll.equippedChips == item.id
        case .avatar: return bankroll.equippedAvatar == item.id
        case .avatarFrame: return bankroll.equippedAvatarFrame == item.id
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            swatch
                .opacity(unlocked ? 1 : 0.4)
            Text(item.name).font(.subheadline.bold())

            if isCustomSlot {
                customSlotAction
            } else if equipped {
                Text("Equipped")
                    .font(.caption).bold()
                    .foregroundColor(.green)
            } else if owned {
                Button("Equip") { bankroll.equip(item) }
                    .buttonStyle(.bordered)
                    .tint(PATheme.goldBright)
            } else if !unlocked {
                VStack(spacing: 3) {
                    Label("\(item.price)", systemImage: "lock.fill")
                        .font(.footnote.bold())
                        .foregroundColor(.secondary)
                    Text("Reach $\(item.unlockRequirement) to unlock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                Button {
                    bankroll.purchase(item)
                } label: {
                    Label("\(item.price)", systemImage: "dollarsign.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(PATheme.gold)
                .foregroundStyle(PATheme.ink)
                .disabled(bankroll.chips < item.price)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(colors: [PATheme.feltGlow.opacity(0.5), PATheme.feltDeeper],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(equipped ? PATheme.goldBright.opacity(0.6) : Color.white.opacity(0.08), lineWidth: equipped ? 1.5 : 1)
        )
        .materialShadow(radius: 5, y: 3)
        .onChange(of: pickerItem) { _, newValue in
            loadPickedPhoto(newValue)
        }
    }

    @ViewBuilder
    private var customSlotAction: some View {
        if !unlocked {
            VStack(spacing: 3) {
                Label("Locked", systemImage: "lock.fill")
                    .font(.footnote.bold())
                    .foregroundColor(.secondary)
                Text("Reach $\(item.unlockRequirement) lifetime to unlock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        } else if equipped {
            VStack(spacing: 6) {
                Text("Equipped").font(.caption).bold().foregroundColor(.green)
                replacePhotoButton
            }
        } else if hasCustomImage {
            VStack(spacing: 6) {
                Button("Equip") { bankroll.equip(item) }
                    .buttonStyle(.bordered)
                    .tint(PATheme.goldBright)
                replacePhotoButton
            }
        } else {
            VStack(spacing: 4) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Upload Photo", systemImage: "photo.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(PATheme.gold)
                .foregroundStyle(PATheme.ink)
                Text("Best at \(item.kind.recommendedImageSize)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var replacePhotoButton: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Text("Replace Photo").font(.caption2)
        }
        .buttonStyle(.plain)
        .foregroundColor(.secondary)
    }

    private func loadPickedPhoto(_ selection: PhotosPickerItem?) {
        guard let selection else { return }
        Task {
            if let data = try? await selection.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                customStore.setImage(uiImage, for: item.kind)
                bankroll.equip(item)
            }
            pickerItem = nil
        }
    }

    /// Every category renders inside this same 70×70 box -- cards, chips,
    /// and avatars are naturally smaller than that and center within it,
    /// while felt/rail/backdrop (which have no intrinsic size of their own)
    /// used to just stretch to fill the grid cell's full width instead of
    /// matching everything else. Custom Photo already happened to use 70×70
    /// on its own; this just makes that the one shared rule instead of a
    /// coincidence.
    private var swatch: some View {
        Group {
            if isCustomSlot {
                customSwatch
            } else {
                switch item.kind {
                case .cardBack:
                    CardView(card: nil, faceDown: true, cardBackID: item.id, width: 44)
                case .cardFace:
                    CardView(card: Card(rank: .ace, suit: .spades), cardFaceID: item.id, width: 44)
                case .tableFelt:
                    RoundedRectangle(cornerRadius: 10).fill(feltColor)
                case .tableRail:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(RailPalette.gradient(for: item.id))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RailPalette.seamColor(for: item.id), lineWidth: 2)
                                .padding(4)
                        )
                case .tableBackdrop:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(BackdropPalette.gradient(for: item.id))
                case .chipSet:
                    HStack(spacing: -8) {
                        Circle().fill(chipColor).frame(width: 30, height: 30)
                        Circle().fill(chipColor.opacity(0.7)).frame(width: 30, height: 30)
                    }
                case .avatar:
                    Image(systemName: AvatarPalette.symbol(for: item.id))
                        .font(.system(size: 34))
                        .foregroundColor(.white)
                case .avatarFrame:
                    ZStack {
                        Circle().fill(Color.black.opacity(0.35))
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .frame(width: 48, height: 48)
                    .overlay(Circle().strokeBorder(AvatarFramePalette.stroke(for: item.id), lineWidth: 3))
                }
            }
        }
        .frame(width: 70, height: 70)
    }

    @ViewBuilder
    private var customSwatch: some View {
        if let image = customStore.image(for: item.kind) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 26))
                        .foregroundColor(.secondary)
                )
        }
    }

    private var feltColor: Color { FeltPalette.color(for: item.id) }

    private var chipColor: Color { ChipPalette.color(for: item.id) }
}
