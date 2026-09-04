import Foundation

enum Suit: String, CaseIterable, Codable {
    case clubs, diamonds, hearts, spades

    var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        case .spades: return "♠"
        }
    }

    var isRed: Bool { self == .diamonds || self == .hearts }
}

enum Rank: Int, CaseIterable, Codable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen = 12, king = 13, ace = 14

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        }
    }

    /// Blackjack value before any soft-ace adjustment: face cards count as
    /// 10, an ace counts as 11 (`BlackjackHandEvaluator` knocks aces down to
    /// 1 one at a time if the hand would otherwise bust).
    var blackjackValue: Int {
        switch self {
        case .jack, .queen, .king: return 10
        case .ace: return 11
        default: return rawValue
        }
    }
}

struct Card: Identifiable, Codable, Hashable {
    var id: String { "\(rank.rawValue)-\(suit.rawValue)" }
    let rank: Rank
    let suit: Suit

    /// Spoken form for VoiceOver -- "♠" and "A" read as nothing useful.
    var spokenName: String {
        let rankWord: String
        switch rank {
        case .jack: rankWord = "Jack"
        case .queen: rankWord = "Queen"
        case .king: rankWord = "King"
        case .ace: rankWord = "Ace"
        default: rankWord = rank.label
        }
        return "\(rankWord) of \(suit.rawValue)"
    }
}
