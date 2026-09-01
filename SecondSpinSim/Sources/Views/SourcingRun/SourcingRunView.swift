import SwiftUI

/// Three states in one screen: plan a run, watch one in progress, or grade
/// the haul it brought back. Only one run is ever out at a time.
struct SourcingRunView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game
    @State private var selectedTab: AppTab = .source

    @State private var chosenLocation: SourcingLocation = .estateSale
    @State private var chosenBuyerIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            hud
            content
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.paper)
        .onChange(of: selectedTab) { _, newValue in
            if newValue != .source { dismiss() }
        }
    }

    // MARK: HUD

    private var hud: some View {
        HStack {
            Button { dismiss() } label: {
                Text("‹ BACK").font(Theme.mono(10, weight: .semibold))
            }
            Spacer()
            HUDStatView(value: "$\(game.cash)", label: "CASH", valueSize: 14)
            Spacer()
            HUDStatView(value: statusValue, label: "SOURCING", valueSize: 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 54)
        .padding(.bottom, 12)
        .background(Theme.ink)
        .foregroundStyle(Theme.cream)
    }

    private var statusValue: String {
        if !game.pendingHaul.isEmpty { return "\(game.pendingHaul.count) TO GRADE" }
        if let run = game.activeRun { return run.dayLabel }
        return "IDLE"
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if !game.pendingHaul.isEmpty {
            haulGrading
        } else if let run = game.activeRun {
            runInProgress(run)
        } else {
            runPlanner
        }
    }

    // MARK: State 1 — plan a run

    private var runPlanner: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("PLAN A RUN")
                    .font(Theme.display(14))
                    .foregroundStyle(Theme.ink)

                VStack(spacing: 7) {
                    ForEach(SourcingLocation.allCases) { location in
                        LocationCard(
                            location: location,
                            isSelected: chosenLocation == location,
                            affordable: game.canAfford(location),
                            onTap: { chosenLocation = location }
                        )
                    }
                }

                Text("SEND BUYERS")
                    .font(Theme.display(13))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 4)

                VStack(spacing: 6) {
                    ForEach(game.buyers) { buyer in
                        BuyerToggleRow(
                            buyer: buyer,
                            isSelected: chosenBuyerIDs.contains(buyer.id),
                            onTap: { toggle(buyer.id) }
                        )
                    }
                }

                Button {
                    game.startRun(location: chosenLocation, buyerIDs: Array(chosenBuyerIDs))
                    chosenBuyerIDs = []
                } label: {
                    Text(startLabel)
                }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
                .disabled(!canStart)
                .opacity(canStart ? 1 : 0.4)
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
    }

    private var canStart: Bool {
        !chosenBuyerIDs.isEmpty && game.canAfford(chosenLocation)
    }

    private var startLabel: String {
        if chosenBuyerIDs.isEmpty { return "PICK A BUYER" }
        if !game.canAfford(chosenLocation) { return "NOT ENOUGH CASH" }
        return "SEND OUT — $\(chosenLocation.cost)"
    }

    private func toggle(_ id: UUID) {
        if chosenBuyerIDs.contains(id) {
            chosenBuyerIDs.remove(id)
        } else {
            chosenBuyerIDs.insert(id)
        }
    }

    // MARK: State 2 — run in progress

    private func runInProgress(_ run: SourcingRun) -> some View {
        VStack(spacing: 16) {
            Text(run.location.rawValue.uppercased())
                .font(Theme.display(15))
                .foregroundStyle(Theme.ink)

            Text(run.location.blurb)
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                Text(run.dayLabel)
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.amberDeep)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0xD7D0BE))
                        Capsule().fill(Theme.amberDeep)
                            .frame(width: geo.size.width * run.progress)
                    }
                }
                .frame(height: 9)

                Text("Out digging. End the day to move the run along.")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(16)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 6) {
                Text("CREW")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
                ForEach(run.buyerIDs.compactMap { game.staffMember(id: $0) }) { buyer in
                    HStack {
                        Text(buyer.name.uppercased())
                            .font(Theme.mono(9, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("RARITY \(buyer.raritySense) · FATIGUE \(buyer.fatigue)")
                            .font(Theme.mono(8))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
    }

    // MARK: State 3 — grade the haul

    @ViewBuilder
    private var haulGrading: some View {
        if let item = game.pendingHaul.first {
            VStack(spacing: 14) {
                HStack {
                    Text("HAUL — \(game.pendingHaul.count) LEFT")
                        .font(Theme.display(13))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if item.isRare {
                        Text("GRAIL")
                            .font(Theme.mono(8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Theme.red)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }

                HaulItemCard(item: item, trendModifier: game.trendModifier(for: item.format))

                VStack(spacing: 8) {
                    Button {
                        game.shelve(item)
                    } label: {
                        Text("SHELVE IT")
                    }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .primary))

                    HStack(spacing: 8) {
                        Button {
                            game.sendToBench(item)
                        } label: {
                            Text(game.benchHasRoom ? "TO BENCH" : "BENCH FULL")
                        }
                        .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
                        .disabled(!game.benchHasRoom)
                        .opacity(game.benchHasRoom ? 1 : 0.4)

                        Button {
                            game.discard(item)
                        } label: {
                            Text("BIN IT")
                        }
                        .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
}

// MARK: - Components

private struct LocationCard: View {
    let location: SourcingLocation
    let isSelected: Bool
    let affordable: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(location.rawValue.uppercased())
                        .font(Theme.display(13))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("$\(location.cost)")
                        .font(Theme.mono(10, weight: .bold))
                        .foregroundStyle(affordable ? Theme.green : Theme.red)
                }

                Text(location.blurb)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    tag("\(location.days)D")
                    tag("\(location.itemRange.lowerBound)-\(location.itemRange.upperBound) ITEMS")
                    tag("RARE \(Int(location.rareChance * 100))%")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .background(Theme.cream)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Theme.amberDeep : Theme.line,
                            lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(Theme.mono(7.5, weight: .semibold))
            .foregroundStyle(Theme.inkSoft)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.line, lineWidth: 1))
    }
}

private struct BuyerToggleRow: View {
    let buyer: StaffMember
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(isSelected ? Theme.amberDeep : Color(hex: 0xD7D0BE))
                    .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(buyer.name.uppercased())
                        .font(Theme.mono(10, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("VOL \(buyer.volume) · RARITY \(buyer.raritySense) · FATIGUE \(buyer.fatigue)")
                        .font(Theme.mono(8))
                        .foregroundStyle(buyer.fatigue >= 60 ? Theme.red : Theme.inkSoft)
                }

                Spacer()

                Text(buyer.specialization.abbreviation)
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(buyer.specialization.binColor)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .padding(10)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

private struct HaulItemCard: View {
    let item: InventoryItem
    let trendModifier: Double

    var body: some View {
        VStack(spacing: 11) {
            RecordDiscView()
                .frame(width: 78, height: 78)

            Text(item.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Text(item.format.abbreviation)
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(item.format.binColor)
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                Text(item.grade.label)
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(item.grade.color)
            }

            HStack {
                Text("ASKING")
                    .font(Theme.mono(8, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("$\(item.askingPrice(trendModifier: trendModifier))")
                    .font(Theme.display(16))
                    .foregroundStyle(Theme.green)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

/// Simple vinyl/laserdisc stand-in — concentric rings and a label hole.
private struct RecordDiscView: View {
    var body: some View {
        ZStack {
            Circle().fill(Theme.ink)
            Circle().stroke(Theme.inkSoft.opacity(0.5), lineWidth: 1).padding(10)
            Circle().stroke(Theme.inkSoft.opacity(0.5), lineWidth: 1).padding(22)
            Circle().fill(Theme.cream).frame(width: 18, height: 18)
        }
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }
}

#Preview {
    SourcingRunView()
        .environment(GameState())
}
