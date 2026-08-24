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
            // Less vertical squash than a true ellipse-from-circle would give,
            // so top/bottom seats sit near the rail instead of crowding the
            // community cards in the middle.
            let y = sin(angle) * 0.90
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
}
