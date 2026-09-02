import SwiftUI

struct ShopFloorView: View {
    @Environment(GameState.self) private var game
    @State private var selectedTab: AppTab = .floor
    @State private var showingReport = false
    @State private var showingUpgrade = false
    @State private var showingAds = false
    @State private var showingPolicy = false
    /// Drives the clock while the shop is open.
    @State private var clockTask: Task<Void, Never>?

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
            // Don't leave playback or the clock running behind another screen.
            resolutionTask?.cancel()
            resolutionTask = nil
            stopClock()
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
        .sheet(isPresented: $showingPolicy) {
            PolicySheet()
                .environment(game)
        }
        .onChange(of: game.policy.isRunning) { _, running in
            running ? startClock() : stopClock()
        }
        .onAppear {
            if game.policy.isRunning { startClock() }
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

            // What the room is working toward, up top where it belongs.
            ActiveProjectsPanel()

            statusStrip

            // The room itself takes whatever space is left.
            WorkroomView(skin: skin, popups: popups, isResolving: isResolving)
                .frame(maxHeight: .infinity)

            shelfStrip

            endDayButton
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    /// The shelves get one slim row now that the room is the main event —
    /// the full grid lives in the shelf detail, not the hub.
    private var shelfStrip: some View {
        let stock = game.shelvedInventory
        let slots = min(game.binCapacity, 10)
        return HStack(spacing: 4) {
            ForEach(0..<slots, id: \.self) { index in
                ShelfBinView(item: index < stock.count ? stock[index] : nil)
            }
            if stock.count > slots {
                Text("+\(stock.count - slots)")
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(height: 22)
    }

    /// Anything needing a decision — a haul to grade. Tapping jumps to it.
    @ViewBuilder
    private var statusStrip: some View {
        if !game.pendingHaul.isEmpty {
            statusPill(text: "\(game.pendingHaul.count) ITEMS TO GRADE",
                       color: Theme.red, destination: .source)
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

    /// The clock is the main control now: the shop trades on its own and you
    /// step in when it asks. The manual day is still there for one-at-a-time.
    private var endDayButton: some View {
        @Bindable var game = game

        return VStack(spacing: 7) {
            if !game.needsAttention.isEmpty {
                Button { onNavigate(.source) } label: {
                    HStack(spacing: 6) {
                        Circle().fill(Theme.red).frame(width: 6, height: 6)
                        Text(game.needsAttention[0].uppercased())
                            .font(Theme.mono(8.5, weight: .bold))
                            .foregroundStyle(Theme.red)
                            .lineLimit(1)
                        Spacer()
                        if game.needsAttention.count > 1 {
                            Text("+\(game.needsAttention.count - 1)")
                                .font(Theme.mono(8, weight: .bold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.red, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Button { showingPolicy = true } label: { Text("ORDERS") }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
                    .frame(maxWidth: 96)

                Button { showingAds = true } label: { Text(adLabel) }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
                    .frame(maxWidth: 96)

                Button {
                    game.policy.isRunning.toggle()
                    game.save()
                } label: {
                    Text(game.policy.isRunning ? "PAUSE" : "OPEN UP")
                }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
            }

            HStack(spacing: 6) {
                ForEach(ClockSpeed.allCases) { speed in
                    Button {
                        game.policy.secondsPerDay = speed.secondsPerDay
                        game.save()
                    } label: {
                        Text(speed.label)
                            .font(Theme.mono(8, weight: .bold))
                            .foregroundStyle(isSpeed(speed) ? Theme.ink : Theme.inkSoft)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(isSpeed(speed) ? Theme.amber : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(isSpeed(speed) ? Theme.amber : Theme.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    .buttonStyle(.plain)
                }

                Button { runDay() } label: {
                    Text("STEP")
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.ink, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(game.policy.isRunning)
                .opacity(game.policy.isRunning ? 0.35 : 1)
            }
        }
    }

    private func isSpeed(_ speed: ClockSpeed) -> Bool {
        abs(game.policy.secondsPerDay - speed.secondsPerDay) < 0.01
    }

    // MARK: Day resolution

    /// Advances the simulation, then narrates what it did. The sim is already
    /// final by the time the first popup shows — this is a replay, not the
    /// source of truth, which keeps the animation from ever desyncing.
    /// One manual day, with the report at the end.
    private func runDay() {
        game.endDay()
        let events = game.lastEvents

        guard !events.isEmpty else {
            showingReport = true
            return
        }

        resolutionTask = Task { @MainActor in
            await playEvents(events, showReportWhenDone: true)
        }
    }

    /// Narrates a day's events. Shared by the manual step and the clock —
    /// the difference is only whether the report interrupts at the end.
    @MainActor
    private func playEvents(_ events: [DayEvent], showReportWhenDone: Bool) async {
        guard !events.isEmpty else { return }

        isResolving = true
        popups = []

        // Squeeze the gap on a busy day so a big haul doesn't drag, and never
        // let a day outlast the clock tick that started it.
        var budget = DayPacing.maxDuration
        if !showReportWhenDone {
            budget = min(budget, game.policy.secondsPerDay * 0.8)
        }
        let gap = min(DayPacing.betweenEvents, budget / Double(events.count))

        for event in events {
            if Task.isCancelled { break }
            popups.append(event)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(DayPacing.popupLifetime))
                popups.removeAll { $0.id == event.id }
            }
            try? await Task.sleep(for: .seconds(gap))
        }

        guard !Task.isCancelled else { return }

        if showReportWhenDone {
            try? await Task.sleep(for: .seconds(DayPacing.beforeReport))
            finishResolution()
        } else {
            isResolving = false
        }
    }

    /// Ticks days while the shop is open. Popups still play, but the report
    /// sheet doesn't interrupt — a running shop shouldn't demand a tap.
    private func startClock() {
        stopClock()
        clockTask = Task { @MainActor in
            while !Task.isCancelled && game.policy.isRunning {
                try? await Task.sleep(for: .seconds(game.policy.secondsPerDay))
                if Task.isCancelled || !game.policy.isRunning { break }
                game.endDay()
                await playEvents(game.lastEvents, showReportWhenDone: false)
            }
        }
    }

    private func stopClock() {
        clockTask?.cancel()
        clockTask = nil
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
