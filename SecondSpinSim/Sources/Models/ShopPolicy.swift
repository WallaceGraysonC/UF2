import Foundation

/// Standing orders. The shop runs itself against these, so a day needs no
/// input unless something falls outside them — which is the whole point:
/// you set how the place is run, not what every person does every morning.
struct ShopPolicy: Codable {

    // MARK: Sourcing

    /// Keep a buying trip going at all times.
    var autoSource: Bool = true
    /// Where to send them when one finishes.
    var sourceLocation: SourcingLocation = .fleaMarket
    /// Don't start a run that would drop the till below this.
    var cashFloor: Int = 200

    // MARK: The bench

    /// Put idle Techs on unstaffed jobs automatically.
    var autoStaffBench: Bool = true

    // MARK: Grading the haul

    /// Anything this grade or better goes straight out on the floor.
    var shelveAtOrAbove: ConditionGrade = .good
    /// Anything below it goes to the bench when there's room.
    var benchBelowThreshold: Bool = true
    /// Junk under this asking price gets binned rather than clogging shelves.
    var binUnderValue: Int = 4
    /// Grails always come to you, whatever the rest of the policy says —
    /// the find is the best moment in the game and shouldn't be automated.
    var alwaysAskOnGrails: Bool = true

    // MARK: Drops

    /// Keep a Drop in prep whenever curators are free.
    var autoDrops: Bool = false
    var dropTheme: DropTheme = .staffPicks
    var dropAngle: DropAngle = .localBands

    // MARK: The clock

    /// Seconds of real time per in-game day.
    var secondsPerDay: Double = 2.0
    /// Whether the clock is running.
    var isRunning: Bool = false
}

/// The three clock speeds offered on the floor.
enum ClockSpeed: String, CaseIterable, Identifiable {
    case steady, brisk, fast

    var id: String { rawValue }

    var secondsPerDay: Double {
        switch self {
        case .steady: return 3.0
        case .brisk: return 1.5
        case .fast: return 0.6
        }
    }

    var label: String {
        switch self {
        case .steady: return "1x"
        case .brisk: return "2x"
        case .fast: return "5x"
        }
    }
}
