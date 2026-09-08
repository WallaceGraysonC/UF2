import SwiftUI

/// The hub destinations reachable from the studio's bottom tab bar. The
/// office ladder lives behind the HUD's level badge instead of a third tab —
/// two tabs is enough surface for this game.
enum AppTab: String, CaseIterable, Identifiable {
    case floor = "Studio"
    case employees = "Team"

    var id: String { rawValue }
}

/// Shared bottom navigation: dark ink bar, amber highlight on the active tab.
struct AppTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                let isActive = tab == selection
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isActive ? Theme.amber : Theme.inkSoft.opacity(0.5))
                            .frame(width: 16, height: 16)
                        Text(tab.rawValue.uppercased())
                            .font(Theme.mono(9, weight: .semibold))
                            .foregroundStyle(isActive ? Theme.amber : Theme.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 9)
                    .padding(.bottom, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Theme.ink)
        .overlay(Rectangle().fill(Theme.line.opacity(0.2)).frame(height: 1), alignment: .top)
    }
}
