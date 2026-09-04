import Foundation

/// A local practice game, saved so the player can back out (or the app can
/// get backgrounded/killed) and pick the same round back up later instead
/// of losing their seat.
struct PersistedLocalGame: Codable {
    var engine: EngineSnapshot
    var humanID: String
    var buyIn: Int
}

enum GamePersistence {
    private static let key = "blackjack.localgame.snapshot"

    static func save(_ game: PersistedLocalGame) {
        guard let data = try? JSONEncoder().encode(game) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func loadLocalGame() -> PersistedLocalGame? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PersistedLocalGame.self, from: data)
    }

    static func clearLocalGame() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    static var hasSavedLocalGame: Bool {
        UserDefaults.standard.data(forKey: key) != nil
    }
}
