import Foundation
import Combine

/// Manages the player's virtual chip balance and owned/equipped cosmetics.
/// Chips have no real-world value, cannot be purchased with real money, and
/// cannot be cashed out -- they only exist to keep score and unlock cosmetics.
///
/// State is written to both `UserDefaults` (instant local read/write) and
/// `NSUbiquitousKeyValueStore` (Apple's free iCloud key-value sync), so the
/// same bankroll and cosmetics follow the player to their other devices as
/// long as they're signed into iCloud and the app's iCloud capability is
/// enabled in Xcode. This needs no server of our own.
final class BankrollManager: ObservableObject {
    static let shared = BankrollManager()

    static let startingChips = 10_000

    @Published private(set) var chips: Int {
        didSet { write(chips, forKey: Keys.chips) }
    }
    @Published private(set) var ownedCosmeticIDs: Set<String> {
        didSet { write(Array(ownedCosmeticIDs), forKey: Keys.owned) }
    }
    @Published var equippedCardBack: String {
        didSet { write(equippedCardBack, forKey: Keys.equippedCardBack) }
    }
    @Published var equippedFelt: String {
        didSet { write(equippedFelt, forKey: Keys.equippedFelt) }
    }
    @Published var equippedChips: String {
        didSet { write(equippedChips, forKey: Keys.equippedChips) }
    }
    @Published var equippedAvatar: String {
        didSet { write(equippedAvatar, forKey: Keys.equippedAvatar) }
    }

    /// True once `NSUbiquitousKeyValueStore` has synced at least once,
    /// meaning the device is signed into iCloud and this app's iCloud
    /// key-value entitlement is set up.
    @Published private(set) var isCloudAvailable = false

    private let defaults = UserDefaults.standard
    private let cloud = NSUbiquitousKeyValueStore.default

    private enum Keys {
        static let chips = "bankroll.chips"
        static let owned = "bankroll.owned"
        static let equippedCardBack = "bankroll.equippedCardBack"
        static let equippedFelt = "bankroll.equippedFelt"
        static let equippedChips = "bankroll.equippedChips"
        static let equippedAvatar = "bankroll.equippedAvatar"
    }

    private init() {
        if defaults.object(forKey: Keys.chips) == nil {
            chips = Self.startingChips
        } else {
            chips = defaults.integer(forKey: Keys.chips)
        }
        ownedCosmeticIDs = Set(defaults.stringArray(forKey: Keys.owned) ?? [])
        equippedCardBack = defaults.string(forKey: Keys.equippedCardBack) ?? CosmeticCatalog.defaultCardBack
        equippedFelt = defaults.string(forKey: Keys.equippedFelt) ?? CosmeticCatalog.defaultFelt
        equippedChips = defaults.string(forKey: Keys.equippedChips) ?? CosmeticCatalog.defaultChips
        equippedAvatar = defaults.string(forKey: Keys.equippedAvatar) ?? CosmeticCatalog.defaultAvatar

        NotificationCenter.default.addObserver(
            self, selector: #selector(cloudDidChangeExternally),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud
        )
        cloud.synchronize()
        pullFromCloudIfNewer()
    }

    private func write<T>(_ value: T, forKey key: String) where T: Any {
        defaults.set(value, forKey: key)
        cloud.set(value, forKey: key)
    }

    /// On launch, if iCloud already has a value (e.g. this bankroll was set
    /// up on another device first), prefer it over a fresh local default.
    private func pullFromCloudIfNewer() {
        guard cloud.object(forKey: Keys.chips) != nil else { return }
        isCloudAvailable = true
        chips = Int(cloud.longLong(forKey: Keys.chips))
        ownedCosmeticIDs = Set(cloud.array(forKey: Keys.owned) as? [String] ?? [])
        equippedCardBack = cloud.string(forKey: Keys.equippedCardBack) ?? equippedCardBack
        equippedFelt = cloud.string(forKey: Keys.equippedFelt) ?? equippedFelt
        equippedChips = cloud.string(forKey: Keys.equippedChips) ?? equippedChips
        equippedAvatar = cloud.string(forKey: Keys.equippedAvatar) ?? equippedAvatar
    }

    @objc private func cloudDidChangeExternally(_ notification: Notification) {
        isCloudAvailable = true
        DispatchQueue.main.async { [weak self] in
            self?.pullFromCloudIfNewer()
        }
    }

    func owns(_ cosmetic: Cosmetic) -> Bool {
        cosmetic.price == 0 || ownedCosmeticIDs.contains(cosmetic.id)
    }

    @discardableResult
    func purchase(_ cosmetic: Cosmetic) -> Bool {
        guard !owns(cosmetic), chips >= cosmetic.price else { return false }
        chips -= cosmetic.price
        ownedCosmeticIDs.insert(cosmetic.id)
        return true
    }

    func equip(_ cosmetic: Cosmetic) {
        guard owns(cosmetic) else { return }
        switch cosmetic.kind {
        case .cardBack: equippedCardBack = cosmetic.id
        case .tableFelt: equippedFelt = cosmetic.id
        case .chipSet: equippedChips = cosmetic.id
        case .avatar: equippedAvatar = cosmetic.id
        }
    }

    /// Settle winnings/losses from a completed table session into the
    /// persistent bankroll (used after a hosted/local game ends).
    func applyDelta(_ delta: Int) {
        chips = max(0, chips + delta)
    }

    func setChips(_ amount: Int) {
        chips = max(0, amount)
    }

    /// "Restart" -- resets the bankroll back to the starting amount, e.g.
    /// after busting out, with no strings attached.
    func resetBankroll() {
        chips = Self.startingChips
    }
}
