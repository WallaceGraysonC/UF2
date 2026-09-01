import SwiftUI

/// The physical formats the shop deals in. Order here doubles as unlock order
/// (see the Shop Ladder in the design reference — CD/VHS at open, Vinyl at
/// Level 2, Games at Level 4, Laserdisc at Level 6).
enum MediaFormat: String, CaseIterable, Identifiable {
    case vinyl, cd, vhs, game, laserdisc

    var id: String { rawValue }

    var abbreviation: String {
        switch self {
        case .vinyl: return "LP"
        case .cd: return "CD"
        case .vhs: return "VHS"
        case .game: return "GM"
        case .laserdisc: return "LD"
        }
    }

    var binColor: Color {
        switch self {
        case .vinyl: return Theme.plum
        case .cd: return Theme.steel
        case .vhs: return Theme.amberDeep
        case .game: return Theme.green
        case .laserdisc: return Theme.red
        }
    }
}
