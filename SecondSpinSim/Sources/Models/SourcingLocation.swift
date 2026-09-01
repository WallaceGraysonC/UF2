import Foundation

/// Where buyers go to find stock. Cheap locations churn out common filler;
/// expensive ones are where grails actually turn up — which is the whole
/// tension of deciding what a run is worth.
enum SourcingLocation: String, CaseIterable, Identifiable, Codable {
    case fleaMarket = "Flea Market"
    case estateSale = "Estate Sale"
    case storageAuction = "Storage Auction"
    case distributor = "Distributor Order"
    case collectorTip = "Collector Tip-off"

    var id: String { rawValue }

    /// Paid up front when the run starts.
    var cost: Int {
        switch self {
        case .fleaMarket: return 60
        case .estateSale: return 180
        case .storageAuction: return 320
        case .distributor: return 250
        case .collectorTip: return 600
        }
    }

    var days: Int {
        switch self {
        case .fleaMarket: return 1
        case .estateSale, .distributor: return 2
        case .storageAuction, .collectorTip: return 3
        }
    }

    var itemRange: ClosedRange<Int> {
        switch self {
        case .fleaMarket: return 2...4
        case .estateSale: return 4...7
        case .storageAuction: return 6...11
        case .distributor: return 5...8
        case .collectorTip: return 1...3
        }
    }

    /// Base odds any single item in the haul is a rare — buyers' Rarity Sense
    /// raises this, so who you send matters as much as where you send them.
    var rareChance: Double {
        switch self {
        case .fleaMarket: return 0.03
        case .estateSale: return 0.08
        case .storageAuction: return 0.06
        case .distributor: return 0.0
        case .collectorTip: return 0.35
        }
    }

    /// What tends to turn up here.
    var formats: [MediaFormat] {
        switch self {
        case .fleaMarket: return [.vhs, .cd, .cd, .vinyl]
        case .estateSale: return [.vinyl, .vinyl, .cd, .vhs, .laserdisc]
        case .storageAuction: return [.vhs, .game, .cd, .vinyl, .laserdisc]
        case .distributor: return [.cd, .cd, .vinyl]
        case .collectorTip: return [.laserdisc, .vinyl, .game]
        }
    }

    /// Condition of what you're likely to dig out, before restoration.
    var conditionRange: ClosedRange<Double> {
        switch self {
        case .fleaMarket: return 0.05...0.55
        case .estateSale: return 0.15...0.8
        case .storageAuction: return 0.0...0.65
        case .distributor: return 0.75...1.0
        case .collectorTip: return 0.3...0.95
        }
    }

    var blurb: String {
        switch self {
        case .fleaMarket: return "Picked over, but cheap and quick."
        case .estateSale: return "Whole collections, one owner. Where sleepers hide."
        case .storageAuction: return "Buy the unit blind. Volume, mostly junk."
        case .distributor: return "Sealed and reliable. No surprises either way."
        case .collectorTip: return "One phone call. Small haul, real stakes."
        }
    }
}
