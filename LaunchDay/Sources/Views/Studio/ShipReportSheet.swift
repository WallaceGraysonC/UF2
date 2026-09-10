import SwiftUI

/// The review reveal — the moment the whole cycle was building to.
struct ShipReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let result: Studio.ShipResult?

    var body: some View {
        VStack(spacing: 16) {
            if let result {
                Text(result.game.name.uppercased())
                    .font(Theme.display(22))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text(String(repeating: "★", count: result.game.stars)
                     + String(repeating: "☆", count: 5 - result.game.stars))
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.amberDeep)

                Text(result.game.reviewLine)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)

                VStack(spacing: 8) {
                    reportRow("HIT OF TARGET", "\(Int(result.pointsRatio * 100))%",
                             result.pointsRatio >= 1 ? Theme.green : Theme.amberDeep)
                    reportRow("LAUNCH SALES", "+$\(result.game.lifetimeSales)", Theme.green)
                    reportRow("FANS GAINED", "+\(result.game.stars * 40)", Theme.plum)
                    if result.bugPenaltyApplied {
                        reportRow("SHIPPED WITH BUGS", "score docked", Theme.red)
                    }
                }
                .padding(14)
                .background(Theme.cream)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Text("It'll keep selling for a while yet — check back on the shelf.")
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                Text("SHIPPED")
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.ink)
            }

            Button { dismiss() } label: { Text("BACK TO THE STUDIO") }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 40)
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
