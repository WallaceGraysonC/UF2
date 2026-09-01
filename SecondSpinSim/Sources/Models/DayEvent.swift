import SwiftUI

/// One thing that happened during a day, recorded as the simulation runs so
/// the floor can narrate it afterwards. The sim stays authoritative — these
/// are a replay of what already happened, not the source of it.
struct DayEvent: Identifiable {
    var id = UUID()
    /// The big floating number, e.g. "+$42" or "+3".
    var headline: String
    /// The quieter line under it.
    var detail: String
    var tint: Color
    /// Which staff station it floats up from.
    var lane: Int
}

/// All the timing for the day-resolution animation, in one place so the feel
/// can be tuned without hunting through the view.
enum DayPacing {
    /// Gap between one popup appearing and the next.
    static let betweenEvents: Double = 0.42
    /// How long a single popup stays on screen.
    static let popupLifetime: Double = 1.1
    /// How far it drifts upward.
    static let popupRise: CGFloat = 46
    /// Beat before the report sheet appears after the last popup.
    static let beforeReport: Double = 0.55
    /// Cap so a huge day doesn't take forever — beyond this, events are
    /// played faster rather than dropped.
    static let maxDuration: Double = 6.0
}
