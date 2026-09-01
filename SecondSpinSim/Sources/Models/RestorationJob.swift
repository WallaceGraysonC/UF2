import Foundation

/// One item sitting on the Backroom Bench — grading in from Sourcing at
/// `startGrade`, climbing toward `mint` as `progress` fills.
struct RestorationJob: Identifiable {
    let id = UUID()
    var itemName: String
    var format: MediaFormat
    var startGrade: ConditionGrade
    /// 0...1 toward the next grade band. Diminishing returns near Mint are a
    /// balance concern (bigger steps needed higher up), not modeled here yet.
    var progress: Double
    var assignedTechName: String?
}
