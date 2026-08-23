import Foundation

enum CosmeticKind: String, Codable {
    case cardBack, tableFelt, chipSet, avatar
}

struct Cosmetic: Identifiable, Codable, Hashable {
    let id: String
    let kind: CosmeticKind
    let name: String
    let price: Int
    /// Asset/SwiftUI color or image name used by the renderer.
    let assetName: String
}

/// The full catalog of purchasable cosmetics. All prices are in the
/// in-app virtual currency only -- there is no real-money purchase path.
enum CosmeticCatalog {
    static let defaultCardBack = "cardback.classicBlue"
    static let defaultAvatar = "avatar.default"
    static let defaultFelt = "felt.classicGreen"
    static let defaultChips = "chips.classic"

    static let all: [Cosmetic] = [
        Cosmetic(id: "cardback.classicBlue", kind: .cardBack, name: "Classic Blue", price: 0, assetName: "cardback.classicBlue"),
        Cosmetic(id: "cardback.crimson", kind: .cardBack, name: "Crimson", price: 500, assetName: "cardback.crimson"),
        Cosmetic(id: "cardback.midnight", kind: .cardBack, name: "Midnight", price: 750, assetName: "cardback.midnight"),
        Cosmetic(id: "cardback.forest", kind: .cardBack, name: "Forest", price: 750, assetName: "cardback.forest"),
        Cosmetic(id: "cardback.violet", kind: .cardBack, name: "Violet", price: 900, assetName: "cardback.violet"),
        Cosmetic(id: "cardback.copper", kind: .cardBack, name: "Copper", price: 1200, assetName: "cardback.copper"),
        Cosmetic(id: "cardback.gold", kind: .cardBack, name: "Gold Foil", price: 2000, assetName: "cardback.gold"),
        Cosmetic(id: "cardback.holographic", kind: .cardBack, name: "Holographic", price: 3500, assetName: "cardback.holographic"),

        Cosmetic(id: "felt.classicGreen", kind: .tableFelt, name: "Classic Green", price: 0, assetName: "felt.classicGreen"),
        Cosmetic(id: "felt.royalBlue", kind: .tableFelt, name: "Royal Blue", price: 600, assetName: "felt.royalBlue"),
        Cosmetic(id: "felt.charcoal", kind: .tableFelt, name: "Charcoal", price: 600, assetName: "felt.charcoal"),
        Cosmetic(id: "felt.burgundy", kind: .tableFelt, name: "Burgundy", price: 900, assetName: "felt.burgundy"),
        Cosmetic(id: "felt.teal", kind: .tableFelt, name: "Teal", price: 900, assetName: "felt.teal"),
        Cosmetic(id: "felt.sunset", kind: .tableFelt, name: "Sunset", price: 1500, assetName: "felt.sunset"),
        Cosmetic(id: "felt.midnightGold", kind: .tableFelt, name: "Midnight Gold", price: 2500, assetName: "felt.midnightGold"),

        Cosmetic(id: "chips.classic", kind: .chipSet, name: "Classic Chips", price: 0, assetName: "chips.classic"),
        Cosmetic(id: "chips.neon", kind: .chipSet, name: "Neon", price: 900, assetName: "chips.neon"),
        Cosmetic(id: "chips.marble", kind: .chipSet, name: "Marble", price: 1800, assetName: "chips.marble"),
        Cosmetic(id: "chips.jade", kind: .chipSet, name: "Jade", price: 1800, assetName: "chips.jade"),
        Cosmetic(id: "chips.sapphire", kind: .chipSet, name: "Sapphire", price: 2200, assetName: "chips.sapphire"),
        Cosmetic(id: "chips.diamond", kind: .chipSet, name: "Diamond", price: 4000, assetName: "chips.diamond"),

        Cosmetic(id: "avatar.default", kind: .avatar, name: "Default", price: 0, assetName: "avatar.default"),
        Cosmetic(id: "avatar.shark", kind: .avatar, name: "Shark", price: 400, assetName: "avatar.shark"),
        Cosmetic(id: "avatar.robot", kind: .avatar, name: "Robot", price: 400, assetName: "avatar.robot"),
        Cosmetic(id: "avatar.fox", kind: .avatar, name: "Fox", price: 600, assetName: "avatar.fox"),
        Cosmetic(id: "avatar.wizard", kind: .avatar, name: "Wizard", price: 900, assetName: "avatar.wizard"),
        Cosmetic(id: "avatar.astronaut", kind: .avatar, name: "Astronaut", price: 1200, assetName: "avatar.astronaut"),
        Cosmetic(id: "avatar.dragon", kind: .avatar, name: "Dragon", price: 2000, assetName: "avatar.dragon"),
        Cosmetic(id: "avatar.crown", kind: .avatar, name: "High Roller", price: 3000, assetName: "avatar.crown"),
    ]

    static func items(of kind: CosmeticKind) -> [Cosmetic] {
        all.filter { $0.kind == kind }
    }

    static func item(id: String) -> Cosmetic? {
        all.first { $0.id == id }
    }
}
