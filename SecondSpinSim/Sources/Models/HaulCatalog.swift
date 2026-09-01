import Foundation

/// The pool of stock that can turn up in a haul. Titles are invented so the
/// shop reads as a real used-media store without leaning on real catalogue.
enum HaulCatalog {

    struct Entry {
        var title: String
        var baseValue: Int
        /// Only ever appears as a rare pull.
        var grailOnly: Bool = false
    }

    static func entries(for format: MediaFormat) -> [Entry] {
        switch format {
        case .vinyl:
            return [
                Entry(title: "The Bitter Ends — Coastal Static", baseValue: 14),
                Entry(title: "Marguerite Vale — Night Ferry", baseValue: 22),
                Entry(title: "Hollow Transit — Second Shift", baseValue: 9),
                Entry(title: "The Ozone Brothers — Dial Tone", baseValue: 18),
                Entry(title: "Sable Union — Wire & Water", baseValue: 26),
                Entry(title: "Junior Aster — Test Pressing", baseValue: 140, grailOnly: true),
                Entry(title: "Cold Kitchen — s/t (first press)", baseValue: 210, grailOnly: true)
            ]
        case .cd:
            return [
                Entry(title: "Pale Arcade — Overexposed", baseValue: 7),
                Entry(title: "Vermillion Set — Long Division", baseValue: 11),
                Entry(title: "The Trouble Ledger — Housefire", baseValue: 6),
                Entry(title: "Nine Mile Radio — Anthology", baseValue: 15),
                Entry(title: "Kestrel Park — Japanese import", baseValue: 95, grailOnly: true)
            ]
        case .vhs:
            return [
                Entry(title: "Graveyard Shift (clamshell)", baseValue: 12),
                Entry(title: "Neon Harbor", baseValue: 9),
                Entry(title: "The Long Weekend", baseValue: 14),
                Entry(title: "Killdozer '84 (rental sleeve)", baseValue: 20),
                Entry(title: "Blood Meridian Drive-In (pre-cert)", baseValue: 260, grailOnly: true),
                Entry(title: "Sealed — Cabin Fever Nights", baseValue: 180, grailOnly: true)
            ]
        case .game:
            return [
                Entry(title: "Tower of Glass (cart only)", baseValue: 24),
                Entry(title: "Rift Runner 2", baseValue: 38),
                Entry(title: "Moonlight Brigade (CIB)", baseValue: 65),
                Entry(title: "Pocket Kingdom", baseValue: 19),
                Entry(title: "Astral Saga (PAL, sealed)", baseValue: 420, grailOnly: true)
            ]
        case .laserdisc:
            return [
                Entry(title: "The Quiet Coast — LD boxset", baseValue: 32),
                Entry(title: "Ronin Hour (widescreen LD)", baseValue: 26),
                Entry(title: "Night Tide — Criterion LD", baseValue: 190, grailOnly: true),
                Entry(title: "Solaris Drift — signed jacket", baseValue: 240, grailOnly: true)
            ]
        }
    }

    /// Rolls one item for a haul at the given location.
    static func roll(format: MediaFormat, isRare: Bool, condition: Double) -> InventoryItem {
        let pool = entries(for: format)
        let candidates = pool.filter { $0.grailOnly == isRare }
        // Fall back to the whole pool if a format has no entry of that kind.
        let entry = (candidates.isEmpty ? pool : candidates).randomElement()
            ?? Entry(title: "Unsorted lot", baseValue: 5)

        return InventoryItem(
            title: entry.title,
            format: format,
            grade: ConditionGrade(value: condition),
            baseValue: entry.baseValue,
            isRare: isRare
        )
    }
}
