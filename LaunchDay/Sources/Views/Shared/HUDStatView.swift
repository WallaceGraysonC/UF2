import SwiftUI

/// A labeled stat in the top HUD bar — "DAY 14" over "SEASON 1", etc.
/// Shared across every hub screen so the HUD reads consistently.
struct HUDStatView: View {
    let value: String
    let label: String
    var valueSize: CGFloat = 15

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.display(valueSize))
                .foregroundStyle(Theme.amber)
                // Rolls the digits when cash or the day changes instead of
                // snapping, which reads much better during day resolution.
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.4), value: value)
            Text(label)
                .font(Theme.mono(8, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
                .kerning(0.5)
        }
    }
}
