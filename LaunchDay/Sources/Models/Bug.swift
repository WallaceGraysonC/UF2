import Foundation

/// A bug that showed up during development. Tap it before it's shipped —
/// the classic Game Dev Story squash — or it comes out of the review score.
struct Bug: Identifiable, Codable {
    var id = UUID()
    var deskLane: Int
    var spawnedDay: Int
}
