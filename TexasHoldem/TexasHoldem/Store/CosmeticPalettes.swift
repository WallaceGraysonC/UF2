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
