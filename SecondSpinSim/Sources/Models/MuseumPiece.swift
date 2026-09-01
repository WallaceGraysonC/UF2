import Foundation

/// An item taken off the market for good. You forfeit its cash value; in
/// exchange it draws Collectors every day it stays on the wall.
struct MuseumPiece: Identifiable, Codable {
    var id = UUID()
    var title: String
    var format: MediaFormat
    var grade: ConditionGrade
    /// What it would have sold for — drives both the daily rep and the
    /// legacy score, so mounting something genuinely valuable costs you.
    var forgoneValue: Int
    var dayMounted: Int

    /// Daily Collector reputation, scaled so a $400 grail is worth noticeably
    /// more than a $30 shelf-filler but doesn't run away with it.
    var dailyRepContribution: Int {
        max(1, Int((Double(forgoneValue) / 120.0).rounded()))
    }

    init(from item: InventoryItem, askingPrice: Int, day: Int) {
        self.title = item.title
        self.format = item.format
        self.grade = item.grade
        self.forgoneValue = askingPrice
        self.dayMounted = day
    }
}
