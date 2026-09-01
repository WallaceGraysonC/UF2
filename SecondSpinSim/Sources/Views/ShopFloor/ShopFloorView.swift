import SwiftUI

struct ShopFloorView: View {
    @Environment(GameState.self) private var game
    @State private var selectedTab: AppTab = .floor
    @State private var showingReport = false

    /// Called when the player taps a tab other than Floor. Floor is the hub
    /// this view already renders, so navigating away is the parent's job.
    var onNavigate: (AppTab) -> Void = { _ in }

    /// Six across, two rows — the shelf wall the player actually sees.
    private let binCapacity = 12

    var body: some View {
        VStack(spacing: 0) {
            hud
            floorContent
            AppTabBar(selection: $selectedTab)
        }
        .background(Theme.paper)
        .onChange(of: selectedTab) { _, newValue in
            guard newValue != .floor else { return }
            onNavigate(newValue)
            selectedTab = .floor
        }
        .sheet(isPresented: $showingReport) {
            DayReportSheet(report: game.lastReport)
        }
    }

    // MARK: HUD

    private var hud: some View {
        HStack {
            HUDStatView(value: "DAY \(game.day)", label: "SEASON 1")
            Spacer()
            HUDStatView(value: "$\(game.cash)", label: "CASH")
            Spacer()
            HUDStatView(value: "LV. \(game.shopLevel)", label: "SHOP")
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
                    .foregroundStyle(Theme.ink)
                Spacer()
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
            ForEach(0..<binCapacity, id: \.self) { index in
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

    private var endDayButton: some View {
        Button {
            game.endDay()
            showingReport = true
        } label: {
            Text("END DAY")
        }
        .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
    }

    private var floorScene: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: 0xDCD5C1))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))

            VStack {
                Spacer()
                Rectangle()
                    .fill(Color(hex: 0xB98A4C))
                    .frame(height: 34)
                    .overlay(Rectangle().fill(Color(hex: 0x8A6136)).frame(height: 3), alignment: .top)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack {
                shopperSprite(color: Theme.steel)
                    .padding(.leading, 40)
                Spacer()
                shopperSprite(color: Theme.red)
                    .padding(.trailing, 60)
            }
            .padding(.bottom, 34)
            .frame(maxHeight: .infinity, alignment: .bottom)

            speechBubble("got any \(game.trendingFormat.abbreviation)?")
                .padding(.top, 12)
                .padding(.leading, 30)
        }
        .frame(minHeight: 120)
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
