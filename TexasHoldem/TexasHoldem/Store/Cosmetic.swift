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
        Cosmetic(id: "cardback.gold", kind: .cardBack, name: "Gold Foil", price: 2000, assetName: "cardback.gold"),

        Cosmetic(id: "felt.classicGreen", kind: .tableFelt, name: "Classic Green", price: 0, assetName: "felt.classicGreen"),
        Cosmetic(id: "felt.royalBlue", kind: .tableFelt, name: "Royal Blue", price: 600, assetName: "felt.royalBlue"),
        Cosmetic(id: "felt.charcoal", kind: .tableFelt, name: "Charcoal", price: 600, assetName: "felt.charcoal"),
        Cosmetic(id: "felt.sunset", kind: .tableFelt, name: "Sunset", price: 1500, assetName: "felt.sunset"),

        Cosmetic(id: "chips.classic", kind: .chipSet, name: "Classic Chips", price: 0, assetName: "chips.classic"),
        Cosmetic(id: "chips.neon", kind: .chipSet, name: "Neon", price: 900, assetName: "chips.neon"),
        Cosmetic(id: "chips.marble", kind: .chipSet, name: "Marble", price: 1800, assetName: "chips.marble"),

        Cosmetic(id: "avatar.default", kind: .avatar, name: "Default", price: 0, assetName: "avatar.default"),
        Cosmetic(id: "avatar.shark", kind: .avatar, name: "Shark", price: 400, assetName: "avatar.shark"),
        Cosmetic(id: "avatar.robot", kind: .avatar, name: "Robot", price: 400, assetName: "avatar.robot"),
        Cosmetic(id: "avatar.crown", kind: .avatar, name: "High Roller", price: 3000, assetName: "avatar.crown"),
    ]

    static func items(of kind: CosmeticKind) -> [Cosmetic] {
        all.filter { $0.kind == kind }
    }

    static func item(id: String) -> Cosmetic? {
        all.first { $0.id == id }
    }
}
