import SwiftUI

/// The live "what you're currently holding" indicator shown above the
/// table -- a glassy, half-transparent gold pill rather than a solid opaque
/// badge, so it reads as an overlay on the felt rather than a flat UI chip.
struct HandValueBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.bold())
            .foregroundColor(BJTheme.goldBright)
            .padding(.horizontal, 16).padding(.vertical, 7)
            .background(Capsule().fill(.ultraThinMaterial))
            .background(Capsule().fill(BJTheme.gold.opacity(0.18)))
            .overlay(Capsule().stroke(BJTheme.gold.opacity(0.55), lineWidth: 1))
            .materialShadow(radius: 6, y: 3)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: text)
    }
}
