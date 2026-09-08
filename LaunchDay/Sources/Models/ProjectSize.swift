import Foundation

/// How big a swing the project is — more target points and more development
/// time, but a bigger ceiling on the score and the sales that follow.
enum ProjectSize: String, CaseIterable, Identifiable, Codable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }

    var targetPoints: Double {
        switch self {
        case .small: return 260
        case .medium: return 520
        case .large: return 900
        }
    }

    var devDays: Int {
        switch self {
        case .small: return 6
        case .medium: return 10
        case .large: return 16
        }
    }

    var cost: Int {
        switch self {
        case .small: return 150
        case .medium: return 350
        case .large: return 700
        }
    }

    /// A bigger game sells more copies, but only if it's actually good.
    var salesCeiling: Int {
        switch self {
        case .small: return 3_000
        case .medium: return 9_000
        case .large: return 22_000
        }
    }
}
