import Foundation

enum BotNames {
    /// Kept to four characters or fewer. A seat is only about as wide as its
    /// two cards, so anything longer either truncates or spills over the
    /// player next to it.
    static let pool = ["Ace", "Chip", "Duke", "Ivy", "Rae", "Jack", "Nova", "Rook",
                       "Slim", "Cash", "Fox", "Kit", "Dice", "Onyx", "Vega", "Zed"]
    private static let avatarPool = ["avatar.shark", "avatar.robot", "avatar.fox", "avatar.wizard", "avatar.astronaut", "avatar.dragon"]
    static func random() -> String { pool.randomElement() ?? "Bot" }
    static func randomAvatar() -> String { avatarPool.randomElement() ?? CosmeticCatalog.defaultAvatar }

    /// Distinct names for one table. Picking independently meant a full
    /// table could easily seat two players with the same name.
    static func randomNames(count: Int) -> [String] {
        guard count > 0 else { return [] }
        var names = pool.shuffled()
        while names.count < count { names += pool.shuffled() }
        return Array(names.prefix(count))
    }
}
