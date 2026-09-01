import SwiftUI

/// Reputation is tracked per archetype rather than as one global meter —
/// a shop known to collectors is a different shop than one known to DJs.
enum CustomerArchetype: String, CaseIterable, Identifiable, Codable {
    case collector = "Collector"
    case crateDigger = "Crate-Digger"
    case completionist = "Completionist"
    case nostalgic = "Nostalgic"
    case reseller = "Reseller"
    case casual = "Casual"

    var id: String { rawValue }

    /// Formats this archetype actually shops for — drives sale odds.
    var preferredFormats: Set<MediaFormat> {
        switch self {
        case .collector: return [.vinyl, .laserdisc]
        case .crateDigger: return [.vinyl, .cd]
        case .completionist: return [.game, .vhs]
        case .nostalgic: return [.vhs, .game]
        case .reseller: return Set(MediaFormat.allCases)
        case .casual: return [.cd, .vhs]
        }
    }

    /// What this archetype pays relative to asking price.
    var priceMultiplier: Double {
        switch self {
        case .collector: return 1.15
        case .crateDigger: return 1.0
        case .completionist: return 1.05
        case .nostalgic: return 0.95
        case .reseller: return 0.6
        case .casual: return 0.9
        }
    }

    var color: Color {
        switch self {
        case .collector: return Theme.plum
        case .crateDigger: return Theme.steel
        case .completionist: return Theme.green
        case .nostalgic: return Theme.amber
        case .reseller: return Theme.red
        case .casual: return Theme.teal
        }
    }
}
