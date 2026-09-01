import Foundation

/// One rung of the shop ladder. Every rung above the first demands cash AND
/// headcount AND (often) reputation with a particular crowd at the same time —
/// the compound gating from the design reference, so no single grind clears
/// the whole tree.
struct ShopUpgrade: Identifiable {
    var level: Int
    var id: Int { level }

    var title: String
    var detail: String
    var cash: Int
    var staffRequired: Int
    /// Reputation floor with a specific crowd, on the 0-100 scale.
    var repRequirement: (archetype: CustomerArchetype, value: Int)?
    /// Reputation floor that must hold across at least `count` crowds.
    var breadthRequirement: (value: Int, count: Int)?
    /// A role that must be on the roster (a Tech to run a bench, say).
    var roleRequired: StaffRole?

    static let ladder: [ShopUpgrade] = [
        ShopUpgrade(level: 2, title: "Vinyl Section",
                    detail: "Racks and dividers. Records start turning up in hauls.",
                    cash: 2_000, staffRequired: 2,
                    repRequirement: nil, breadthRequirement: (value: 45, count: 2),
                    roleRequired: nil),

        ShopUpgrade(level: 3, title: "Backroom Bench",
                    detail: "A bench, a sink and a lamp. Restoration work begins.",
                    cash: 3_500, staffRequired: 3,
                    repRequirement: nil, breadthRequirement: nil,
                    roleRequired: .tech),

        ShopUpgrade(level: 4, title: "Games Section",
                    detail: "Locked shelving for carts and discs.",
                    cash: 6_000, staffRequired: 4,
                    repRequirement: (archetype: .completionist, value: 45),
                    breadthRequirement: nil, roleRequired: nil),

        ShopUpgrade(level: 5, title: "Stage & PA",
                    detail: "A corner cleared for live Drops.",
                    cash: 10_000, staffRequired: 5,
                    repRequirement: nil, breadthRequirement: nil,
                    roleRequired: .curator),

        ShopUpgrade(level: 6, title: "Laserdisc & Glass Case",
                    detail: "The locked case. Grails go behind glass.",
                    cash: 18_000, staffRequired: 6,
                    repRequirement: (archetype: .collector, value: 65),
                    breadthRequirement: nil, roleRequired: .tech),

        ShopUpgrade(level: 7, title: "Floor Expansion",
                    detail: "Through the back wall — more shelf, more bench.",
                    cash: 28_000, staffRequired: 7,
                    repRequirement: nil, breadthRequirement: nil,
                    roleRequired: nil),

        ShopUpgrade(level: 8, title: "Memorabilia Case",
                    detail: "Posters, press kits, promo standees.",
                    cash: 42_000, staffRequired: 8,
                    repRequirement: nil, breadthRequirement: (value: 70, count: 3),
                    roleRequired: nil),

        ShopUpgrade(level: 9, title: "Second Location",
                    detail: "A satellite shop across town.",
                    cash: 70_000, staffRequired: 10,
                    repRequirement: nil, breadthRequirement: nil,
                    roleRequired: nil),

        ShopUpgrade(level: 10, title: "Museum Wall",
                    detail: "The pieces that are no longer for sale.",
                    cash: 110_000, staffRequired: 12,
                    repRequirement: nil, breadthRequirement: (value: 80, count: 4),
                    roleRequired: nil)
    ]

    static func upgrade(toReach level: Int) -> ShopUpgrade? {
        ladder.first { $0.level == level }
    }
}

/// One checkable line on the upgrade sheet.
struct UpgradeRequirement: Identifiable {
    let id = UUID()
    var label: String
    var met: Bool
}
