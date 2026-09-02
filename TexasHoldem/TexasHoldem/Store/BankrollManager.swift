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
    /// The top-up floor: any time the balance is under this, one tap brings
    /// it back up *to* this -- never any higher. So a player is never stuck
    /// waiting to play (this is exactly one buy-in at the main table), but
    /// tapping it repeatedly can't build a balance either, because it tops
    /// up to a fixed ceiling rather than adding a fixed amount. Anything
    /// pricier than this has to be won at the table.
    static let bankrollTopUpFloor = 500

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
    /// Lifetime experience points, earned by playing hands (not by chip
    /// count) -- used purely to gate game modes like VIP High Stakes behind
    /// time-invested rather than money, so it can't be bought or farmed via
    /// bankroll top-ups.
    @Published private(set) var xp: Int {
        didSet { write(xp, forKey: Keys.xp) }
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
        static let xp = "bankroll.xp"
    }

    private init() {
        // Assigned straight into each @Published property's backing storage
        // (rather than through its setter) so no didSet fires while other
        // stored properties still don't have values yet -- calling a method
        // like `write` from a didSet that runs before every stored property
        // is set is exactly the "'self' used ... before all stored
        // properties are initialized" error.
        let initialChips = defaults.object(forKey: Keys.chips) == nil
            ? Self.startingChips
            : defaults.integer(forKey: Keys.chips)
        _chips = Published(initialValue: initialChips)

        let savedPeak = defaults.integer(forKey: Keys.highestChips)
        _highestChips = Published(initialValue: max(savedPeak, initialChips, Self.startingChips))

        let savedTopUp = defaults.double(forKey: Keys.lastTopUpAt)
        _lastTopUpAt = Published(initialValue: savedTopUp > 0 ? Date(timeIntervalSince1970: savedTopUp) : nil)

        _xp = Published(initialValue: defaults.integer(forKey: Keys.xp))

        _ownedCosmeticIDs = Published(initialValue: Set(defaults.stringArray(forKey: Keys.owned) ?? []))

        _equippedCardBack = Published(initialValue: defaults.string(forKey: Keys.equippedCardBack) ?? CosmeticCatalog.defaultCardBack)
        _equippedCardFace = Published(initialValue: defaults.string(forKey: Keys.equippedCardFace) ?? CosmeticCatalog.defaultCardFace)
        _equippedFelt = Published(initialValue: defaults.string(forKey: Keys.equippedFelt) ?? CosmeticCatalog.defaultFelt)
        _equippedRail = Published(initialValue: defaults.string(forKey: Keys.equippedRail) ?? CosmeticCatalog.defaultRail)
        _equippedBackdrop = Published(initialValue: defaults.string(forKey: Keys.equippedBackdrop) ?? CosmeticCatalog.defaultBackdrop)
        _equippedChips = Published(initialValue: defaults.string(forKey: Keys.equippedChips) ?? CosmeticCatalog.defaultChips)
        _equippedAvatar = Published(initialValue: defaults.string(forKey: Keys.equippedAvatar) ?? CosmeticCatalog.defaultAvatar)
        _equippedAvatarFrame = Published(initialValue: defaults.string(forKey: Keys.equippedAvatarFrame) ?? CosmeticCatalog.defaultAvatarFrame)

        NotificationCenter.default.addObserver(
            self, selector: #selector(cloudDidChangeExternally),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud
        )
        // `synchronize()` and the initial cloud read are deferred off the
        // launch path (to the next run loop turn) so the very first frame
        // isn't held up waiting on iCloud's key-value store.
        DispatchQueue.main.async { [weak self] in
            self?.cloud.synchronize()
            self?.pullFromCloudIfNewer()
        }
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
        xp = max(xp, Int(cloud.longLong(forKey: Keys.xp)))
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

    /// Whether a top-up is available -- true whenever the balance is short of
    /// one buy-in. There's no cooldown: being unable to play and having to
    /// wait it out is worse than the small amount of grinding this allows,
    /// and topping up to a fixed ceiling means the grinding gets you nowhere
    /// anyway.
    var canTopUpBankroll: Bool { chips < Self.bankrollTopUpFloor }

    /// Chips the next top-up would hand over, for display.
    var topUpAmount: Int { max(0, Self.bankrollTopUpFloor - chips) }

    /// Brings a short balance back up to one buy-in so the player can sit
    /// down again. Tops up *to* the floor rather than adding a flat amount,
    /// so it can never be tapped repeatedly to fund the store.
    @discardableResult
    func topUpBankroll() -> Bool {
        guard canTopUpBankroll else { return false }
        chips = Self.bankrollTopUpFloor
        trackPeak()
        lastTopUpAt = Date()
        return true
    }

    // MARK: - Experience / Levels

    /// The level required to play VIP High Stakes -- reached purely by
    /// playing hands over time, not by spending or winning chips.
    static let vipUnlockLevel = 5

    /// Triangular XP curve: level 1 costs 0, and each subsequent level
    /// costs 300 more XP than the last (level 2 = 300, level 3 = 900, ...).
    private static func totalXP(forLevel level: Int) -> Int {
        let n = level - 1
        return 300 * n * (n + 1) / 2
    }

    var level: Int {
        var lvl = 1
        while Self.totalXP(forLevel: lvl + 1) <= xp { lvl += 1 }
        return lvl
    }

    /// XP earned so far within the current level, and how much the current
    /// level requires in total -- for progress bars.
    var xpProgress: (current: Int, needed: Int) {
        let base = Self.totalXP(forLevel: level)
        let next = Self.totalXP(forLevel: level + 1)
        return (xp - base, next - base)
    }

    var isVIPUnlocked: Bool { level >= Self.vipUnlockLevel }

    func addXP(_ amount: Int) {
        guard amount > 0 else { return }
        xp += amount
    }
}
