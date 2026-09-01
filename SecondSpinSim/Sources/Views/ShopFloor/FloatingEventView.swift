import SwiftUI

/// A single "+$42" that rises off a staff station and fades — the beat that
/// makes a day feel like it happened rather than like it was calculated.
struct FloatingEventView: View {
    let event: DayEvent

    @State private var rise: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.6

    var body: some View {
        VStack(spacing: 1) {
            Text(event.headline)
                .font(Theme.display(15))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
            Text(event.detail)
                .font(Theme.mono(7, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(event.tint)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(.black.opacity(0.3), lineWidth: 1))
        .scaleEffect(scale)
        .offset(y: -rise)
        .opacity(opacity)
        .onAppear { animate() }
    }

    private func animate() {
        // A quick pop in, then a slow drift up and out.
        withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
            scale = 1
            opacity = 1
        }
        withAnimation(.easeOut(duration: DayPacing.popupLifetime)) {
            rise = DayPacing.popupRise
        }
        withAnimation(.easeIn(duration: 0.35).delay(DayPacing.popupLifetime - 0.35)) {
            opacity = 0
        }
    }
}
