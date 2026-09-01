import Foundation

/// An in-flight buying trip. Buyers are committed for its duration, and the
/// haul only materialises when it finishes — the "ship day" for inventory.
struct SourcingRun: Identifiable {
    let id = UUID()
    var location: SourcingLocation
    var buyerIDs: [UUID]
    var daysRemaining: Int
    var totalDays: Int

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
