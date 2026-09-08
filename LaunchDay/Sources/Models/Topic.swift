import Foundation

/// What the game is about. The other half of the genre×topic pairing.
enum Topic: String, CaseIterable, Identifiable, Codable {
    case fantasy = "Fantasy"
    case sciFi = "Sci-Fi"
    case war = "War"
    case horror = "Horror"
    case sports = "Sports"
    case music = "Music"

    var id: String { rawValue }
}
