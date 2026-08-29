import SwiftUI

/// Shared color lookups so card backs and table felt render consistently
/// wherever they're shown (table, store swatches, seat cards).
enum CardBackPalette {
    static func color(for id: String) -> Color {
        switch id {
        case "cardback.crimson": return .red
        case "cardback.midnight": return .indigo
        case "cardback.forest": return Color(red: 0.05, green: 0.4, blue: 0.2)
        case "cardback.violet": return Color(red: 0.45, green: 0.2, blue: 0.65)
        case "cardback.copper": return Color(red: 0.6, green: 0.35, blue: 0.15)
        case "cardback.gold": return .yellow
        case "cardback.holographic": return Color(red: 0.55, green: 0.8, blue: 0.95)
        default: return .blue
        }
    }
}

enum FeltPalette {
    static func color(for id: String) -> Color {
        switch id {
        case "felt.royalBlue": return Color(red: 0.10, green: 0.22, blue: 0.55)
        case "felt.charcoal": return Color(red: 0.18, green: 0.18, blue: 0.2)
        case "felt.burgundy": return Color(red: 0.4, green: 0.08, blue: 0.15)
        case "felt.teal": return Color(red: 0.05, green: 0.35, blue: 0.35)
        case "felt.sunset": return Color(red: 0.55, green: 0.22, blue: 0.15)
        case "felt.midnightGold": return Color(red: 0.12, green: 0.1, blue: 0.05)
        default: return Color(red: 0.05, green: 0.4, blue: 0.22)
        }
    }
}

/// The wood/trim rail around the table -- a separate cosmetic slot from the
/// felt itself, so the two can be mixed and matched.
enum RailPalette {
    static func gradient(for id: String) -> LinearGradient {
        let (top, bottom) = colors(for: id)
        return LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }

    static func seamColor(for id: String) -> Color {
        switch id {
        case "rail.roseGold": return Color(red: 0.90, green: 0.60, blue: 0.55)
        case "rail.carbonFiber": return Color(red: 0.55, green: 0.55, blue: 0.6)
        case "rail.platinum": return Color(red: 0.85, green: 0.87, blue: 0.9)
        case "rail.crimsonLeather": return Color(red: 0.75, green: 0.25, blue: 0.3)
        default: return PATheme.gold
        }
    }

    private static func colors(for id: String) -> (Color, Color) {
        switch id {
        case "rail.darkWalnut":
            return (Color(red: 0.22, green: 0.13, blue: 0.07), Color(red: 0.12, green: 0.07, blue: 0.04))
        case "rail.ebony":
            return (Color(red: 0.14, green: 0.12, blue: 0.11), Color(red: 0.04, green: 0.03, blue: 0.03))
        case "rail.crimsonLeather":
            return (Color(red: 0.35, green: 0.08, blue: 0.10), Color(red: 0.18, green: 0.03, blue: 0.05))
        case "rail.roseGold":
            return (Color(red: 0.72, green: 0.45, blue: 0.42), Color(red: 0.45, green: 0.26, blue: 0.24))
        case "rail.carbonFiber":
            return (Color(red: 0.20, green: 0.20, blue: 0.22), Color(red: 0.06, green: 0.06, blue: 0.07))
        case "rail.platinum":
            return (Color(red: 0.75, green: 0.77, blue: 0.80), Color(red: 0.50, green: 0.52, blue: 0.55))
        default: // rail.classicOak
            return (Color(red: 0.32, green: 0.19, blue: 0.09), Color(red: 0.17, green: 0.10, blue: 0.05))
        }
    }
}

/// The room/scene rendered behind the table itself -- a separate cosmetic
/// slot from the felt and rail, so the whole screen (not just the table)
/// can be restyled.
enum BackdropPalette {
    static func gradient(for id: String) -> RadialGradient {
        let (glow, deep) = colors(for: id)
        return RadialGradient(colors: [glow, deep, .black],
                               center: UnitPoint(x: 0.5, y: 0.32), startRadius: 10, endRadius: 700)
    }

    private static func colors(for id: String) -> (Color, Color) {
        switch id {
        case "backdrop.casinoFloor":
            return (Color(red: 0.35, green: 0.22, blue: 0.08), Color(red: 0.14, green: 0.09, blue: 0.03))
        case "backdrop.velvetLounge":
            return (Color(red: 0.28, green: 0.08, blue: 0.32), Color(red: 0.12, green: 0.03, blue: 0.15))
        case "backdrop.sunsetLounge":
            return (Color(red: 0.45, green: 0.18, blue: 0.12), Color(red: 0.18, green: 0.07, blue: 0.05))
        case "backdrop.emeraldRoom":
            return (Color(red: 0.06, green: 0.30, blue: 0.20), Color(red: 0.02, green: 0.12, blue: 0.08))
        case "backdrop.neonNights":
            return (Color(red: 0.05, green: 0.32, blue: 0.38), Color(red: 0.24, green: 0.05, blue: 0.30))
        case "backdrop.royalGold":
            return (Color(red: 0.38, green: 0.30, blue: 0.09), Color(red: 0.15, green: 0.12, blue: 0.03))
        default: // backdrop.midnight
            return (Color(red: 0.11, green: 0.11, blue: 0.12), Color(red: 0.03, green: 0.03, blue: 0.04))
        }
    }
}

/// SF Symbol used to represent an avatar cosmetic, shared between the store
/// swatches and the small icon shown next to a player's name at the table.
enum AvatarPalette {
    static func symbol(for id: String) -> String {
        switch id {
        case "avatar.shark": return "fish.fill"
        case "avatar.robot": return "faceid"
        case "avatar.fox": return "pawprint.fill"
        case "avatar.wizard": return "wand.and.stars"
        case "avatar.astronaut": return "moon.stars.fill"
        case "avatar.dragon": return "flame.fill"
        case "avatar.crown": return "crown.fill"
        default: return "person.circle.fill"
        }
    }
}
