import Foundation

/// A single piece of stock. Price follows the design reference's formula:
/// base × condition × rarity × trend.
struct InventoryItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var format: MediaFormat
    var grade: ConditionGrade
    var baseValue: Int
    var isRare: Bool = false
    /// True once it's out of the back room and actually on a shelf.
    var isShelved: Bool = true

    var conditionMultiplier: Double {
        switch grade {
        case .poor: return 0.25
        case .fair: return 0.45
        case .good: return 0.7
        case .veryGood: return 1.0
        case .nearMint: return 1.4
        case .mint: return 1.8
        }
    }

    var rarityMultiplier: Double { isRare ? 3.2 : 1.0 }

    /// What the item is marked at on the shelf.
    func askingPrice(trendModifier: Double = 1.0) -> Int {
        Int((Double(baseValue) * conditionMultiplier * rarityMultiplier * trendModifier).rounded())
    }

    static func starterStock() -> [InventoryItem] {
        [
            InventoryItem(title: "Blondie — Parallel Lines", format: .vinyl, grade: .good, baseValue: 22),
            InventoryItem(title: "Steely Dan — Aja", format: .vinyl, grade: .veryGood, baseValue: 18),
            InventoryItem(title: "Fugazi — Repeater", format: .cd, grade: .nearMint, baseValue: 12),
            InventoryItem(title: "Portishead — Dummy", format: .cd, grade: .good, baseValue: 10),
            InventoryItem(title: "The Warriors (clamshell)", format: .vhs, grade: .veryGood, baseValue: 16),
            InventoryItem(title: "Suspiria (pre-cert)", format: .vhs, grade: .good, baseValue: 40, isRare: true),
            InventoryItem(title: "Chrono Trigger (cart)", format: .game, grade: .fair, baseValue: 65),
            InventoryItem(title: "Panzer Dragoon Saga", format: .game, grade: .good, baseValue: 90, isRare: true)
        ]
    }
}
