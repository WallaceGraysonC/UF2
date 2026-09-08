import Foundation

/// What kind of game this is. Paired with a Topic to decide a project's
/// hidden affinity rating — the genre×topic matrix from the real Game Dev
/// Story, discoverable through play rather than looked up.
enum Genre: String, CaseIterable, Identifiable, Codable {
    case action = "Action"
    case rpg = "RPG"
    case adventure = "Adventure"
    case simulation = "Simulation"
    case strategy = "Strategy"
    case puzzle = "Puzzle"

    var id: String { rawValue }

    /// Which point type this genre leans on more heavily when scoring.
    var designWeight: Double {
        switch self {
        case .action: return 0.4
        case .rpg: return 0.55
        case .adventure: return 0.65
        case .simulation: return 0.5
        case .strategy: return 0.45
        case .puzzle: return 0.6
        }
    }
}
