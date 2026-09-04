import UIKit

/// Physical feedback for the handful of moments that deserve it. Deliberately
/// sparse: a game that buzzes on every tap trains people to switch it off, so
/// this fires only when the table state changes in a way you'd want to feel
/// without looking -- your turn, a hand won, a bust-out.
enum Haptics {
    /// Respected everywhere below. On by default, unlike the music -- feedback
    /// is expected in a card game in a way that background music isn't.
    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Key.enabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Key.enabled) }
    }

    private enum Key { static let enabled = "haptics.enabled" }

    /// The action has come round to you.
    static func yourTurn() { impact(.medium) }

    /// You won the hand.
    static func wonHand() { notify(.success) }

    /// You're out of chips at the table.
    static func bustedOut() { notify(.warning) }

    /// A chip token, a card, a menu row.
    static func tap() { impact(.light) }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
