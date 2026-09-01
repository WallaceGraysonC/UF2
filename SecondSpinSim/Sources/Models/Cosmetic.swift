import SwiftUI

/// What part of the shop a cosmetic redresses.
enum CosmeticSlot: String, CaseIterable, Identifiable, Codable {
    case floor = "Floor"
    case walls = "Walls"
    case sign = "Sign"
    case counter = "Counter"

    var id: String { rawValue }
}

/// What you have to do to earn a cosmetic. Conditions are checked against the
/// legacy profile, so they persist across runs.
enum UnlockCondition: Codable, Equatable {
    /// Available from the start.
    case fromTheStart
    /// Closed up shop this many times.
    case prestigeCount(Int)
    /// Reached this shop level in any single run.
    case reachedLevel(Int)
    /// Sold one item for at least this much.
    case soldGrailWorth(Int)
    /// This many pieces mounted on the Museum Wall, across all runs.
    case museumPieces(Int)
    /// This many staff sent to a convention, across all runs.
    case staffTrained(Int)
    /// This many 5-star Drop write-ups.
    case fiveStarDrops(Int)
    /// Closed up shop with less than this in the till.
    case retiredBroke(Int)

    var describe: String {
        switch self {
        case .fromTheStart: return "Available from the start"
        case .prestigeCount(let n): return n == 1 ? "Close up shop once" : "Close up shop \(n) times"
        case .reachedLevel(let n): return "Reach shop level \(n)"
        case .soldGrailWorth(let n): return "Sell a single item for $\(n)"
        case .museumPieces(let n): return "Mount \(n) pieces on the Museum Wall"
        case .staffTrained(let n): return "Send \(n) staff to conventions"
        case .fiveStarDrops(let n): return "Earn \(n) five-star write-ups"
        case .retiredBroke(let n): return "Close up shop with under $\(n) to your name"
        }
    }
}

struct Cosmetic: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var slot: CosmeticSlot
    var flavour: String
    var unlock: UnlockCondition
    /// Secret cosmetics don't appear in the gallery until earned — the reward
    /// is partly the surprise.
    var isSecret: Bool = false
    /// Stored as a hex value so the whole catalog stays Codable.
    var hex: UInt32

    var color: Color { Color(hex: hex) }
}

/// The four equipped colours, resolved once and handed to the floor so the
/// shop screens don't each have to reach for the legacy profile.
struct ShopSkin {
    var floor: Color
    var walls: Color
    var sign: Color
    var counter: Color

    static let `default` = ShopSkin(
        floor: CosmeticCatalog.starter(for: .floor).color,
        walls: CosmeticCatalog.starter(for: .walls).color,
        sign: CosmeticCatalog.starter(for: .sign).color,
        counter: CosmeticCatalog.starter(for: .counter).color
    )

    init(floor: Color, walls: Color, sign: Color, counter: Color) {
        self.floor = floor
        self.walls = walls
        self.sign = sign
        self.counter = counter
    }

    init(profile: LegacyProfile) {
        floor = profile.equippedCosmetic(in: .floor).color
        walls = profile.equippedCosmetic(in: .walls).color
        sign = profile.equippedCosmetic(in: .sign).color
        counter = profile.equippedCosmetic(in: .counter).color
    }
}

enum CosmeticCatalog {

    static let all: [Cosmetic] = [
        // --- Floor ---
        Cosmetic(id: "floor.checker", name: "Checkerboard Tile", slot: .floor,
                 flavour: "Cracked in two places. Nobody minds.",
                 unlock: .fromTheStart, hex: 0xDCD5C1),
        Cosmetic(id: "floor.carpet", name: "Worn Red Carpet", slot: .floor,
                 flavour: "Sticky near the listening booth.",
                 unlock: .reachedLevel(4), hex: 0x8E4A44),
        Cosmetic(id: "floor.parquet", name: "Parquet", slot: .floor,
                 flavour: "Somebody sanded this by hand.",
                 unlock: .prestigeCount(1), hex: 0xB07A3E),
        Cosmetic(id: "floor.concrete", name: "Sealed Concrete", slot: .floor,
                 flavour: "Industrial. The DJs approve.",
                 unlock: .museumPieces(3), hex: 0x8C8C88),
        Cosmetic(id: "floor.astroturf", name: "Astroturf", slot: .floor,
                 flavour: "An unexplainable decision you stand by.",
                 unlock: .prestigeCount(3), isSecret: true, hex: 0x4E8A4A),

        // --- Walls ---
        Cosmetic(id: "wall.brick", name: "Painted Brick", slot: .walls,
                 flavour: "Six coats deep and still showing through.",
                 unlock: .fromTheStart, hex: 0xC6BCA6),
        Cosmetic(id: "wall.panel", name: "Wood Panelling", slot: .walls,
                 flavour: "Basement rec-room energy. Complimentary.",
                 unlock: .reachedLevel(6), hex: 0x7A5433),
        Cosmetic(id: "wall.posters", name: "Papered in Posters", slot: .walls,
                 flavour: "Every inch. Some of them are worth more than the stock.",
                 unlock: .staffTrained(6), hex: 0x6B4A70),
        Cosmetic(id: "wall.black", name: "Blacked Out", slot: .walls,
                 flavour: "Matte black, everywhere. Very serious shop.",
                 unlock: .prestigeCount(1), hex: 0x24242A),
        Cosmetic(id: "wall.foil", name: "Foil Wallpaper", slot: .walls,
                 flavour: "Recovered from a closed-down arcade.",
                 unlock: .soldGrailWorth(500), isSecret: true, hex: 0xB89A5C),

        // --- Sign ---
        Cosmetic(id: "sign.painted", name: "Hand-Painted Board", slot: .sign,
                 flavour: "Your handwriting. It shows.",
                 unlock: .fromTheStart, hex: 0xB87A1E),
        Cosmetic(id: "sign.neon", name: "Neon", slot: .sign,
                 flavour: "Hums at a frequency you stopped hearing months ago.",
                 unlock: .prestigeCount(1), hex: 0xD8536F),
        Cosmetic(id: "sign.marquee", name: "Marquee Letters", slot: .sign,
                 flavour: "Changeable. You change it weekly. Nobody reads it.",
                 unlock: .prestigeCount(2), hex: 0xE0C05A),
        Cosmetic(id: "sign.backlit", name: "Backlit Box", slot: .sign,
                 flavour: "Professional. Almost too professional.",
                 unlock: .fiveStarDrops(3), hex: 0x4F9C93),
        Cosmetic(id: "sign.broken", name: "Half-Dead Neon", slot: .sign,
                 flavour: "Reads 'SEC ND SPI'. You've grown fond of it.",
                 unlock: .retiredBroke(100), isSecret: true, hex: 0x7A3B4A),

        // --- Counter ---
        Cosmetic(id: "counter.formica", name: "Formica", slot: .counter,
                 flavour: "Wiped down twice daily since day one.",
                 unlock: .fromTheStart, hex: 0xB98A4C),
        Cosmetic(id: "counter.glass", name: "Glass Case", slot: .counter,
                 flavour: "For the things that don't go on open shelves.",
                 unlock: .museumPieces(1), hex: 0x6F97A8),
        Cosmetic(id: "counter.reclaimed", name: "Reclaimed Bar Top", slot: .counter,
                 flavour: "Came out of a pub that closed in '91.",
                 unlock: .reachedLevel(7), hex: 0x6B4526),
        Cosmetic(id: "counter.steel", name: "Brushed Steel", slot: .counter,
                 flavour: "Cold to lean on. Easy to clean.",
                 unlock: .prestigeCount(2), hex: 0x8A8F94)
    ]

    static func cosmetic(id: String) -> Cosmetic? {
        all.first { $0.id == id }
    }

    static func inSlot(_ slot: CosmeticSlot) -> [Cosmetic] {
        all.filter { $0.slot == slot }
    }

    /// The one equipped by default in each slot.
    static func starter(for slot: CosmeticSlot) -> Cosmetic {
        inSlot(slot).first { $0.unlock == .fromTheStart } ?? all[0]
    }
}
