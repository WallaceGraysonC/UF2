import Foundation

/// A themed display or in-store event. Each theme pulls a particular crowd,
/// which is how a Drop converts curation work into reputation with the
/// people you actually want walking in.
enum DropTheme: String, CaseIterable, Identifiable {
    case horrorNight = "80s Horror VHS Night"
    case breakbeatWall = "Breakbeat 7-inch Wall"
    case importShelf = "Import RPG Shelf"
    case staffPicks = "Staff Picks Endcap"
    case listeningParty = "Listening Party"

    var id: String { rawValue }

    var prepDays: Int {
        switch self {
        case .staffPicks: return 2
        case .horrorNight, .breakbeatWall, .importShelf: return 3
        case .listeningParty: return 4
        }
    }

    var cost: Int {
        switch self {
        case .staffPicks: return 40
        case .breakbeatWall: return 90
        case .horrorNight: return 140
        case .importShelf: return 120
        case .listeningParty: return 260
        }
    }

    /// Stock in this format sells at a premium during the Drop.
    var format: MediaFormat {
        switch self {
        case .horrorNight: return .vhs
        case .breakbeatWall: return .vinyl
        case .importShelf: return .game
        case .staffPicks: return .cd
        case .listeningParty: return .vinyl
        }
    }

    /// Who this brings through the door.
    var draws: [CustomerArchetype] {
        switch self {
        case .horrorNight: return [.nostalgic, .collector]
        case .breakbeatWall: return [.crateDigger, .collector]
        case .importShelf: return [.completionist, .collector]
        case .staffPicks: return [.casual, .nostalgic]
        case .listeningParty: return [.crateDigger, .casual, .collector]
        }
    }

    /// How much curation this theme demands. A Listening Party with a thin
    /// display reads worse than a modest endcap done well.
    var expectation: Double {
        switch self {
        case .staffPicks: return 45
        case .breakbeatWall: return 70
        case .horrorNight: return 85
        case .importShelf: return 80
        case .listeningParty: return 120
        }
    }

    var blurb: String {
        switch self {
        case .horrorNight: return "Clamshells, a fog machine, and a TV in the window."
        case .breakbeatWall: return "Singles, sorted by break. DJs will dig for hours."
        case .importShelf: return "Region-locked and spine-labelled. Completionists notice."
        case .staffPicks: return "Cheap to run, hard to get wrong."
        case .listeningParty: return "Someone plays a record start to finish. High risk."
        }
    }
}
