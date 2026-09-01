import SwiftUI

/// One slot on the shelf grid — empty slots render as a dashed placeholder,
/// `isRare` draws the red grail outline used for a standout find.
struct ShelfBin: Identifiable {
    let id = UUID()
    var format: MediaFormat?
    var isRare: Bool = false
}

struct ShopFloorView: View {
    @State private var selectedTab: AppTab = .floor

    /// Called when the player taps a tab other than Floor. Floor is the hub
    /// this view already renders, so navigating away is the parent's job.
    var onNavigate: (AppTab) -> Void = { _ in }

    // Sample data until this is backed by a real inventory model.
    var day: Int = 14
    var cash: Int = 1240
    var shopLevel: Int = 3
    var hasNewHaul: Bool = true
    var bins: [ShelfBin] = [
        .init(format: .vinyl), .init(format: .vinyl), .init(format: .cd), .init(format: .cd),
        .init(format: .vhs), .init(format: .vhs, isRare: true), .init(format: .game), .init(format: .game),
        .init(format: .vinyl), .init(format: .cd), .init(format: nil), .init(format: nil)
    ]

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
    }

    // MARK: HUD

    private var hud: some View {
        HStack {
            HUDStatView(value: "DAY \(day)", label: "SEASON 1")
            Spacer()
            HUDStatView(value: "$\(cash)", label: "CASH")
            Spacer()
            HUDStatView(value: "LV. \(shopLevel)", label: "SHOP")
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
                if hasNewHaul {
                    Text("NEW HAUL")
                        .font(Theme.mono(9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Theme.red)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
            }

            shelfGrid

            floorScene
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var shelfGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 6)
        return LazyVGrid(columns: columns, spacing: 5) {
            ForEach(bins) { bin in
                ShelfBinView(bin: bin)
            }
        }
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
                    .frame(height: 40)
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
            .padding(.bottom, 40)
            .frame(maxHeight: .infinity, alignment: .bottom)

            speechBubble("got any Blondie?")
                .padding(.top, 14)
                .padding(.leading, 30)
        }
        .frame(minHeight: 150)
    }

    private func shopperSprite(color: Color) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color(hex: 0xE8C9A0))
                .frame(width: 16, height: 16)
            RoundedRectangle(cornerRadius: 5)
                .fill(color)
                .frame(width: 22, height: 34)
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

private struct ShelfBinView: View {
    let bin: ShelfBin

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(bin.format?.binColor ?? Color(hex: 0xD7D0BE))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Group {
                    if bin.format == nil {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                            .foregroundStyle(Color(hex: 0xB7AF97))
                    } else if bin.isRare {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Theme.red, lineWidth: 2)
                    }
                }
            )
            .overlay(
                Text(bin.format?.abbreviation ?? "")
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            )
    }
}

#Preview {
    ShopFloorView()
}
