import Foundation

/// A flat, Codable picture of a run, saved to Application Support.
struct SaveFile: Codable {
    static let currentVersion = 1
    var version: Int = SaveFile.currentVersion

    var day: Int
    var cash: Int
    var fans: Int
    var studioLevel: Int

    var employees: [Employee]
    var hiringBoard: [Employee]
    var currentProject: GameProject?
    var needsShipDecision: Bool
    var shippedGames: [ShippedGame]
    var discoveredCombos: Set<String>
    var milestonesReached: Set<Int>

    var savedAt: Date = Date()
}

/// Reads and writes the single save slot in Application Support.
enum SaveStore {

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first
            ?? URL.documentsDirectory
        return base.appendingPathComponent("launch-day-save.json")
    }

    static var hasSave: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    static func save(_ snapshot: SaveFile) {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory,
                                                    withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Launch Day: save failed — \(error)")
        }
    }

    static func load() -> SaveFile? {
        guard hasSave else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try JSONDecoder().decode(SaveFile.self, from: data)
            guard snapshot.version == SaveFile.currentVersion else {
                print("Launch Day: save version mismatch — discarding")
                deleteSave()
                return nil
            }
            return snapshot
        } catch {
            print("Launch Day: load failed — \(error)")
            return nil
        }
    }

    static func deleteSave() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
