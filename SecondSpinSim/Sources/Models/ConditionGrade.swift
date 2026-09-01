import SwiftUI

/// The condition bands shown on the grading meter, Poor→Mint — the same
/// scale used across every format's inspection minigame.
enum ConditionGrade: CaseIterable {
    case poor, fair, good, veryGood, nearMint, mint

    /// Buckets a 0...1 inspection value into a grade.
    init(value: Double) {
        switch value {
        case ..<0.2: self = .poor
        case ..<0.4: self = .fair
        case ..<0.6: self = .good
        case ..<0.8: self = .veryGood
        case ..<0.95: self = .nearMint
        default: self = .mint
        }
    }

    var label: String {
        switch self {
        case .poor: return "POOR"
        case .fair: return "FAIR"
        case .good: return "GOOD"
        case .veryGood: return "VERY GOOD"
        case .nearMint: return "NEAR MINT"
        case .mint: return "MINT"
        }
    }

    var color: Color {
        switch self {
        case .poor: return Theme.red
        case .fair: return Color(hex: 0xC98A3E)
        case .good: return Theme.amber
        case .veryGood: return Color(hex: 0x8CA84E)
        case .nearMint: return Theme.green
        case .mint: return Theme.teal
        }
    }
}
