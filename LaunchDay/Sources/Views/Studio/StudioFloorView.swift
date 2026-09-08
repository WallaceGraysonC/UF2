import SwiftUI

struct StudioFloorView: View {
    @Environment(Studio.self) private var studio
    @State private var selectedTab: AppTab = .floor

    @State private var showingNewProject = false
    @State private var showingShipReport = false
    @State private var showingOffice = false

    @State private var popups: [DayEvent] = []
    @State private var isResolving = false
    @State private var resolutionTask: Task<Void, Never>?
    @State private var clockTask: Task<Void, Never>?

    var onNavigate: (AppTab) -> Void = { _ in }

    var body: some View {
        @Bindable var studio = studio

        VStack(spacing: 0) {
            hud
            floorContent
            StudioStatBar()
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.paper)
        .onChange(of: selectedTab) { _, newValue in
            guard newValue != .floor else { return }
            onNavigate(newValue)
            selectedTab = .floor
        }
        .onDisappear {
            resolutionTask?.cancel(); resolutionTask = nil
            stopClock()
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectSheet().environment(studio)
        }
        .sheet(isPresented: $showingShipReport) {
            ShipReportSheet(result: studio.lastShipResult)
        }
        .sheet(isPresented: $showingOffice) {
            OfficeSheet().environment(studio)
        }
        .onChange(of: studio.isRunning) { _, running in
            running ? startClock() : stopClock()
        }
        .onAppear {
            if studio.isRunning { startClock() }
        }
    }

    // MARK: HUD

    private var hud: some View {
        HStack {
            HUDStatView(value: "DAY \(studio.day)", label: "STUDIO")
            Spacer()
            HUDStatView(value: "$\(studio.cash)", label: "CASH")
            Spacer()
            Button { showingOffice = true } label: {
                HUDStatView(value: "LV. \(studio.studioLevel)", label: "OFFICE")
            }
            .buttonStyle(.plain)
            .overlay(alignment: .topTrailing) {
                if let next = studio.nextUpgrade, studio.canUpgrade(to: next) {
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
            Text("THE STUDIO")
                .font(Theme.display(14))
                .foregroundStyle(Theme.ink)

            ProjectPanel(
                onStartProject: { showingNewProject = true },
                onShip: { shipNow() }
            )

            DesksView(popups: popups, isResolving: isResolving, onSquashBug: { bug in
                studio.squashBug(bug)
            })
            .frame(maxHeight: .infinity)

            clockControls
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: Clock

    private var clockControls: some View {
        @Bindable var studio = studio

        return VStack(spacing: 7) {
            HStack(spacing: 8) {
                Button {
                    studio.isRunning.toggle()
                    studio.save()
                } label: {
                    Text(studio.isRunning ? "PAUSE" : "WORK")
                }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))

                Button { runDay() } label: {
                    Text("STEP")
                        .font(Theme.mono(8, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: 70)
                        .padding(.vertical, 13)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.ink, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(studio.isRunning)
                .opacity(studio.isRunning ? 0.35 : 1)
            }

            HStack(spacing: 6) {
                ForEach(ClockSpeed.allCases) { speed in
                    Button {
                        studio.secondsPerDay = speed.secondsPerDay
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
            }
        }
    }

    private func isSpeed(_ speed: ClockSpeed) -> Bool {
        abs(studio.secondsPerDay - speed.secondsPerDay) < 0.01
    }

    // MARK: Shipping

    private func shipNow() {
        studio.shipProject()
        showingShipReport = true
    }

    // MARK: Day resolution

    private func runDay() {
        studio.endDay()
        let events = studio.lastEvents
        guard !events.isEmpty else { return }
        resolutionTask = Task { @MainActor in
            await playEvents(events, tightBudget: false)
        }
    }

    private func startClock() {
        stopClock()
        clockTask = Task { @MainActor in
            while !Task.isCancelled && studio.isRunning {
                try? await Task.sleep(for: .seconds(studio.secondsPerDay))
                if Task.isCancelled || !studio.isRunning { break }
                studio.endDay()
                await playEvents(studio.lastEvents, tightBudget: true)
            }
        }
    }

    private func stopClock() {
        clockTask?.cancel()
        clockTask = nil
    }

    @MainActor
    private func playEvents(_ events: [DayEvent], tightBudget: Bool) async {
        guard !events.isEmpty else { return }
        isResolving = true
        popups = []

        var budget = DayPacing.maxDuration
        if tightBudget { budget = min(budget, studio.secondsPerDay * 0.8) }
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
        isResolving = false
    }
}

#Preview {
    StudioFloorView()
        .environment(Studio())
}
