import SwiftUI

/// Compact best-to-worst hand reference, sized for a watch sheet -- no
/// example cards (screen's too small to spare), just the name and a
/// one-line reminder of what it takes.
struct WatchHandRankingsView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Entry: Identifiable {
        let id = UUID()
        let category: HandCategory
        let blurb: String
    }

    private let entries: [Entry] = [
        Entry(category: .straightFlush, blurb: "5 in a row, same suit"),
        Entry(category: .fourOfAKind, blurb: "4 of the same rank"),
        Entry(category: .fullHouse, blurb: "3 of a kind + a pair"),
        Entry(category: .flush, blurb: "5 of the same suit"),
        Entry(category: .straight, blurb: "5 in a row, mixed suits"),
        Entry(category: .threeOfAKind, blurb: "3 of the same rank"),
        Entry(category: .twoPair, blurb: "2 separate pairs"),
        Entry(category: .pair, blurb: "2 of the same rank"),
        Entry(category: .highCard, blurb: "Highest card plays"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Hand Rankings")
                    .font(.headline)
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    HStack(alignment: .top, spacing: 6) {
                        Text("\(index + 1).")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.category.displayName).font(.caption.bold())
                            Text(entry.blurb).font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
                Button("Close") { dismiss() }
                    .font(.caption)
            }
            .padding(.horizontal, 4)
        }
    }
}
