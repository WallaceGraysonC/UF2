import Foundation

/// A permanent bonus chosen when you close up shop. One per retirement,
/// and they stack across runs.
enum LegacyPerk: String, CaseIterable, Identifiable, Codable {
    case seedMoney = "Seed Money"
    case eyeForIt = "An Eye For It"
    case rolodex = "The Rolodex"
    case quickStudy = "Quick Study"

    var id: String { rawValue }

    var detail: String {
        switch self {
        case .seedMoney: return "Start each run with an extra $400."
        case .eyeForIt: return "Rare pulls on every Sourcing Run are 25% likelier."
        case .rolodex: return "Start with an extra staff member on the roster."
        case .quickStudy: return "Conventions finish a day sooner."
        }
    }

    /// What it takes to pick this one — better perks want a better run.
    var scoreRequired: Int {
        switch self {
        case .seedMoney: return 0
        case .quickStudy: return 400
        case .eyeForIt: return 900
        case .rolodex: return 1_600
        }
    }
}

/// Everything that outlives a single shop: how many times you've retired,
/// what you've unlocked, and the running totals unlock conditions check.
struct LegacyProfile: Codable {
    static let currentVersion = 1
    var version: Int = LegacyProfile.currentVersion

    var prestigeCount: Int = 0
    var totalLegacyScore: Int = 0
    var bestLegacyScore: Int = 0
    var perks: [LegacyPerk] = []

    var unlockedCosmeticIDs: Set<String> = []
    var equipped: [CosmeticSlot: String] = [:]

    // Running totals across every run, for unlock conditions.
    var lifetimeRevenue: Int = 0
    var highestSaleValue: Int = 0
    var bestShopLevel: Int = 1
    var totalMuseumPieces: Int = 0
    var totalStaffTrained: Int = 0
    var totalFiveStarDrops: Int = 0
    var lowestRetirementCash: Int = Int.max

    func has(_ perk: LegacyPerk) -> Bool { perks.contains(perk) }

    func isUnlocked(_ cosmetic: Cosmetic) -> Bool {
        if case .fromTheStart = cosmetic.unlock { return true }
        return unlockedCosmeticIDs.contains(cosmetic.id)
    }

    /// Whether the profile's running totals currently satisfy a condition.
    func satisfies(_ condition: UnlockCondition) -> Bool {
        switch condition {
        case .fromTheStart: return true
        case .prestigeCount(let n): return prestigeCount >= n
        case .reachedLevel(let n): return bestShopLevel >= n
        case .soldGrailWorth(let n): return highestSaleValue >= n
        case .museumPieces(let n): return totalMuseumPieces >= n
        case .staffTrained(let n): return totalStaffTrained >= n
        case .fiveStarDrops(let n): return totalFiveStarDrops >= n
        case .retiredBroke(let n): return lowestRetirementCash < n
        }
    }

    /// Grants anything newly earned and reports what was just unlocked, so the
    /// retirement screen can call it out.
    mutating func refreshUnlocks() -> [Cosmetic] {
        var newlyUnlocked: [Cosmetic] = []
        for cosmetic in CosmeticCatalog.all where !isUnlocked(cosmetic) {
            if satisfies(cosmetic.unlock) {
                unlockedCosmeticIDs.insert(cosmetic.id)
                newlyUnlocked.append(cosmetic)
            }
        }
        return newlyUnlocked
    }

    func equippedCosmetic(in slot: CosmeticSlot) -> Cosmetic {
        if let id = equipped[slot], let found = CosmeticCatalog.cosmetic(id: id) {
            return found
        }
        return CosmeticCatalog.starter(for: slot)
    }

    mutating func equip(_ cosmetic: Cosmetic) {
        guard isUnlocked(cosmetic) else { return }
        equipped[cosmetic.slot] = cosmetic.id
    }
}

/// The legacy profile lives in its own file — closing up shop wipes the run
/// save but must never touch this one.
enum LegacyStore {

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first
            ?? URL.documentsDirectory
        return base.appendingPathComponent("second-spin-legacy.json")
    }

    static func load() -> LegacyProfile {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return LegacyProfile()
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let profile = try JSONDecoder().decode(LegacyProfile.self, from: data)
            guard profile.version == LegacyProfile.currentVersion else {
                print("Second Spin: legacy profile version mismatch — starting fresh")
                return LegacyProfile()
            }
            return profile
        } catch {
            print("Second Spin: legacy load failed — \(error)")
            return LegacyProfile()
        }
    }

    static func save(_ profile: LegacyProfile) {
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory,
                                                    withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            try encoder.encode(profile).write(to: fileURL, options: .atomic)
        } catch {
            print("Second Spin: legacy save failed — \(error)")
        }
    }
}
