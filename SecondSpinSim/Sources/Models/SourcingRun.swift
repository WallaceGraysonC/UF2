import Foundation

/// An in-flight buying trip. Buyers are committed for its duration, and the
/// haul only materialises when it finishes — the "ship day" for inventory.
struct SourcingRun: Identifiable, Codable {
    var id = UUID()
    var location: SourcingLocation
    var buyerIDs: [UUID]
    var daysRemaining: Int
    var totalDays: Int

    /// Accumulated day by day as the crew works, rather than computed in one
    /// go at the end — so the run has point totals you can watch climb.
    var volumePoints: Double = 0
    var rarityPoints: Double = 0
    var negotiationPoints: Double = 0

    init(location: SourcingLocation, buyerIDs: [UUID]) {
        self.location = location
        self.buyerIDs = buyerIDs
        self.daysRemaining = location.days
        self.totalDays = location.days
    }

    var dayLabel: String { "DAY \(totalDays - daysRemaining + 1)/\(totalDays)" }
    var progress: Double {
        guard totalDays > 0 else { return 0 }
        return Double(totalDays - daysRemaining) / Double(totalDays)
    }
}
