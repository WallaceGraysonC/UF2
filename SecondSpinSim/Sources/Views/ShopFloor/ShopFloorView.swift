import SwiftUI

struct ShopFloorView: View {
    @Environment(GameState.self) private var game
    @State private var selectedTab: AppTab = .floor
    @State private var showingReport = false
    @State private var showingUpgrade = false
    @State private var showingAds = false

    /// Day-resolution playback.
    @State private var popups: [DayEvent] = []
    @State private var isResolving = false
    @State private var resolutionTask: Task<Void, Never>?

    /// Called when the player taps a tab other than Floor. Floor is the hub
    /// this view already renders, so navigating away is the parent's job.
    var onNavigate: (AppTab) -> Void = { _ in }
    /// The Museum Wall isn't a tab — it's reached from the floor at Level 10.
    var onOpenMuseum: () -> Void = {}
    /// Equipped cosmetics, resolved from the legacy profile by the root.
    var skin: ShopSkin = .default

    var body: some View {
        VStack(spacing: 0) {
            hud
            floorContent
            ShopStatBar()
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.paper)
        .onChange(of: selectedTab) { _, newValue in
            guard newValue != .floor else { return }
            onNavigate(newValue)
            selectedTab = .floor
        }
        .onDisappear {
            // Don't leave a playback task running behind a pushed screen.
            resolutionTask?.cancel()
            resolutionTask = nil
        }
        .sheet(isPresented: $showingReport) {
            DayReportSheet(report: game.lastReport)
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradeSheet()
                .environment(game)
        }
        .sheet(isPresented: $showingAds) {
            AdvertisingSheet()
                .environment(game)
        }
    }

    // MARK: HUD

    private var hud: some View {
        HStack {
            HUDStatView(value: "DAY \(game.day)", label: "SEASON 1")
            Spacer()
            HUDStatView(value: "$\(game.cash)", label: "CASH")
            Spacer()
            Button { showingUpgrade = true } label: {
                HUDStatView(value: "LV. \(game.shopLevel)", label: "SHOP")
            }
            .buttonStyle(.plain)
            .overlay(alignment: .topTrailing) {
                // A dot when the next rung is actually affordable.
                if let next = game.nextUpgrade, game.canUpgrade(to: next) {
                    Circle().fill(Theme.red).frame(width: 7, height: 7).offset(x: 6, y: -2)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 54)
        .padding(.bottom, 12)
        .background(Theme.ink)
        .foregroundStyle(Theme.cream)
    }

    // MARK: Floor

    private var floorContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SHOP FLOOR")
                    .font(Theme.display(14))
                    .foregroundStyle(skin.sign)
                Spacer()
                if game.museumUnlocked {
                    Button(action: onOpenMuseum) {
                        Text("THE WALL")
                            .font(Theme.mono(9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Theme.plum)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    .buttonStyle(.plain)
                }
                Text("TRENDING: \(game.trendingFormat.abbreviation)")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Theme.red)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }

            shelfGrid

            statusStrip

            floorScene

            endDayButton
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var shelfGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 6)
        let stock = game.shelvedInventory
        return LazyVGrid(columns: columns, spacing: 5) {
            ForEach(0..<game.binCapacity, id: \.self) { index in
                ShelfBinView(item: index < stock.count ? stock[index] : nil)
            }
        }
    }

    /// What's outstanding right now — a haul waiting to be graded, or a run
    /// still out. Tapping jumps to Sourcing to deal with it.
    @ViewBuilder
    private var statusStrip: some View {
        if !game.pendingHaul.isEmpty {
            statusPill(text: "\(game.pendingHaul.count) ITEMS TO GRADE",
                       color: Theme.red, destination: .source)
        } else if let drop = game.activeDrop {
            statusPill(text: "\(drop.theme.rawValue.uppercased()) — \(drop.dayLabel)",
                       color: Theme.plum, destination: .drops)
        } else if let run = game.activeRun {
            statusPill(text: "\(run.location.rawValue.uppercased()) — \(run.dayLabel)",
                       color: Theme.amberDeep, destination: .source)
        }
    }

    private func statusPill(text: String, color: Color, destination: AppTab) -> some View {
        Button {
            onNavigate(destination)
        } label: {
            HStack {
                Text(text)
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("OPEN ›")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var endDayButton: some View {
        if isResolving {
            Button { skipResolution() } label: { Text("SKIP") }
                .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
        } else {
            HStack(spacing: 8) {
                Button { showingAds = true } label: {
                    Text(adLabel)
                }
                .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
                .frame(maxWidth: 118)

                Button {
                    runDay()
                } label: {
                    Text("END DAY")
                }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
            }
        }
    }

    // MARK: Day resolution

    /// Advances the simulation, then narrates what it did. The sim is already
    /// final by the time the first popup shows — this is a replay, not the
    /// source of truth, which keeps the animation from ever desyncing.
    private func runDay() {
        game.endDay()
        let events = game.lastEvents

        guard !events.isEmpty else {
            showingReport = true
            return
        }

        isResolving = true
        popups = []

        // Squeeze the gap on a busy day so a big haul doesn't drag.
        let gap = min(DayPacing.betweenEvents,
                      DayPacing.maxDuration / Double(events.count))

        resolutionTask = Task { @MainActor in
            for event in events {
                if Task.isCancelled { break }
                popups.append(event)
                // Retire it once its own animation has finished.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(DayPacing.popupLifetime))
                    popups.removeAll { $0.id == event.id }
                }
                try? await Task.sleep(for: .seconds(gap))
            }
            if !Task.isCancelled {
                try? await Task.sleep(for: .seconds(DayPacing.beforeReport))
                finishResolution()
            }
        }
    }

    private func skipResolution() {
        resolutionTask?.cancel()
        finishResolution()
    }

    private func finishResolution() {
        resolutionTask = nil
        popups = []
        isResolving = false
        showingReport = true
    }

    /// Shows the running campaign's remaining days rather than a dead label.
    private var adLabel: String {
        if let campaign = game.activeCampaign {
            return "ADS \(campaign.daysRemaining)D"
        }
        return "ADS"
    }

    private var floorScene: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 6)
                .fill(skin.floor)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))

            VStack {
                Spacer()
                Rectangle()
                    .fill(skin.counter)
                    .frame(height: 34)
                    .overlay(Rectangle().fill(.black.opacity(0.25)).frame(height: 3), alignment: .top)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // One station per staffer (capped), each a lane popups rise from.
            HStack(spacing: 0) {
                ForEach(0..<laneCount, id: \.self) { lane in
                    ZStack(alignment: .bottom) {
                        shopperSprite(color: laneTint(lane))
                            .opacity(isResolving ? 1 : 0.85)

                        ForEach(popups.filter { $0.lane == lane }) { event in
                            FloatingEventView(event: event)
                                .offset(y: -34)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 30)
            .frame(maxHeight: .infinity, alignment: .bottom)

            if !isResolving {
                speechBubble("got any \(game.trendingFormat.abbreviation)?")
                    .padding(.top, 10)
                    .padding(.leading, 24)
            }
        }
        .frame(minHeight: 132)
    }

    /// A station per staffer, capped so the floor doesn't get crowded.
    private var laneCount: Int { max(1, min(game.staff.count, 4)) }

    private func laneTint(_ lane: Int) -> Color {
        let palette = [Theme.steel, Theme.red, Theme.plum, Theme.teal]
        return palette[lane % palette.count]
    }

    private func shopperSprite(color: Color) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color(hex: 0xE8C9A0))
                .frame(width: 16, height: 16)
            RoundedRectangle(cornerRadius: 5)
                .fill(color)
                .frame(width: 22, height: 30)
        }
    }

    private func speechBubble(_ text: String) -> some View {
        Text(text)
            .font(Theme.mono(9, weight: .bold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.ink, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

/// One slot on the shelf wall — an empty slot renders as a dashed placeholder,
/// a rare item gets the red grail outline.
private struct ShelfBinView: View {
    let item: InventoryItem?

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(item?.format.binColor ?? Color(hex: 0xD7D0BE))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Group {
                    if item == nil {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                            .foregroundStyle(Color(hex: 0xB7AF97))
                    } else if item?.isRare == true {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Theme.red, lineWidth: 2)
                    }
                }
            )
            .overlay(
                Text(item?.format.abbreviation ?? "")
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            )
    }
}

/// The end-of-day summary — the beat where a Kairosoft game tells you how
/// the day actually went.
private struct DayReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let report: GameState.DayReport?

    var body: some View {
        VStack(spacing: 16) {
            Text("DAY \(report?.day ?? 0) REPORT")
                .font(Theme.display(20))
                .foregroundStyle(Theme.ink)

            if let report {
                VStack(spacing: 8) {
                    reportRow("ITEMS SOLD", "\(report.itemsSold)", Theme.ink)
                    reportRow("REVENUE", "+$\(report.revenue)", Theme.green)
                    reportRow("WAGES", "-$\(report.wages)", Theme.red)
                    reportRow("NET", (report.net >= 0 ? "+$\(report.net)" : "-$\(abs(report.net))"),
                              report.net >= 0 ? Theme.green : Theme.red)
                    reportRow("BENCH JOBS WORKED", "\(report.restorationsAdvanced)", Theme.ink)
                    if let haulSize = report.haulSize {
                        reportRow("HAUL BACK", "\(haulSize) items to grade", Theme.amberDeep)
                    }
                }
                .padding(14)
                .background(Theme.cream)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                if let drop = report.dropResult {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("DROP LAUNCHED")
                                .font(Theme.mono(9, weight: .bold))
                                .foregroundStyle(Theme.red)
                            Spacer()
                            Text(String(repeating: "★", count: drop.stars)
                                 + String(repeating: "☆", count: 5 - drop.stars))
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.amberDeep)
                        }
                        Text(drop.review)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !report.trainingFinished.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("BACK FROM A CONVENTION")
                            .font(Theme.mono(9, weight: .bold))
                            .foregroundStyle(Theme.steel)
                        ForEach(report.trainingFinished, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 11.5))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !report.gradeUps.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("GRADE UPS")
                            .font(Theme.mono(9, weight: .bold))
                            .foregroundStyle(Theme.amberDeep)
                        ForEach(report.gradeUps, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 11.5))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Button { dismiss() } label: { Text("OPEN UP") }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 30)
        .background(Theme.paper)
    }

    private func reportRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(Theme.mono(9, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.mono(11, weight: .bold))
                .foregroundStyle(color)
        }
    }
}

#Preview {
    ShopFloorView()
        .environment(GameState())
}
