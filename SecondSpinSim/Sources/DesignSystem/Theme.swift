import SwiftUI
import UIKit

/// Shared palette and type scale for Second Spin Sim.
/// Carries the amber/red/green/teal accents established in the design reference,
/// tuned brighter for in-game screens (the design doc runs a muted ledger-paper palette).
enum Theme {

    // MARK: Colors

    static let paper = Color(hex: 0xE9E4D6)
    static let cream = Color(hex: 0xF4EFE2)
    static let ink = Color(hex: 0x211D18)
    static let inkSoft = Color(hex: 0x585143)
    static let line = Color(hex: 0xC9C3AE)

    static let amber = Color(hex: 0xD89A34)
    static let amberDeep = Color(hex: 0xB87A1E)
    static let teal = Color(hex: 0x4F9C93)
    static let plum = Color(hex: 0x8A4A6B)
    static let steel = Color(hex: 0x3E8494)
    static let green = Color(hex: 0x4E8A4A)
    static let red = Color(hex: 0xC24F3C)

    /// Backdrop behind the shop-floor scene — deep, so painted panels pop off it.
    static let stageBackground = Color(hex: 0x131215)

    // MARK: Type

    /// Chunky pixel/display face for titles, buttons, and HUD numbers — the Kairosoft "menu voice."
    /// Backed by Silkscreen (Resources/Fonts, registered via UIAppFonts in project.yml). Falls back
    /// to system rounded bold if the font isn't found — e.g. a preview target that skips resources.
    static func display(_ size: CGFloat, weight: DisplayWeight = .bold) -> Font {
        let name = weight == .bold ? "Silkscreen-Bold" : "Silkscreen-Regular"
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight == .bold ? .bold : .regular, design: .rounded)
    }

    enum DisplayWeight { case regular, bold }

    /// Ledger/mono face for item names, prices, and body copy — keeps the "shop receipt" texture.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
