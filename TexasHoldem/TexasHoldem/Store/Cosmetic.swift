import Foundation

enum CosmeticKind: String, Codable, CaseIterable {
    case cardBack, cardFace, tableFelt, tableRail, tableBackdrop, chipSet, avatar, avatarFrame

    var displayName: String {
        switch self {
        case .cardBack: return "Card Backs"
        case .cardFace: return "Card Faces"
        case .tableFelt: return "Felt"
        case .tableRail: return "Rail"
        case .tableBackdrop: return "Room"
        case .chipSet: return "Chips"
        case .avatar: return "Avatars"
        case .avatarFrame: return "Frames"
        }
    }

    /// Suggested source-image dimensions for this category's "Custom Photo"
    /// upload, shown to the player before they pick one -- matched to each
    /// shape's on-screen proportions so the photo doesn't look stretched.
    var recommendedImageSize: String {
        switch self {
        case .cardBack, .cardFace: return "400×600"
        case .tableFelt: return "1600×1200"
        case .tableRail: return "1600×300"
        case .tableBackdrop: return "1200×2000"
        case .chipSet, .avatar, .avatarFrame: return "512×512"
        }
    }
}

struct Cosmetic: Identifiable, Codable, Hashable {
    let id: String
    let kind: CosmeticKind
    let name: String
    let price: Int
    /// Minimum lifetime chip peak (`BankrollManager.highestChips`) required
    /// before this item can be purchased, on top of affording its price.
    /// Gates the pricier items behind money actually won at the table
    /// rather than just money currently on hand -- resets/top-ups are
    /// capped low, so this can't be farmed by resetting over and over.
    let unlockRequirement: Int
    /// Asset/SwiftUI color or image name used by the renderer.
    let assetName: String
}

/// The full catalog of purchasable cosmetics. All prices are in the
/// in-app virtual currency only -- there is no real-money purchase path.
enum CosmeticCatalog {
    static let defaultCardBack = "cardback.classicBlue"
    static let defaultCardFace = "face.classic"
    static let defaultAvatar = "avatar.default"
    static let defaultAvatarFrame = "frame.none"
    static let defaultFelt = "felt.classicGreen"
    static let defaultRail = "rail.classicOak"
    static let defaultBackdrop = "backdrop.midnight"
    static let defaultChips = "chips.classic"

    static let all: [Cosmetic] = [
        // MARK: Card backs
        Cosmetic(id: "cardback.classicBlue", kind: .cardBack, name: "Classic Blue", price: 0, unlockRequirement: 0, assetName: "cardback.classicBlue"),
        Cosmetic(id: "cardback.crimson", kind: .cardBack, name: "Crimson", price: 600, unlockRequirement: 0, assetName: "cardback.crimson"),
        Cosmetic(id: "cardback.midnight", kind: .cardBack, name: "Midnight", price: 900, unlockRequirement: 0, assetName: "cardback.midnight"),
        Cosmetic(id: "cardback.forest", kind: .cardBack, name: "Forest", price: 900, unlockRequirement: 0, assetName: "cardback.forest"),
        Cosmetic(id: "cardback.violet", kind: .cardBack, name: "Violet", price: 1100, unlockRequirement: 0, assetName: "cardback.violet"),
        Cosmetic(id: "cardback.copper", kind: .cardBack, name: "Copper", price: 1500, unlockRequirement: 1500, assetName: "cardback.copper"),
        Cosmetic(id: "cardback.gold", kind: .cardBack, name: "Gold Foil", price: 2600, unlockRequirement: 3000, assetName: "cardback.gold"),
        Cosmetic(id: "cardback.holographic", kind: .cardBack, name: "Holographic", price: 4500, unlockRequirement: 5000, assetName: "cardback.holographic"),

        // MARK: Card face (the rank/suit style on the front of every card)
        Cosmetic(id: "face.classic", kind: .cardFace, name: "Classic Serif", price: 0, unlockRequirement: 0, assetName: "face.classic"),
        Cosmetic(id: "face.modern", kind: .cardFace, name: "Modern Sans", price: 700, unlockRequirement: 0, assetName: "face.modern"),
        Cosmetic(id: "face.rounded", kind: .cardFace, name: "Rounded", price: 700, unlockRequirement: 0, assetName: "face.rounded"),
        Cosmetic(id: "face.blockBold", kind: .cardFace, name: "Block Bold", price: 1200, unlockRequirement: 1500, assetName: "face.blockBold"),

        // MARK: Table felt
        Cosmetic(id: "felt.classicGreen", kind: .tableFelt, name: "Classic Green", price: 0, unlockRequirement: 0, assetName: "felt.classicGreen"),
        Cosmetic(id: "felt.royalBlue", kind: .tableFelt, name: "Royal Blue", price: 750, unlockRequirement: 0, assetName: "felt.royalBlue"),
        Cosmetic(id: "felt.charcoal", kind: .tableFelt, name: "Charcoal", price: 750, unlockRequirement: 0, assetName: "felt.charcoal"),
        Cosmetic(id: "felt.burgundy", kind: .tableFelt, name: "Burgundy", price: 1100, unlockRequirement: 0, assetName: "felt.burgundy"),
        Cosmetic(id: "felt.teal", kind: .tableFelt, name: "Teal", price: 1100, unlockRequirement: 0, assetName: "felt.teal"),
        Cosmetic(id: "felt.sunset", kind: .tableFelt, name: "Sunset", price: 1800, unlockRequirement: 1500, assetName: "felt.sunset"),
        Cosmetic(id: "felt.midnightGold", kind: .tableFelt, name: "Midnight Gold", price: 3200, unlockRequirement: 3000, assetName: "felt.midnightGold"),

        // MARK: Table rail (the wood/trim border around the felt)
        Cosmetic(id: "rail.classicOak", kind: .tableRail, name: "Classic Oak", price: 0, unlockRequirement: 0, assetName: "rail.classicOak"),
        Cosmetic(id: "rail.darkWalnut", kind: .tableRail, name: "Dark Walnut", price: 700, unlockRequirement: 0, assetName: "rail.darkWalnut"),
        Cosmetic(id: "rail.ebony", kind: .tableRail, name: "Ebony", price: 1100, unlockRequirement: 0, assetName: "rail.ebony"),
        Cosmetic(id: "rail.crimsonLeather", kind: .tableRail, name: "Crimson Leather", price: 1400, unlockRequirement: 0, assetName: "rail.crimsonLeather"),
        Cosmetic(id: "rail.roseGold", kind: .tableRail, name: "Rose Gold", price: 2000, unlockRequirement: 1500, assetName: "rail.roseGold"),
        Cosmetic(id: "rail.carbonFiber", kind: .tableRail, name: "Carbon Fiber", price: 2800, unlockRequirement: 3000, assetName: "rail.carbonFiber"),
        Cosmetic(id: "rail.platinum", kind: .tableRail, name: "Platinum", price: 4200, unlockRequirement: 5000, assetName: "rail.platinum"),

        // MARK: Table backdrop (the room/scene behind the table itself)
        Cosmetic(id: "backdrop.midnight", kind: .tableBackdrop, name: "Midnight", price: 0, unlockRequirement: 0, assetName: "backdrop.midnight"),
        Cosmetic(id: "backdrop.casinoFloor", kind: .tableBackdrop, name: "Casino Floor", price: 700, unlockRequirement: 0, assetName: "backdrop.casinoFloor"),
        Cosmetic(id: "backdrop.velvetLounge", kind: .tableBackdrop, name: "Velvet Lounge", price: 900, unlockRequirement: 0, assetName: "backdrop.velvetLounge"),
        Cosmetic(id: "backdrop.sunsetLounge", kind: .tableBackdrop, name: "Sunset Lounge", price: 1100, unlockRequirement: 0, assetName: "backdrop.sunsetLounge"),
        Cosmetic(id: "backdrop.emeraldRoom", kind: .tableBackdrop, name: "Emerald Room", price: 1100, unlockRequirement: 0, assetName: "backdrop.emeraldRoom"),
        Cosmetic(id: "backdrop.neonNights", kind: .tableBackdrop, name: "Neon Nights", price: 2000, unlockRequirement: 1500, assetName: "backdrop.neonNights"),
        Cosmetic(id: "backdrop.royalGold", kind: .tableBackdrop, name: "Royal Gold", price: 3000, unlockRequirement: 3000, assetName: "backdrop.royalGold"),

        // MARK: Chip sets
        Cosmetic(id: "chips.classic", kind: .chipSet, name: "Classic Chips", price: 0, unlockRequirement: 0, assetName: "chips.classic"),
        Cosmetic(id: "chips.neon", kind: .chipSet, name: "Neon", price: 1100, unlockRequirement: 0, assetName: "chips.neon"),
        Cosmetic(id: "chips.marble", kind: .chipSet, name: "Marble", price: 2200, unlockRequirement: 1500, assetName: "chips.marble"),
        Cosmetic(id: "chips.jade", kind: .chipSet, name: "Jade", price: 2200, unlockRequirement: 1500, assetName: "chips.jade"),
        Cosmetic(id: "chips.sapphire", kind: .chipSet, name: "Sapphire", price: 2800, unlockRequirement: 3000, assetName: "chips.sapphire"),
        Cosmetic(id: "chips.diamond", kind: .chipSet, name: "Diamond", price: 5000, unlockRequirement: 5000, assetName: "chips.diamond"),

        // MARK: Avatars
        Cosmetic(id: "avatar.default", kind: .avatar, name: "Default", price: 0, unlockRequirement: 0, assetName: "avatar.default"),
        Cosmetic(id: "avatar.shark", kind: .avatar, name: "Shark", price: 500, unlockRequirement: 0, assetName: "avatar.shark"),
        Cosmetic(id: "avatar.robot", kind: .avatar, name: "Robot", price: 500, unlockRequirement: 0, assetName: "avatar.robot"),
        Cosmetic(id: "avatar.fox", kind: .avatar, name: "Fox", price: 750, unlockRequirement: 0, assetName: "avatar.fox"),
        Cosmetic(id: "avatar.wizard", kind: .avatar, name: "Wizard", price: 1100, unlockRequirement: 0, assetName: "avatar.wizard"),
        Cosmetic(id: "avatar.astronaut", kind: .avatar, name: "Astronaut", price: 1500, unlockRequirement: 1500, assetName: "avatar.astronaut"),
        Cosmetic(id: "avatar.dragon", kind: .avatar, name: "Dragon", price: 2600, unlockRequirement: 3000, assetName: "avatar.dragon"),
        Cosmetic(id: "avatar.crown", kind: .avatar, name: "High Roller", price: 3600, unlockRequirement: 5000, assetName: "avatar.crown"),

        // MARK: Avatar frames (the ring around your avatar icon at the table)
        Cosmetic(id: "frame.none", kind: .avatarFrame, name: "No Frame", price: 0, unlockRequirement: 0, assetName: "frame.none"),
        Cosmetic(id: "frame.silver", kind: .avatarFrame, name: "Silver Ring", price: 600, unlockRequirement: 0, assetName: "frame.silver"),
        Cosmetic(id: "frame.gold", kind: .avatarFrame, name: "Gold Ring", price: 1000, unlockRequirement: 0, assetName: "frame.gold"),
        Cosmetic(id: "frame.sapphire", kind: .avatarFrame, name: "Sapphire Ring", price: 1600, unlockRequirement: 1500, assetName: "frame.sapphire"),
        Cosmetic(id: "frame.crimson", kind: .avatarFrame, name: "Crimson Ring", price: 1600, unlockRequirement: 1500, assetName: "frame.crimson"),
        Cosmetic(id: "frame.royal", kind: .avatarFrame, name: "Royal Ring", price: 2400, unlockRequirement: 3000, assetName: "frame.royal"),

        // MARK: Custom Photo -- one free "upload your own" slot per
        // category, unlocked at a high lifetime chip peak so it's a real
        // milestone to work toward rather than something to just buy.
        Cosmetic(id: CustomCosmeticStore.customID(for: .cardBack), kind: .cardBack, name: "Custom Photo", price: 0, unlockRequirement: 5000, assetName: "custom"),
        Cosmetic(id: CustomCosmeticStore.customID(for: .cardFace), kind: .cardFace, name: "Custom Photo", price: 0, unlockRequirement: 5000, assetName: "custom"),
        Cosmetic(id: CustomCosmeticStore.customID(for: .tableFelt), kind: .tableFelt, name: "Custom Photo", price: 0, unlockRequirement: 5000, assetName: "custom"),
        Cosmetic(id: CustomCosmeticStore.customID(for: .tableRail), kind: .tableRail, name: "Custom Photo", price: 0, unlockRequirement: 5000, assetName: "custom"),
        Cosmetic(id: CustomCosmeticStore.customID(for: .tableBackdrop), kind: .tableBackdrop, name: "Custom Photo", price: 0, unlockRequirement: 5000, assetName: "custom"),
        Cosmetic(id: CustomCosmeticStore.customID(for: .chipSet), kind: .chipSet, name: "Custom Photo", price: 0, unlockRequirement: 5000, assetName: "custom"),
        Cosmetic(id: CustomCosmeticStore.customID(for: .avatar), kind: .avatar, name: "Custom Photo", price: 0, unlockRequirement: 5000, assetName: "custom"),
        Cosmetic(id: CustomCosmeticStore.customID(for: .avatarFrame), kind: .avatarFrame, name: "Custom Photo", price: 0, unlockRequirement: 5000, assetName: "custom"),
    ]

    static func items(of kind: CosmeticKind) -> [Cosmetic] {
        all.filter { $0.kind == kind }
    }

    static func item(id: String) -> Cosmetic? {
        all.first { $0.id == id }
    }
}
