import Foundation

enum StaffRole: String, CaseIterable, Identifiable {
    case buyer = "Buyer"
    case tech = "Tech"
    case curator = "Curator"

    var id: String { rawValue }

    /// What this role actually does on a project screen.
    var duty: String {
        switch self {
        case .buyer: return "Runs Sourcing"
        case .tech: return "Works the Bench"
        case .curator: return "Runs Drops & floor"
        }
    }
}

/// A staff member on the roster. Six stats mirror the design reference:
/// Volume / Rarity Sense / Negotiation for Buyers, Restoration for Techs,
/// Design / Hype for Curators. Everyone has all six; roles govern growth.
struct StaffMember: Identifiable {
    let id = UUID()
    var name: String
    var role: StaffRole
    /// Format familiarity — multiplies stat output when working this format.
    var specialization: MediaFormat

    var volume: Int = 20
    var raritySense: Int = 20
    var negotiation: Int = 20
    var restoration: Int = 20
    var design: Int = 20
    var hype: Int = 20

    /// 0...100. Climbs while assigned, falls on a rest day; high fatigue
    /// cuts output, which is what stops one staffer being chained forever.
    var fatigue: Int = 0
    var dailyWage: Int = 40

    /// The stat this role is actually judged on, for roster display.
    var primaryStat: (label: String, value: Int) {
        switch role {
        case .buyer: return ("RARITY SENSE", raritySense)
        case .tech: return ("RESTORATION", restoration)
        case .curator: return ("DESIGN", design)
        }
    }

    /// Output multiplier from fatigue — full strength when rested, 55% when spent.
    var effectiveness: Double {
        1.0 - (Double(fatigue) / 100.0) * 0.45
    }

    static func starterRoster() -> [StaffMember] {
        [
            StaffMember(name: "Mara", role: .buyer, specialization: .vinyl,
                        volume: 41, raritySense: 58, negotiation: 34, dailyWage: 55),
            StaffMember(name: "Priya", role: .tech, specialization: .laserdisc,
                        restoration: 62, fatigue: 20, dailyWage: 60),
            StaffMember(name: "Dev", role: .buyer, specialization: .game,
                        volume: 36, raritySense: 29, negotiation: 45, dailyWage: 40),
            StaffMember(name: "Court", role: .curator, specialization: .vhs,
                        design: 51, hype: 44, dailyWage: 50)
        ]
    }
}
