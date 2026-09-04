import SwiftUI

/// Shared color and material tokens for the app's "card room" visual
/// language -- gradient-lit gold and card stock instead of flat fills, used
/// across the logo, table, and UI chrome so the whole app reads as one
/// material world instead of a collection of flat-colored screens.
enum BJTheme {
    // Felt / background
    static let feltGlow = Color(red: 0.071, green: 0.239, blue: 0.161)   // #123d29
    static let feltDeep = Color(red: 0.031, green: 0.141, blue: 0.098)   // #082419
    static let feltDeeper = Color(red: 0.016, green: 0.075, blue: 0.047) // #04130c

    // Gold / metal
    static let goldBright = Color(red: 0.910, green: 0.784, blue: 0.478) // #e7c97a
    static let gold = Color(red: 0.796, green: 0.627, blue: 0.275)       // #cba046
    static let goldDeep = Color(red: 0.486, green: 0.369, blue: 0.141)   // #7c5e24

    // Card stock
    static let creamBright = Color(red: 0.992, green: 0.965, blue: 0.906) // #fdf6e7
    static let cream = Color(red: 0.945, green: 0.906, blue: 0.824)       // #f1e7d2
    static let creamDeep = Color(red: 0.863, green: 0.792, blue: 0.639)   // #dccaa3

    // Ink / suits
    static let ink = Color(red: 0.090, green: 0.071, blue: 0.031)         // #171208
    static let crimson = Color(red: 0.639, green: 0.173, blue: 0.239)     // #a32c3e
    static let crimsonDeep = Color(red: 0.561, green: 0.122, blue: 0.188) // #8f1f30

    static var feltBackground: RadialGradient {
        RadialGradient(colors: [feltGlow, feltDeep, feltDeeper],
                        center: UnitPoint(x: 0.42, y: 0.3), startRadius: 10, endRadius: 640)
    }

    static var goldMaterial: LinearGradient {
        LinearGradient(colors: [goldBright, gold, goldDeep], startPoint: .top, endPoint: .bottom)
    }

    static var cardMaterial: LinearGradient {
        LinearGradient(colors: [creamBright, cream, creamDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// A card-back material derived from a cosmetic's base color, so every
    /// card back gets the same gradient sheen as the front of the deck.
    static func cardBackMaterial(base: Color) -> LinearGradient {
        LinearGradient(colors: [base.opacity(0.92), base, base.opacity(0.62)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension View {
    /// Soft directional drop shadow matching the material style used across
    /// cards, chips, and gold surfaces throughout the app.
    func materialShadow(radius: CGFloat = 5, y: CGFloat = 3) -> some View {
        shadow(color: .black.opacity(0.45), radius: radius, x: 0, y: y)
    }
}
