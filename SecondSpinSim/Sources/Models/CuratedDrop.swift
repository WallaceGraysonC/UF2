import Foundation

/// A Drop in prep. Curators pour Design and Hype into it across the prep
/// cycle; it "ships" on the last day and gets written up.
struct CuratedDrop: Identifiable, Codable {
    var id = UUID()
    /// What the player calls it on the poster in the window.
    var name: String
    var theme: DropTheme
    var angle: DropAngle
    var curatorIDs: [UUID]
    var daysRemaining: Int
    var totalDays: Int

    /// Accumulated across prep days, not granted all at once — the points
    /// system from the design reference.
    var designPoints: Double = 0
    var hypePoints: Double = 0

    var affinity: ComboAffinity { DropCombo.affinity(theme: theme, angle: angle) }

    init(name: String, theme: DropTheme, angle: DropAngle, curatorIDs: [UUID]) {
        self.name = name.isEmpty ? theme.rawValue : name
        self.theme = theme
        self.angle = angle
        self.curatorIDs = curatorIDs
        self.daysRemaining = theme.prepDays
        self.totalDays = theme.prepDays
    }

    var dayLabel: String { "PREP \(totalDays - daysRemaining + 1)/\(totalDays)" }
    var progress: Double {
        guard totalDays > 0 else { return 0 }
        return Double(totalDays - daysRemaining) / Double(totalDays)
    }
}

/// The write-up — the Kairosoft "review score" beat, scaled to how well the
/// curation met what the theme promised.
struct DropResult: Identifiable, Codable {
    var id = UUID()
    var themeName: String
    var day: Int
    var turnout: Int
    var stars: Int
    var revenue: Int
    var repGains: [CustomerArchetype: Int]
    var review: String

    static func review(stars: Int, themeName: String) -> String {
        switch stars {
        case 5: return "\"Best night this shop has ever thrown. \(themeName) was the real thing.\""
        case 4: return "\"\(themeName) delivered. Went home with more than I meant to.\""
        case 3: return "\"Decent turnout, decent racks. \(themeName) did the job.\""
        case 2: return "\"Thin. \(themeName) promised more than the shelves had.\""
        default: return "\"Nobody had prepped a thing. Skip \(themeName) next time.\""
        }
    }
}
