import Foundation

/// Which market a project targets. Unlike genre×topic, fit is shown up
/// front rather than discovered — you'd know a racing game suits a console
/// before you start, the way a real studio would.
enum Platform: String, CaseIterable, Identifiable, Codable {
    case handheld = "Handheld"
    case homeConsole = "Home Console"
    case computer = "Computer"

    var id: String { rawValue }

    /// Paid up front, on top of the project's own dev cost — the licence fee.
    var entryFee: Int {
        switch self {
        case .handheld: return 80
        case .homeConsole: return 260
        case .computer: return 40
        }
    }

    /// Baseline reach of this market, before genre fit is applied.
    var salesMultiplier: Double {
        switch self {
        case .handheld: return 0.85
        case .homeConsole: return 1.3
        case .computer: return 1.0
        }
    }

    /// Office level required before this platform can be targeted — the
    /// console licence is the one gated behind actually being established.
    var unlockLevel: Int {
        switch self {
        case .handheld, .computer: return 1
        case .homeConsole: return 2
        }
    }

    var blurb: String {
        switch self {
        case .handheld: return "Small screen, always in someone's pocket. Cheap to enter."
        case .homeConsole: return "The living room. Costly licence, the biggest ceiling."
        case .computer: return "No gatekeeper, no licence fee, an audience that already loves genre work."
        }
    }

    /// How well a genre suits this platform — visible, not hidden.
    func fit(for genre: Genre) -> Double {
        switch self {
        case .handheld:
            switch genre {
            case .puzzle: return 1.5
            case .adventure: return 1.25
            case .strategy: return 0.7
            default: return 1.0
            }
        case .homeConsole:
            switch genre {
            case .action: return 1.5
            case .rpg: return 1.3
            case .puzzle: return 0.7
            default: return 1.0
            }
        case .computer:
            switch genre {
            case .strategy: return 1.5
            case .simulation: return 1.4
            case .action: return 0.8
            default: return 1.0
            }
        }
    }

    /// A short label for the fit, for the picker.
    func fitLabel(for genre: Genre) -> String {
        switch fit(for: genre) {
        case 1.4...: return "GREAT FIT"
        case 1.15..<1.4: return "GOOD FIT"
        case ..<0.85: return "POOR FIT"
        default: return "OKAY FIT"
        }
    }
}
