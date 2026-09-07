import Foundation

/// How aggressively/accurately `BotAI` plays. Applies to any table with
/// bots -- Custom Table Setup and the Game Modes (Sit & Go, Turbo Sit & Go,
/// VIP High Stakes) both let the player pick one; the default "Play vs
/// Bots" quick-start table always uses `.normal`.
enum BotDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy, normal, hard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}
