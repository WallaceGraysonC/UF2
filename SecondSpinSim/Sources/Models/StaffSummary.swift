import Foundation

/// Lightweight view-model for a staffer shown on a project screen —
/// not the eventual persisted Staff model, just enough to render a chip.
struct StaffSummary: Identifiable {
    let id = UUID()
    var name: String
    var role: String
    /// 0...1, drives the mini stat bar for whichever stat is relevant to this project.
    var statValue: Double
}
