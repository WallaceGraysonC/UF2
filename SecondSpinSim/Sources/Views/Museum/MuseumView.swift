import SwiftUI

/// The Museum Wall — stock taken off the market on purpose. Also where the
/// decision to close up shop lives, since retiring means deciding what the
/// shop was ultimately for.
struct MuseumView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game

    /// Handed up so the root can swap the run out for a fresh one.
    var onCloseUpShop: () -> Void = {}

    @State private var showingRetirement = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                wall
                mountable
                retirementCard
                Button { dismiss() } label: { Text("BACK TO THE FLOOR") }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
            }
            .padding(18)
            .padding(.top, 24)
        }
        .background(Theme.paper)
        .sheet(isPresented: $showingRetirement) {
            RetirementSheet(onConfirm: {
                showingRetirement = false
                onCloseUpShop()
            })
            .environment(game)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("THE MUSEUM WALL")
                .font(Theme.display(20))
                .foregroundStyle(Theme.ink)
            Text("\(game.museum.count)/\(game.museumCapacity) mounted · +\(game.museumDailyRep) Collector rep a day")
                .font(Theme.mono(9, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var wall: some View {
        VStack(spacing: 7) {
            if game.museum.isEmpty {
                Text("Nothing up yet. Whatever goes on this wall is never sold — that's the point of it.")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(Color(hex: 0xB7AF97))
                    )
            } else {
                ForEach(game.museum) { piece in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(piece.format.binColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(piece.format.abbreviation)
                                    .font(Theme.mono(7.5, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.9))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(piece.title)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            Text("MOUNTED DAY \(piece.dayMounted) · GAVE UP $\(piece.forgoneValue)")
                                .font(Theme.mono(7.5))
                                .foregroundStyle(Theme.inkSoft)
                        }

                        Spacer()

                        Text("+\(piece.dailyRepContribution)")
                            .font(Theme.mono(10, weight: .bold))
                            .foregroundStyle(Theme.plum)
                    }
                    .padding(10)
                    .background(Theme.cream)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.plum, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    /// Anything on the shelves is a candidate — the wall competes with the till.
    @ViewBuilder
    private var mountable: some View {
        if game.museumHasRoom {
            VStack(alignment: .leading, spacing: 7) {
                Text("MOUNT SOMETHING")
                    .font(Theme.display(13))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 6)

                if game.shelvedInventory.isEmpty {
                    Text("Nothing on the shelves to mount.")
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    ForEach(game.shelvedInventory) { item in
                        Button {
                            game.mount(item)
                        } label: {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.format.binColor)
                                    .frame(width: 24, height: 24)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.title)
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(Theme.ink)
                                        .lineLimit(1)
                                    if item.isRare {
                                        Text("GRAIL")
                                            .font(Theme.mono(7, weight: .bold))
                                            .foregroundStyle(Theme.red)
                                    }
                                }

                                Spacer()

                                Text("-$\(item.askingPrice(trendModifier: game.trendModifier(for: item.format)))")
                                    .font(Theme.mono(9, weight: .bold))
                                    .foregroundStyle(Theme.red)
                            }
                            .padding(9)
                            .background(Theme.cream)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var retirementCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("CLOSE UP SHOP")
                .font(Theme.display(14))
                .foregroundStyle(Theme.ink)

            Text("Retire this shop and bank what it was worth. You keep your perks and everything you've unlocked, and start again somewhere new. Nothing forces you — the score keeps climbing as long as you keep trading.")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("LEGACY SCORE IF YOU RETIRED TODAY")
                    .font(Theme.mono(8, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("\(game.legacyScore)")
                    .font(Theme.display(18))
                    .foregroundStyle(Theme.amberDeep)
            }

            Button {
                showingRetirement = true
            } label: {
                Text(game.canCloseUpShop ? "CLOSE UP SHOP…" : "MOUNT A PIECE FIRST")
            }
            .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
            .disabled(!game.canCloseUpShop)
            .opacity(game.canCloseUpShop ? 1 : 0.4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.amberDeep, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.top, 6)
    }
}

#Preview {
    MuseumView()
        .environment(GameState())
}
