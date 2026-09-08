import Foundation

/// A desk in the studio. Two stats — Design and Tech — are the whole of it,
/// on purpose: the real game is in the project and the pairing, not in
/// managing six numbers per person.
struct Employee: Identifiable, Codable {
    var id = UUID()
    var name: String
    var design: Int
    var tech: Int
    /// How many points a work session actually produces — separate from the
    /// raw stats, so a fast junior can still outpace a slow senior.
    var speed: Int
    /// A favourite genre gives a flat bonus while working it.
    var favoriteGenre: Genre

    var dailyWage: Int

    static func starterRoster() -> [Employee] {
        [
            Employee(name: "Priya", design: 42, tech: 24, speed: 55, favoriteGenre: .rpg, dailyWage: 45),
            Employee(name: "Dev", design: 22, tech: 46, speed: 50, favoriteGenre: .strategy, dailyWage: 45),
            Employee(name: "Mara", design: 30, tech: 30, speed: 60, favoriteGenre: .puzzle, dailyWage: 40)
        ]
    }

    /// A fresh face for the hiring board — better and pricier as the studio grows.
    static func candidate(studioLevel: Int) -> Employee {
        let names = ["Ana", "Bex", "Cyrus", "Dot", "Emil", "Fitz", "Gio", "Hana",
                     "Ike", "Jules", "Kit", "Lore", "Moss", "Nell", "Omar", "Pia"]
        let base = 18 + studioLevel * 5
        func stat() -> Int { min(99, Int.random(in: base...(base + 24))) }

        let design = stat()
        let tech = stat()
        let speed = min(99, Int.random(in: (base - 5)...(base + 15)))
        let wage = 25 + (design + tech) / 4

        return Employee(name: names.randomElement() ?? "Sam", design: design, tech: tech,
                        speed: speed, favoriteGenre: Genre.allCases.randomElement() ?? .action,
                        dailyWage: wage)
    }

    var signingFee: Int { (design + tech) * 5 }
}
