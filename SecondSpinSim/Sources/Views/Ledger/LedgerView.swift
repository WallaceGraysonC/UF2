import SwiftUI

struct LedgerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game
    @State private var selectedTab: AppTab = .ledger

    var body: some View {
        VStack(spacing: 0) {
            hud
            content
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.paper)
        .onChange(of: selectedTab) { _, newValue in
            if newValue != .ledger { dismiss() }
        }
    }

    private var hud: some View {
        HStack {
            Button { dismiss() } label: {
                Text("‹ BACK").font(Theme.mono(10, weight: .semibold))
            }
            Spacer()
            HUDStatView(value: "$\(game.cash)", label: "CASH", valueSize: 14)
            Spacer()
            HUDStatView(value: "REP \(game.overallReputation)", label: "OVERALL", valueSize: 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 54)
        .padding(.bottom, 12)
        .background(Theme.ink)
        .foregroundStyle(Theme.cream)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                reputationSection
                booksSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
    }

    // MARK: Reputation

    private var reputationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REPUTATION BY CROWD")
                .font(Theme.display(13))
                .foregroundStyle(Theme.ink)

            VStack(spacing: 6) {
                ForEach(CustomerArchetype.allCases) { archetype in
                    HStack(spacing: 8) {
                        Text(archetype.rawValue.uppercased())
                            .font(Theme.mono(8, weight: .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .frame(width: 92, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(hex: 0xD7D0BE))
                                Capsule()
                                    .fill(archetype.color)
                                    .frame(width: geo.size.width * (Double(game.reputation[archetype] ?? 0) / 100.0))
                            }
                        }
                        .frame(height: 6)

                        Text("\(game.reputation[archetype] ?? 0)")
                            .font(Theme.mono(9, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 22, alignment: .trailing)
                    }
                }
            }
            .padding(12)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: Books

    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("THE BOOKS")
                    .font(Theme.display(13))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("TRENDING: \(game.trendingFormat.abbreviation)")
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Theme.amberDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            if game.ledger.isEmpty {
                Text("No entries yet — end a day on the Shop Floor.")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(Color(hex: 0xB7AF97))
                    )
            } else {
                VStack(spacing: 0) {
                    ForEach(game.ledger.reversed()) { entry in
                        HStack(spacing: 10) {
                            Text("D\(entry.day)")
                                .font(Theme.mono(8, weight: .bold))
                                .foregroundStyle(Theme.inkSoft)
                                .frame(width: 26, alignment: .leading)

                            Text(entry.detail)
                                .font(.system(size: 11.5))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)

                            Spacer(minLength: 8)

                            Text(entry.amountText)
                                .font(Theme.mono(10, weight: .bold))
                                .foregroundStyle(entry.color)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .overlay(
                            Rectangle().fill(Theme.line.opacity(0.6)).frame(height: 1),
                            alignment: .bottom
                        )
                    }
                }
                .background(Theme.cream)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

#Preview {
    LedgerView()
        .environment(GameState())
}
