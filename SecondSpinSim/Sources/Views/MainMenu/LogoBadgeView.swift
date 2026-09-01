import SwiftUI

/// The main menu's centerpiece mark: a record spinning inside a static
/// badge ring, with a small punched "hang tag" hole near the top edge —
/// the record (spin) and the tag (secondhand) motifs in one emblem.
/// Replaces the earlier small record-beside-wordmark treatment.
struct LogoBadgeView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.ink)
                .overlay(Circle().stroke(Theme.amber, lineWidth: 4))

            grooves
                .rotationEffect(.degrees(rotation))

            tagHole
        }
        .onAppear {
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    private var grooves: some View {
        ZStack {
            Circle().stroke(Theme.cream.opacity(0.2), lineWidth: 1).padding(fraction: 0.13)
            Circle().stroke(Theme.cream.opacity(0.2), lineWidth: 1).padding(fraction: 0.26)
            Circle().stroke(Theme.cream.opacity(0.2), lineWidth: 1).padding(fraction: 0.39)
            Circle().fill(Theme.amber).padding(fraction: 0.43)
        }
    }

    private var tagHole: some View {
        GeometryReader { geo in
            Circle()
                .fill(Theme.stageBackground)
                .overlay(Circle().stroke(Theme.amber, lineWidth: 2.5))
                .frame(width: geo.size.width * 0.1, height: geo.size.width * 0.1)
                .position(x: geo.size.width * 0.74, y: geo.size.height * 0.2)
        }
    }
}

private extension View {
    /// Pads by a fraction of the view's own width — keeps the groove rings
    /// proportional regardless of what size the badge is drawn at.
    func padding(fraction: CGFloat) -> some View {
        GeometryReader { geo in
            self.padding(geo.size.width * fraction)
        }
    }
}

#Preview {
    LogoBadgeView()
        .frame(width: 92, height: 92)
        .padding(40)
        .background(Theme.stageBackground)
}
