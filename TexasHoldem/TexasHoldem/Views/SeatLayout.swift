import CoreGraphics
import Foundation

enum SeatLayout {
    /// Returns normalized (x, y) offsets in -1...1 around an oval table for
    /// `count` seats, starting at the bottom (human seat) and going clockwise.
    static func offsets(count: Int) -> [CGPoint] {
        guard count > 0 else { return [] }
        var points: [CGPoint] = []
        for i in 0..<count {
            let angle = (Double(i) / Double(count)) * 2 * .pi + .pi / 2
            let x = cos(angle)
            let rawY = sin(angle)
            // Less vertical squash than a true ellipse-from-circle would give,
            // so top/bottom seats sit near the rail instead of crowding the
            // community cards in the middle.
            //
            // Seats out at the left and right ends of the oval land at the
            // table's vertical midline, which is exactly where the community
            // cards are -- their hole cards end up overlapping the board. So
            // bias those downward, strongest at the midline and tapering to
            // nothing for the seats already at the top and bottom.
            let midlineBias = (1 - abs(rawY)) * 0.20
            points.append(CGPoint(x: x, y: rawY * 0.90 + midlineBias))
        }
        return points
    }
}
