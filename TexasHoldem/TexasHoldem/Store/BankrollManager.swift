import Foundation
import Combine

/// Manages the player's virtual chip balance and owned/equipped cosmetics.
/// Chips have no real-world value, cannot be purchased with real money, and
/// cannot be cashed out -- they only exist to keep score and unlock cosmetics.
final class BankrollManager: ObservableObject {
    static let shared = BankrollManager()

    static let startingChips = 10_000

    @Published private(set) var chips: Int {
        didSet { UserDefaults.standard.set(chips, forKey: Keys.chips) }
    }
    @Published private(set) var ownedCosmeticIDs: Set<String> {
        didSet { UserDefaults.standard.set(Array(ownedCosmeticIDs), forKey: Keys.owned) }
    }
    @Published var equippedCardBack: String {
        didSet { UserDefaults.standard.set(equippedCardBack, forKey: Keys.equippedCardBack) }
    }
    @Published var equippedFelt: String {
        didSet { UserDefaults.standard.set(equippedFelt, forKey: Keys.equippedFelt) }
    }
    @Published var equippedChips: String {
        didSet { UserDefaults.standard.set(equippedChips, forKey: Keys.equippedChips) }
    }
    @Published var equippedAvatar: String {
        didSet { UserDefaults.standard.set(equippedAvatar, forKey: Keys.equippedAvatar) }
    }

    private enum Keys {
        static let chips = "bankroll.chips"
        static let owned = "bankroll.owned"
        static let equippedCardBack = "bankroll.equippedCardBack"
        static let equippedFelt = "bankroll.equippedFelt"
        static let equippedChips = "bankroll.equippedChips"
        static let equippedAvatar = "bankroll.equippedAvatar"
    }

    private init() {
        let defaults = UserDefaults.standard
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
