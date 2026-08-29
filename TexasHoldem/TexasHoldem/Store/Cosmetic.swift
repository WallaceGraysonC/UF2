import Foundation

enum CosmeticKind: String, Codable, CaseIterable {
    case cardBack, tableFelt, tableRail, chipSet, avatar
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
    static let defaultAvatar = "avatar.default"
    static let defaultFelt = "felt.classicGreen"
    static let defaultRail = "rail.classicOak"
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
    ]

    static func items(of kind: CosmeticKind) -> [Cosmetic] {
        all.filter { $0.kind == kind }
    }

    static func item(id: String) -> Cosmetic? {
        all.first { $0.id == id }
    }
}
