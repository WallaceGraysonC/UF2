import SwiftUI

/// The five hub destinations reachable from the shop's bottom tab bar.
enum AppTab: String, CaseIterable, Identifiable {
    case floor = "Floor"
    case source = "Source"
    case bench = "Bench"
    case staff = "Staff"
    case ledger = "Ledger"

    var id: String { rawValue }
}

/// Shared bottom navigation, styled to match the phone mockups: dark ink bar,
/// amber highlight on the active tab, muted everywhere else.
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
