import Foundation

/// The one thing the studio is making. Everyone's desk points at this.
struct GameProject: Codable {
    var name: String
    var genre: Genre
    var topic: Topic
    var size: ProjectSize
    var platform: Platform

    var daysElapsed: Int = 0
    var designPoints: Double = 0
    var techPoints: Double = 0

    /// 0 = full Tech emphasis, 1 = full Design emphasis — the classic GDS
    /// dial. Defaults to the genre's own natural lean.
    var focusBias: Double

    var bugs: [Bug] = []
    var bugsFixed: Int = 0

    init(name: String, genre: Genre, topic: Topic, size: ProjectSize, platform: Platform) {
        self.name = name
        self.genre = genre
        self.topic = topic
        self.size = size
        self.platform = platform
        self.focusBias = genre.designWeight
    }

    var affinity: ComboAffinity { GenreTopicCombo.affinity(genre: genre, topic: topic) }

    var totalPoints: Double { designPoints + techPoints }
    var progress: Double { min(1.0, totalPoints / size.targetPoints) }
    var isReadyToShip: Bool { daysElapsed >= size.devDays }
    var daysRemaining: Int { max(0, size.devDays - daysElapsed) }

    /// Bugs start showing up once the project is mostly built — polishing
    /// a project too early doesn't make sense, same as in the original.
    var isInPolishWindow: Bool { Double(daysElapsed) / Double(max(1, size.devDays)) > 0.55 }

    var unfixedBugCount: Int { bugs.count }
}

/// A finished, shipped game — history plus the sales tail it's still earning.
struct ShippedGame: Identifiable, Codable {
    var id = UUID()
    var name: String
    var genre: Genre
    var topic: Topic
    var size: ProjectSize
    var platform: Platform
    var shipDay: Int
    var stars: Int
    var reviewLine: String
    var lifetimeSales: Int = 0
    /// Days since ship — sales taper off, so this drives the tail-off curve.
    var daysSinceShip: Int = 0
    /// True once the tail is exhausted and it stops earning.
    var isRetired: Bool = false
}
