import SwiftUI
import UIKit

/// Fills a shape with the player's uploaded photo when the equipped id is
/// that category's "Custom Photo" slot and a photo has actually been
/// uploaded; otherwise returns the given built-in fallback style. Shared by
/// every cosmetic category that renders as a filled/stroked shape.
enum CustomCosmeticFill {
    static func style(for id: String, kind: CosmeticKind, fallback: @autoclosure () -> AnyShapeStyle) -> AnyShapeStyle {
        if id == CustomCosmeticStore.customID(for: kind), let image = CustomCosmeticStore.shared.image(for: kind) {
            return AnyShapeStyle(ImagePaint(image: Image(uiImage: image)))
        }
        return fallback()
    }
}

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
        default: return BJTheme.gold
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

/// Renders the room/scene behind the table -- the player's uploaded photo
/// if "Custom Photo" is equipped and one has been uploaded, otherwise the
/// built-in gradient for their equipped backdrop.
struct BackdropView: View {
    let id: String

    var body: some View {
        if id == CustomCosmeticStore.customID(for: .tableBackdrop),
           let image = CustomCosmeticStore.shared.image(for: .tableBackdrop) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            BackdropPalette.gradient(for: id)
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

/// The decorative ring drawn around a player's avatar icon at the table --
/// a separate cosmetic slot from the avatar itself, so any avatar can be
/// framed. "No Frame" renders as fully transparent, i.e. no ring at all.
enum AvatarFramePalette {
    static func stroke(for id: String) -> AnyShapeStyle {
        CustomCosmeticFill.style(for: id, kind: .avatarFrame, fallback: builtInStroke(for: id))
    }

    private static func builtInStroke(for id: String) -> AnyShapeStyle {
        switch id {
        case "frame.silver": return AnyShapeStyle(LinearGradient(colors: [Color(white: 0.9), Color(white: 0.6)], startPoint: .top, endPoint: .bottom))
        case "frame.gold": return AnyShapeStyle(BJTheme.goldMaterial)
        case "frame.sapphire": return AnyShapeStyle(LinearGradient(colors: [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.1, green: 0.2, blue: 0.6)], startPoint: .top, endPoint: .bottom))
        case "frame.crimson": return AnyShapeStyle(LinearGradient(colors: [Color(red: 1.0, green: 0.4, blue: 0.45), Color(red: 0.5, green: 0.05, blue: 0.1)], startPoint: .top, endPoint: .bottom))
        case "frame.royal": return AnyShapeStyle(LinearGradient(colors: [BJTheme.goldBright, Color(red: 0.35, green: 0.1, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
        default: return AnyShapeStyle(Color.clear) // frame.none
        }
    }
}

/// The color of a player's chip stack and the quick-bet chip tokens at the
/// table -- shared between the store swatch and the live betting controls
/// so betting with a chip token always matches the player's equipped set.
enum ChipPalette {
    static func color(for id: String) -> Color {
        switch id {
        case "chips.neon": return .green
        case "chips.marble": return .gray
        case "chips.jade": return Color(red: 0.0, green: 0.6, blue: 0.4)
        case "chips.sapphire": return Color(red: 0.1, green: 0.3, blue: 0.9)
        case "chips.diamond": return .white
        default: return .red // chips.classic
        }
    }
}

/// Rank/suit style on the *front* of every card -- a separate cosmetic slot
/// from the card back. Each style is primarily a distinct ink color theme
/// (the thing players actually notice at a glance), with font as a smaller
/// secondary touch.
enum CardFacePalette {
    static func design(for id: String) -> Font.Design {
        switch id {
        case "face.modern": return .default
        case "face.rounded": return .rounded
        case "face.blockBold": return .monospaced
        default: return .serif // face.classic
        }
    }

    static func weight(for id: String) -> Font.Weight {
        id == "face.blockBold" ? .heavy : .bold
    }

    /// The ink color for a card's rank/suit text -- `isRed` selects the
    /// red-suit half of the theme (hearts/diamonds) vs. the black-suit half.
    static func inkColor(isRed: Bool, for id: String) -> Color {
        switch id {
        case "face.modern":
            return isRed ? Color(red: 0.80, green: 0.10, blue: 0.42) : Color(red: 0.06, green: 0.16, blue: 0.38)
        case "face.rounded":
            return isRed ? Color(red: 0.80, green: 0.38, blue: 0.05) : Color(red: 0.06, green: 0.36, blue: 0.20)
        case "face.blockBold":
            return isRed ? Color(red: 0.88, green: 0.10, blue: 0.55) : Color(red: 0.16, green: 0.05, blue: 0.36)
        default: // face.classic
            return isRed ? BJTheme.crimsonDeep : BJTheme.ink
        }
    }
}
