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

    static let startingChips = 1000
    /// A "top-up" (not a full reset) available only when the player is
    /// nearly broke, with a cooldown -- deliberately smaller and slower
    /// than actually winning chips at the table, so it's a safety net
    /// against busting out rather than a free way to buy every cosmetic.
    static let bankrollTopUpAmount = 500
    static let bankrollTopUpThreshold = 200
    static let bankrollTopUpCooldown: TimeInterval = 60 * 60 * 8 // 8 hours

    @Published private(set) var chips: Int {
        didSet { write(chips, forKey: Keys.chips) }
    }
    /// The most chips this player has ever held. Only grows when `chips`
    /// exceeds its previous peak, which -- since the starting balance and
    /// every top-up are fixed, small amounts -- can only climb meaningfully
    /// through actual winnings at the table. Used to gate pricier cosmetics
    /// behind money actually won rather than money currently on hand, so
    /// resetting/topping up the bankroll can't be farmed to unlock everything.
    @Published private(set) var highestChips: Int {
        didSet { write(highestChips, forKey: Keys.highestChips) }
    }
    @Published private(set) var lastTopUpAt: Date? {
        didSet { write(lastTopUpAt?.timeIntervalSince1970 ?? -1, forKey: Keys.lastTopUpAt) }
    }
    @Published private(set) var ownedCosmeticIDs: Set<String> {
        didSet { write(Array(ownedCosmeticIDs), forKey: Keys.owned) }
    }
    @Published var equippedCardBack: String {
        didSet { write(equippedCardBack, forKey: Keys.equippedCardBack) }
    }
    @Published var equippedCardFace: String {
        didSet { write(equippedCardFace, forKey: Keys.equippedCardFace) }
    }
    @Published var equippedFelt: String {
        didSet { write(equippedFelt, forKey: Keys.equippedFelt) }
    }
    @Published var equippedRail: String {
        didSet { write(equippedRail, forKey: Keys.equippedRail) }
    }
    @Published var equippedBackdrop: String {
        didSet { write(equippedBackdrop, forKey: Keys.equippedBackdrop) }
    }
    @Published var equippedChips: String {
        didSet { write(equippedChips, forKey: Keys.equippedChips) }
    }
    @Published var equippedAvatar: String {
        didSet { write(equippedAvatar, forKey: Keys.equippedAvatar) }
    }
    @Published var equippedAvatarFrame: String {
        didSet { write(equippedAvatarFrame, forKey: Keys.equippedAvatarFrame) }
    }

    /// True once `NSUbiquitousKeyValueStore` has synced at least once,
    /// meaning the device is signed into iCloud and this app's iCloud
    /// key-value entitlement is set up.
    @Published private(set) var isCloudAvailable = false

    private let defaults = UserDefaults.standard
    private let cloud = NSUbiquitousKeyValueStore.default

    private enum Keys {
        static let chips = "bankroll.chips"
        static let highestChips = "bankroll.highestChips"
        static let lastTopUpAt = "bankroll.lastTopUpAt"
        static let owned = "bankroll.owned"
        static let equippedCardBack = "bankroll.equippedCardBack"
        static let equippedCardFace = "bankroll.equippedCardFace"
        static let equippedFelt = "bankroll.equippedFelt"
        static let equippedRail = "bankroll.equippedRail"
        static let equippedBackdrop = "bankroll.equippedBackdrop"
        static let equippedChips = "bankroll.equippedChips"
        static let equippedAvatar = "bankroll.equippedAvatar"
        static let equippedAvatarFrame = "bankroll.equippedAvatarFrame"
    }

    private init() {
        if defaults.object(forKey: Keys.chips) == nil {
            chips = Self.startingChips
        } else {
            chips = defaults.integer(forKey: Keys.chips)
        }
        let savedPeak = defaults.integer(forKey: Keys.highestChips)
        highestChips = max(savedPeak, chips, Self.startingChips)
        let savedTopUp = defaults.double(forKey: Keys.lastTopUpAt)
        lastTopUpAt = savedTopUp > 0 ? Date(timeIntervalSince1970: savedTopUp) : nil
        ownedCosmeticIDs = Set(defaults.stringArray(forKey: Keys.owned) ?? [])
        equippedCardBack = defaults.string(forKey: Keys.equippedCardBack) ?? CosmeticCatalog.defaultCardBack
        equippedCardFace = defaults.string(forKey: Keys.equippedCardFace) ?? CosmeticCatalog.defaultCardFace
        equippedFelt = defaults.string(forKey: Keys.equippedFelt) ?? CosmeticCatalog.defaultFelt
        equippedRail = defaults.string(forKey: Keys.equippedRail) ?? CosmeticCatalog.defaultRail
        equippedBackdrop = defaults.string(forKey: Keys.equippedBackdrop) ?? CosmeticCatalog.defaultBackdrop
        equippedChips = defaults.string(forKey: Keys.equippedChips) ?? CosmeticCatalog.defaultChips
        equippedAvatar = defaults.string(forKey: Keys.equippedAvatar) ?? CosmeticCatalog.defaultAvatar
        equippedAvatarFrame = defaults.string(forKey: Keys.equippedAvatarFrame) ?? CosmeticCatalog.defaultAvatarFrame

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
        highestChips = max(highestChips, Int(cloud.longLong(forKey: Keys.highestChips)))
        let cloudTopUp = cloud.double(forKey: Keys.lastTopUpAt)
        if cloudTopUp > 0 { lastTopUpAt = Date(timeIntervalSince1970: cloudTopUp) }
        ownedCosmeticIDs = Set(cloud.array(forKey: Keys.owned) as? [String] ?? [])
        equippedCardBack = cloud.string(forKey: Keys.equippedCardBack) ?? equippedCardBack
        equippedCardFace = cloud.string(forKey: Keys.equippedCardFace) ?? equippedCardFace
        equippedFelt = cloud.string(forKey: Keys.equippedFelt) ?? equippedFelt
        equippedRail = cloud.string(forKey: Keys.equippedRail) ?? equippedRail
        equippedBackdrop = cloud.string(forKey: Keys.equippedBackdrop) ?? equippedBackdrop
        equippedChips = cloud.string(forKey: Keys.equippedChips) ?? equippedChips
        equippedAvatar = cloud.string(forKey: Keys.equippedAvatar) ?? equippedAvatar
        equippedAvatarFrame = cloud.string(forKey: Keys.equippedAvatarFrame) ?? equippedAvatarFrame
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

    /// Whether this item's lifetime-peak gate is met, independent of
    /// whether the player can currently afford its price.
    func isUnlocked(_ cosmetic: Cosmetic) -> Bool {
        highestChips >= cosmetic.unlockRequirement
    }

    @discardableResult
    func purchase(_ cosmetic: Cosmetic) -> Bool {
        guard !owns(cosmetic), isUnlocked(cosmetic), chips >= cosmetic.price else { return false }
        chips -= cosmetic.price
        ownedCosmeticIDs.insert(cosmetic.id)
        return true
    }

    func equip(_ cosmetic: Cosmetic) {
        guard owns(cosmetic) else { return }
        switch cosmetic.kind {
        case .cardBack: equippedCardBack = cosmetic.id
        case .cardFace: equippedCardFace = cosmetic.id
        case .tableFelt: equippedFelt = cosmetic.id
        case .tableRail: equippedRail = cosmetic.id
        case .tableBackdrop: equippedBackdrop = cosmetic.id
        case .chipSet: equippedChips = cosmetic.id
        case .avatar: equippedAvatar = cosmetic.id
        case .avatarFrame: equippedAvatarFrame = cosmetic.id
        }
    }

    /// Settle winnings/losses from a completed table session into the
    /// persistent bankroll (used after a hosted/local game ends). This is
    /// the only path through which `highestChips` can climb in practice,
    /// since it's the only place real winnings (as opposed to the fixed
    /// starting balance or a top-up) get added.
    func applyDelta(_ delta: Int) {
        chips = max(0, chips + delta)
        trackPeak()
    }

    func setChips(_ amount: Int) {
        chips = max(0, amount)
        trackPeak()
    }

    /// Bumps `highestChips` if `chips` just exceeded its previous peak.
    /// Called explicitly at every runtime mutation point rather than from
    /// a `didSet` on `chips`, since that would read `highestChips` before
    /// it's initialized when `chips` gets its first value in `init`.
    private func trackPeak() {
        if chips > highestChips { highestChips = chips }
    }

    /// Whether a bankroll top-up can be used right now: the player has to
    /// actually be low on chips, and enough time has to have passed since
    /// the last one.
    var canTopUpBankroll: Bool {
        chips < Self.bankrollTopUpThreshold && topUpCooldownRemaining <= 0
    }

    /// Seconds remaining before another top-up is allowed, 0 if available now.
    var topUpCooldownRemaining: TimeInterval {
        guard let lastTopUpAt else { return 0 }
        return max(0, Self.bankrollTopUpCooldown - Date().timeIntervalSince(lastTopUpAt))
    }

    /// Adds a small emergency top-up when the player is nearly broke, with
    /// a cooldown -- deliberately not a full reset, so it can't be spammed
    /// to fund every cosmetic in the store. Returns whether it was applied.
    @discardableResult
    func topUpBankroll() -> Bool {
        guard canTopUpBankroll else { return false }
        chips += Self.bankrollTopUpAmount
        trackPeak()
        lastTopUpAt = Date()
        return true
    }
}
