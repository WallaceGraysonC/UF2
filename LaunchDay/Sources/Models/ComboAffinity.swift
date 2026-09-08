import SwiftUI

/// How well a genre and a topic go together. The multiplier lands on every
/// point the team earns during development, so a perfect pairing is worth
/// more than an extra desk, and a clash sinks a project no staffing saves.
enum ComboAffinity: Int, CaseIterable {
    case clash, weak, fine, strong, perfect

    var multiplier: Double {
        switch self {
        case .clash: return 0.5
        case .weak: return 0.75
        case .fine: return 1.0
        case .strong: return 1.3
        case .perfect: return 1.6
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

enum GenreTopicCombo {

    /// Each genre names the topics it loves and the ones that fight it.
    /// Anything unlisted is a serviceable, unremarkable pairing.
    static func affinity(genre: Genre, topic: Topic) -> ComboAffinity {
        switch genre {
        case .action:
            switch topic {
            case .war: return .perfect
            case .horror: return .strong
            case .sciFi: return .strong
            case .music: return .clash
            default: return .fine
            }

        case .rpg:
            switch topic {
            case .fantasy: return .perfect
            case .sciFi: return .strong
            case .war: return .strong
            case .sports: return .clash
            default: return .fine
            }

        case .adventure:
            switch topic {
            case .horror: return .perfect
            case .fantasy: return .strong
            case .sciFi: return .strong
            case .sports: return .weak
            default: return .fine
            }

        case .simulation:
            switch topic {
            case .sports: return .perfect
            case .music: return .strong
            case .war: return .strong
            case .horror: return .clash
            default: return .fine
            }

        case .strategy:
            switch topic {
            case .war: return .perfect
            case .sciFi: return .strong
            case .fantasy: return .strong
            case .music: return .weak
            default: return .fine
            }

        case .puzzle:
            switch topic {
            case .music: return .perfect
            case .fantasy: return .strong
            case .sports: return .strong
            case .war: return .clash
            case .horror: return .weak
            default: return .fine
            }
        }
    }

    static func key(genre: Genre, topic: Topic) -> String {
        "\(genre.rawValue)|\(topic.rawValue)"
    }
}
