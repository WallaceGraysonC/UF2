import SwiftUI

/// Idle decoration for the main menu — a slow-spinning record, a nod to the
/// game's name and a bit of the ambient motion Kairosoft menus always have
/// (a flag waving, a sign swinging) rather than a static screen.
struct SpinningRecordView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.ink)
            Circle()
                .stroke(Theme.inkSoft.opacity(0.4), lineWidth: 1)
                .padding(6)
            Circle()
                .stroke(Theme.inkSoft.opacity(0.4), lineWidth: 1)
                .padding(14)
            Circle()
                .fill(Theme.amber)
                .frame(width: 18, height: 18)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
