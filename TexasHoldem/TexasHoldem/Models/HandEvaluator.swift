import Foundation

enum HandCategory: Int, Comparable, Codable {
    case highCard = 0
    case pair
    case twoPair
    case threeOfAKind
    case straight
    case flush
    case fullHouse
    case fourOfAKind
    case straightFlush

    static func < (lhs: HandCategory, rhs: HandCategory) -> Bool { lhs.rawValue < rhs.rawValue }

    var displayName: String {
        switch self {
        case .highCard: return "High Card"
        case .pair: return "Pair"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        }
    }
}

/// Ranks a 5-card hand. `tiebreakers` is ordered most-significant first,
/// e.g. for a full house [tripsRank, pairRank]; for high card, the five
/// ranks in descending order.
struct HandRank: Comparable, Codable {
    let category: HandCategory
    let tiebreakers: [Int]

    static func < (lhs: HandRank, rhs: HandRank) -> Bool {
        if lhs.category != rhs.category { return lhs.category < rhs.category }
        for (a, b) in zip(lhs.tiebreakers, rhs.tiebreakers) where a != b {
            return a < b
        }
        return false
    }

    static func == (lhs: HandRank, rhs: HandRank) -> Bool {
        lhs.category == rhs.category && lhs.tiebreakers == rhs.tiebreakers
    }
}

enum HandEvaluator {
    /// Evaluates the best possible 5-card hand out of 5-7 given cards
    /// (typically 2 hole cards + up to 5 community cards).
    static func bestHand(from cards: [Card]) -> HandRank {
        precondition(cards.count >= 5, "Need at least 5 cards to evaluate a hand")
        var best: HandRank?
        for combo in combinations(cards, choose: 5) {
            let rank = evaluateFive(combo)
            if best == nil || rank > best! { best = rank }
        }
        return best!
    }

    private static func evaluateFive(_ cards: [Card]) -> HandRank {
        let ranksDescending = cards.map { $0.rank.rawValue }.sorted(by: >)
        let isFlush = Set(cards.map { $0.suit }).count == 1

        let straightHigh = straightHighCard(ranksDescending)
        let isStraight = straightHigh != nil

        var countsByRank: [Int: Int] = [:]
        for r in ranksDescending { countsByRank[r, default: 0] += 1 }
        // Groups sorted by (count desc, rank desc)
        let groups = countsByRank.sorted { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value > rhs.value }
            return lhs.key > rhs.key
        }
        let counts = groups.map { $0.value }

        if isStraight && isFlush {
            return HandRank(category: .straightFlush, tiebreakers: [straightHigh!])
        }
        if counts == [4, 1] {
            return HandRank(category: .fourOfAKind, tiebreakers: groups.map { $0.key })
        }
        if counts == [3, 2] {
            return HandRank(category: .fullHouse, tiebreakers: groups.map { $0.key })
        }
        if isFlush {
            return HandRank(category: .flush, tiebreakers: ranksDescending)
        }
        if isStraight {
            return HandRank(category: .straight, tiebreakers: [straightHigh!])
        }
        if counts == [3, 1, 1] {
            return HandRank(category: .threeOfAKind, tiebreakers: groups.map { $0.key })
        }
        if counts == [2, 2, 1] {
            return HandRank(category: .twoPair, tiebreakers: groups.map { $0.key })
        }
        if counts == [2, 1, 1, 1] {
            return HandRank(category: .pair, tiebreakers: groups.map { $0.key })
        }
        return HandRank(category: .highCard, tiebreakers: ranksDescending)
    }

    /// Returns the high card of the straight if the given descending, unique-checked
    /// rank list forms a straight (handles wheel A-2-3-4-5), else nil.
    private static func straightHighCard(_ ranksDescending: [Int]) -> Int? {
        let unique = Array(Set(ranksDescending)).sorted(by: >)
        guard unique.count == 5 else { return nil }
        if unique[0] - unique[4] == 4 { return unique[0] }
        // Wheel: A,5,4,3,2
        if unique == [14, 5, 4, 3, 2] { return 5 }
        return nil
    }

    private static func combinations<T>(_ array: [T], choose k: Int) -> [[T]] {
        guard k <= array.count else { return [] }
        if k == 0 { return [[]] }
        if k == array.count { return [array] }
        var result: [[T]] = []
        func helper(_ start: Int, _ chosen: [T]) {
            if chosen.count == k {
                result.append(chosen)
                return
            }
            guard start < array.count else { return }
            for i in start..<array.count {
                helper(i + 1, chosen + [array[i]])
            }
        }
        helper(0, [])
        return result
    }
}
