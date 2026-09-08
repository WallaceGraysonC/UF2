import Foundation

/// The office ladder. Short on purpose — five rungs, each buying more desks
/// and a bit more room, gated on cash and headcount together so cash alone
/// never clears it.
struct StudioUpgrade: Identifiable {
    var level: Int
    var id: Int { level }

    var title: String
    var detail: String
    var cost: Int
    var staffRequired: Int
    var deskCapacity: Int

    static let ladder: [StudioUpgrade] = [
        StudioUpgrade(level: 1, title: "Garage", detail: "Where it starts. Three desks, one window.",
                     cost: 0, staffRequired: 0, deskCapacity: 3),
        StudioUpgrade(level: 2, title: "Shared Office", detail: "A real lease. Room for the team to grow.",
                     cost: 4_000, staffRequired: 3, deskCapacity: 5),
        StudioUpgrade(level: 3, title: "Own Floor", detail: "No more shared kitchen.",
                     cost: 12_000, staffRequired: 5, deskCapacity: 8),
        StudioUpgrade(level: 4, title: "Studio Building", detail: "A sign out front with your name on it.",
                     cost: 30_000, staffRequired: 8, deskCapacity: 12),
        StudioUpgrade(level: 5, title: "Campus", detail: "You made it.",
                     cost: 80_000, staffRequired: 12, deskCapacity: 18)
    ]

    static func upgrade(toReach level: Int) -> StudioUpgrade? {
        ladder.first { $0.level == level }
    }
}
