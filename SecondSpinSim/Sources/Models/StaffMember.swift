import Foundation

/// The six stats a convention can raise.
enum TrainableStat: String, CaseIterable, Identifiable, Codable {
    case volume = "Volume"
    case raritySense = "Rarity Sense"
    case negotiation = "Negotiation"
    case restoration = "Restoration"
    case design = "Design"
    case hype = "Hype"

    var id: String { rawValue }
}

enum StaffRole: String, CaseIterable, Identifiable, Codable {
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
struct StaffMember: Identifiable, Codable {
    var id = UUID()
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

    /// Away at a convention. Training takes real days — they can't be
    /// assigned to anything while it runs, which is the point.
    var trainingDaysRemaining: Int = 0
    var trainingStat: TrainableStat?

    var isTraining: Bool { trainingDaysRemaining > 0 }

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

    /// Read/write access to a stat by its trainable name.
    mutating func raise(_ stat: TrainableStat, by amount: Int) {
        switch stat {
        case .volume: volume = min(99, volume + amount)
        case .raritySense: raritySense = min(99, raritySense + amount)
        case .negotiation: negotiation = min(99, negotiation + amount)
        case .restoration: restoration = min(99, restoration + amount)
        case .design: design = min(99, design + amount)
        case .hype: hype = min(99, hype + amount)
        }
    }

    func value(of stat: TrainableStat) -> Int {
        switch stat {
        case .volume: return volume
        case .raritySense: return raritySense
        case .negotiation: return negotiation
        case .restoration: return restoration
        case .design: return design
        case .hype: return hype
        }
    }

    /// A fresh face for the hiring board — stats scale with how far along
    /// the shop is, so later hires are better and cost more.
    static func candidate(shopLevel: Int) -> StaffMember {
        let firstNames = ["Ana", "Bex", "Cyrus", "Dot", "Emil", "Fitz", "Gio", "Hana",
                          "Ike", "Jules", "Kit", "Lore", "Moss", "Nell", "Omar", "Pia",
                          "Quill", "Rae", "Sol", "Tam", "Uma", "Vic", "Wes", "Yuna"]
        let role = StaffRole.allCases.randomElement() ?? .buyer
        let base = 18 + shopLevel * 4
        func stat() -> Int { min(99, Int.random(in: base...(base + 22))) }

        var member = StaffMember(
            name: firstNames.randomElement() ?? "Sam",
            role: role,
            specialization: MediaFormat.allCases.randomElement() ?? .cd,
            volume: stat(), raritySense: stat(), negotiation: stat(),
            restoration: stat(), design: stat(), hype: stat()
        )
        // Their role's own stat runs ahead of the rest.
        switch role {
        case .buyer: member.raise(.raritySense, by: 12)
        case .tech: member.raise(.restoration, by: 12)
        case .curator: member.raise(.design, by: 12)
        }
        member.dailyWage = 30 + member.primaryStat.value / 2
        return member
    }

    /// One-off signing fee, separate from the daily wage.
    var signingFee: Int { primaryStat.value * 8 }

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
