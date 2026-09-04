import SwiftUI

/// Compact payouts/actions reference, sized for a watch sheet -- no example
/// cards (screen's too small to spare), just the name and a one-line
/// reminder of what it takes.
struct WatchRulesGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Entry: Identifiable {
        let id = UUID()
        let title: String
        let blurb: String
    }

    private let payouts: [Entry] = [
        Entry(title: "Blackjack", blurb: "Pays 3:2"),
        Entry(title: "Win", blurb: "Pays 1:1"),
        Entry(title: "Push", blurb: "Bet returned"),
        Entry(title: "Bust", blurb: "Hand lost"),
        Entry(title: "Insurance", blurb: "Pays 2:1 if dealer has Blackjack"),
        Entry(title: "Surrender", blurb: "Half your bet back"),
    ]

    private let actions: [Entry] = [
        Entry(title: "Hit", blurb: "Take another card"),
        Entry(title: "Stand", blurb: "End your turn"),
        Entry(title: "Double", blurb: "2x bet, one more card"),
        Entry(title: "Split", blurb: "Split a pair into two hands"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Payouts")
                    .font(.headline)
                ForEach(payouts) { entry in row(entry) }

                Text("Actions")
                    .font(.headline)
                    .padding(.top, 4)
                ForEach(actions) { entry in row(entry) }

                Text("Dealer hits to 17, stands on all 17s.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Button("Close") { dismiss() }
                    .font(.caption)
            }
            .padding(.horizontal, 4)
        }
    }

    private func row(_ entry: Entry) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(entry.title).font(.caption.bold())
            Spacer()
            Text(entry.blurb)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}
