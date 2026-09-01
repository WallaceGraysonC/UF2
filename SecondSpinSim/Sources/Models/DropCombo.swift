import SwiftUI

/// How well a theme and an angle go together — the combination lookup that
/// Game Dev Story runs on genre x topic. The multiplier lands on Design
/// points, so a perfect pairing is worth more than an extra curator, and a
/// clash can sink a Drop no amount of staffing rescues.
enum ComboAffinity: Int, CaseIterable {
    case clash, weak, fine, strong, perfect

    var multiplier: Double {
        switch self {
        case .clash: return 0.45
        case .weak: return 0.7
        case .fine: return 1.0
        case .strong: return 1.25
        case .perfect: return 1.5
        }
    }

    var label: String {
        switch self {
        case .clash: return "CLASH"
        case .weak: return "WEAK"
        case .fine: return "FINE"
        case .strong: return "STRONG"
        case .perfect: return "PERFECT"
        }
    }

    var color: Color {
        switch self {
        case .clash: return Theme.red
        case .weak: return Color(hex: 0xC98A3E)
        case .fine: return Theme.inkSoft
        case .strong: return Theme.green
        case .perfect: return Theme.teal
        }
    }
}

enum DropCombo {

    /// Each theme names the angles it loves and the ones that fight it.
    /// Anything unlisted is a serviceable, unremarkable pairing.
    static func affinity(theme: DropTheme, angle: DropAngle) -> ComboAffinity {
        switch theme {
        case .horrorNight:
            switch angle {
            case .slasher: return .perfect
            case .cultSciFi: return .strong
            case .soundtracks: return .strong
            case .sealedAndGraded: return .weak
            case .localBands: return .clash
            case .oneHitWonders: return .clash
            default: return .fine
            }

        case .breakbeatWall:
            switch angle {
            case .deepCuts: return .perfect
            case .soundtracks: return .strong
            case .imports: return .strong
            case .oneHitWonders: return .weak
            case .sealedAndGraded: return .clash
            case .slasher: return .clash
            default: return .fine
            }

        case .importShelf:
            switch angle {
            case .imports: return .perfect
            case .sealedAndGraded: return .strong
            case .cultSciFi: return .strong
            case .localBands: return .clash
            case .oneHitWonders: return .weak
            default: return .fine
            }

        case .staffPicks:
            switch angle {
            case .localBands: return .perfect
            case .deepCuts: return .strong
            case .oneHitWonders: return .strong
            case .sealedAndGraded: return .weak
            case .imports: return .weak
            default: return .fine
            }

        case .listeningParty:
            switch angle {
            case .deepCuts: return .perfect
            case .localBands: return .strong
            case .soundtracks: return .strong
            case .sealedAndGraded: return .clash
            case .slasher: return .weak
            default: return .fine
            }
        }
    }

    /// Stable key for remembering which pairings the player has already run.
    static func key(theme: DropTheme, angle: DropAngle) -> String {
        "\(theme.rawValue)|\(angle.rawValue)"
    }
}
