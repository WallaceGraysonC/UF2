import Foundation

/// Paid promotion. The third marketing lever, and deliberately a different
/// shape from the other two: reputation is permanent and per-crowd, a Drop is
/// one big scored event, and advertising is a broad, shallow, temporary lift
/// in people coming through the door.
enum AdMethod: String, CaseIterable, Identifiable, Codable {
    case flyers = "Flyers"
    case zineAd = "Zine Ad"
    case localRadio = "Local Radio Spot"
    case streetTeam = "Street Team"
    case billboard = "Billboard"

    var id: String { rawValue }

    var cost: Int {
        switch self {
        case .flyers: return 60
        case .zineAd: return 140
        case .localRadio: return 320
        case .streetTeam: return 600
        case .billboard: return 1_200
        }
    }

    /// How many days the extra foot traffic lasts.
    var days: Int {
        switch self {
        case .flyers: return 2
        case .zineAd: return 4
        case .localRadio: return 5
        case .streetTeam: return 7
        case .billboard: return 10
        }
    }

    /// Added to every item's chance of selling while the campaign runs.
    var trafficBoost: Double {
        switch self {
        case .flyers: return 0.06
        case .zineAd: return 0.10
        case .localRadio: return 0.15
        case .streetTeam: return 0.20
        case .billboard: return 0.26
        }
    }

    /// A small permanent bump, spread across the crowds this method reaches.
    var repGain: Int {
        switch self {
        case .flyers: return 1
        case .zineAd: return 2
        case .localRadio: return 3
        case .streetTeam: return 4
        case .billboard: return 6
        }
    }

    /// Who actually notices. Cheap methods reach the people already nearby.
    var reaches: [CustomerArchetype] {
        switch self {
        case .flyers: return [.casual, .nostalgic]
        case .zineAd: return [.crateDigger, .collector]
        case .localRadio: return [.casual, .nostalgic, .completionist]
        case .streetTeam: return [.crateDigger, .casual, .completionist]
        case .billboard: return CustomerArchetype.allCases
        }
    }

    var blurb: String {
        switch self {
        case .flyers: return "Stapled to poles within four streets."
        case .zineAd: return "Quarter page, black and white, back of the issue."
        case .localRadio: return "Read out badly between two songs."
        case .streetTeam: return "Six people handing out sampler tapes downtown."
        case .billboard: return "By the overpass. Everybody sees it."
        }
    }
}

/// A campaign currently running.
struct AdCampaign: Identifiable, Codable {
    var id = UUID()
    var method: AdMethod
    var daysRemaining: Int

    init(method: AdMethod) {
        self.method = method
        self.daysRemaining = method.days
    }
}
