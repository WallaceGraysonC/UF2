import SwiftUI

/// What a staffer is doing right now. Drives what shows at their desk, so
/// the room reads as people working rather than sprites standing about.
enum StaffTask: Equatable {
    case sourcing(String)
    case bench(String)
    case drop(String)
    case training(String)
    case floor

    var label: String {
        switch self {
        case .sourcing: return "SOURCING"
        case .bench: return "BENCH"
        case .drop: return "DROP PREP"
        case .training: return "CONVENTION"
        case .floor: return "ON THE FLOOR"
        }
    }

    /// The specific thing — which location, which item, which drop.
    var subject: String {
        switch self {
        case .sourcing(let where_): return where_
        case .bench(let item): return item
        case .drop(let name): return name
        case .training(let stat): return stat
        case .floor: return "serving customers"
        }
    }

    var tint: Color {
        switch self {
        case .sourcing: return Theme.amberDeep
        case .bench: return Theme.teal
        case .drop: return Theme.plum
        case .training: return Theme.steel
        case .floor: return Theme.inkSoft
        }
    }

    /// Whether this counts as working a project — idle staff read differently.
    var isBusy: Bool {
        if case .floor = self { return false }
        return true
    }
}

extension GameState {
    /// Resolves a staffer's current job from whatever they're attached to.
    func currentTask(for member: StaffMember) -> StaffTask {
        if member.isTraining {
            return .training(member.trainingStat?.rawValue ?? "training")
        }
        if let run = activeRun, run.buyerIDs.contains(member.id) {
            return .sourcing(run.location.rawValue)
        }
        if let job = benchJobs.first(where: { $0.assignedTechID == member.id }) {
            return .bench(job.itemName)
        }
        if let drop = activeDrop, drop.curatorIDs.contains(member.id) {
            return .drop(drop.name)
        }
        return .floor
    }
}
