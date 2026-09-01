import Foundation

/// One item sitting on the Backroom Bench, climbing grade bands as an
/// assigned Tech pours Restoration points into it.
struct RestorationJob: Identifiable, Codable {
    var id = UUID()
    var itemName: String
    var format: MediaFormat
    var grade: ConditionGrade
    /// 0...1 toward the next grade band.
    var progress: Double
    var assignedTechID: UUID?

    /// Points needed per band climb rise sharply near Mint — restoring a
    /// beat copy to Good is quick, pushing Near Mint to Mint is not.
    var effortMultiplier: Double {
        switch grade {
        case .poor, .fair: return 1.0
        case .good: return 1.4
        case .veryGood: return 2.2
        case .nearMint: return 3.5
        case .mint: return .infinity
        }
    }

    static func starterJobs() -> [RestorationJob] {
        [
            RestorationJob(itemName: "Blondie — Parallel Lines", format: .vinyl,
                           grade: .good, progress: 0.7, assignedTechID: nil),
            RestorationJob(itemName: "Night Tide (Criterion LD)", format: .laserdisc,
                           grade: .fair, progress: 0.3, assignedTechID: nil),
            RestorationJob(itemName: "Chrono Trigger (cart only)", format: .game,
                           grade: .poor, progress: 0.1, assignedTechID: nil)
        ]
    }
}
