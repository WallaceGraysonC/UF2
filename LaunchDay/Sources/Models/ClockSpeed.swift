import Foundation

/// The three clock speeds offered on the floor.
enum ClockSpeed: String, CaseIterable, Identifiable {
    case steady, brisk, fast

    var id: String { rawValue }

    var secondsPerDay: Double {
        switch self {
        case .steady: return 1.6
        case .brisk: return 0.8
        case .fast: return 0.35
        }
    }

    var label: String {
        switch self {
        case .steady: return "1x"
        case .brisk: return "2x"
        case .fast: return "4x"
        }
    }
}
