import Foundation

/// A flat, Codable picture of a run. Kept separate from GameState so the
/// on-disk shape is something we control deliberately rather than whatever
/// the observable class happens to hold this week.
struct SaveGame: Codable {
    /// Bumped when the shape changes incompatibly; older files are discarded
    /// rather than half-loaded.
    static let currentVersion = 1
    var version: Int = SaveGame.currentVersion

    var day: Int
    var cash: Int
    var shopLevel: Int

    var staff: [StaffMember]
    var inventory: [InventoryItem]
    var benchJobs: [RestorationJob]
    var ledger: [LedgerEntry]
    var hiringBoard: [StaffMember]

    var activeRun: SourcingRun?
    var pendingHaul: [InventoryItem]

    var activeDrop: CuratedDrop?
    var lastDropResult: DropResult?
    var dropHistory: [DropResult]
    var discoveredCombos: Set<String>

    var reputation: [CustomerArchetype: Int]
    var trendingFormat: MediaFormat
    var trendDaysRemaining: Int

    var activeCampaign: AdCampaign?
    var museum: [MuseumPiece]
    var highestSaleValue: Int
    var lifetimeRevenue: Int
    var staffTrainedCount: Int
    var fiveStarDrops: Int
    var perks: [LegacyPerk]

    /// Shown on the main menu so Continue says what you'd be returning to.
    var savedAt: Date = Date()
}

/// Reads and writes the single save slot in Application Support.
enum SaveStore {

    enum StoreError: Error {
        case noSave
    }

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first
            ?? URL.documentsDirectory
        return base.appendingPathComponent("second-spin-save.json")
    }

    static var hasSave: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    static func save(_ snapshot: SaveGame) {
        do {
            // Application Support isn't guaranteed to exist on a fresh install.
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory,
                                                    withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(snapshot)
            // Atomic so a crash mid-write can't leave a truncated save.
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // A failed save shouldn't take the game down — the run continues
            // in memory and the next day-end will try again.
            print("Second Spin: save failed — \(error)")
        }
    }

    static func load() -> SaveGame? {
        guard hasSave else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try JSONDecoder().decode(SaveGame.self, from: data)
            guard snapshot.version == SaveGame.currentVersion else {
                print("Second Spin: save is version \(snapshot.version), expected \(SaveGame.currentVersion) — discarding")
                deleteSave()
                return nil
            }
            return snapshot
        } catch {
            print("Second Spin: load failed — \(error)")
            return nil
        }
    }

    static func deleteSave() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
