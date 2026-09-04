import CoreGraphics
import Foundation

enum SeatLayout {
    /// Normalized (x, y) seat offsets in -1...1 around the table's curve,
    /// with index 0 being the local player's own seat.
    ///
    /// These are placed per table size rather than spread evenly around an
    /// arc. An even spread always lands seats at the far left and right --
    /// exactly the height the dealer's hand occupies -- so those players'
    /// cards ended up sitting on top of the dealer. Every position here is
    /// either above the dealer or below their cards, leaving that middle
    /// band clear no matter how many are seated. Real semi-circle blackjack
    /// tables seat at most seven players plus the dealer, so unlike a poker
    /// oval this only needs to go up to 7.
    static func offsets(count: Int) -> [CGPoint] {
        guard count > 0 else { return [] }
        return tables[count] ?? evenlySpaced(count: count)
    }

    /// Full tables need the smaller seat rendering, or neighbouring seats
    /// start running into each other once the curve is this full.
    static func usesCompactSeats(count: Int) -> Bool { count >= 6 }

    /// The local player's own seat. The table view draws the human
    /// separately along the bottom edge, so this is only a placeholder that
    /// keeps every other seat's index lined up with the players array.
    private static let heroSeat = CGPoint(x: 0, y: 0.95)

    /// Seats run clockwise from the local player: up the left side, across
    /// the top, and back down the right, mirroring how a real blackjack
    /// table curves around the dealer.
    private static let tables: [Int: [CGPoint]] = [
        2: [heroSeat,
            CGPoint(x: 0.00, y: -0.88)],

        3: [heroSeat,
            CGPoint(x: -0.72, y: -0.70),
            CGPoint(x: 0.72, y: -0.70)],

        4: [heroSeat,
            CGPoint(x: -0.82, y: 0.34),
            CGPoint(x: 0.00, y: -0.92),
            CGPoint(x: 0.82, y: 0.34)],

        5: [heroSeat,
            CGPoint(x: -0.82, y: 0.34),
            CGPoint(x: -0.72, y: -0.72),
            CGPoint(x: 0.72, y: -0.72),
            CGPoint(x: 0.82, y: 0.34)],

        6: [heroSeat,
            CGPoint(x: -0.82, y: 0.34),
            CGPoint(x: -0.76, y: -0.66),
            CGPoint(x: 0.00, y: -0.94),
            CGPoint(x: 0.76, y: -0.66),
            CGPoint(x: 0.82, y: 0.34)],

        7: [heroSeat,
            CGPoint(x: -0.80, y: 0.36),
            CGPoint(x: -0.92, y: -0.50),
            CGPoint(x: -0.50, y: -0.92),
            CGPoint(x: 0.50, y: -0.92),
            CGPoint(x: 0.92, y: -0.50),
            CGPoint(x: 0.80, y: 0.36)],
    ]

    /// Fallback for table sizes with no hand-placed layout: an even spread
    /// around the curve, biased downward at the vertical midline so those
    /// seats still clear the dealer.
    private static func evenlySpaced(count: Int) -> [CGPoint] {
        (0..<count).map { i in
            let angle = (Double(i) / Double(count)) * 2 * .pi + .pi / 2
            let rawY = sin(angle)
            return CGPoint(x: cos(angle), y: rawY * 0.90 + (1 - abs(rawY)) * 0.30)
        }
    }
}
