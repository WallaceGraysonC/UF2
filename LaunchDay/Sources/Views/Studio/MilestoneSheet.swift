import SwiftUI

/// A one-time celebration when the fan count crosses a round number —
/// texture between ships rather than a silently climbing counter.
struct MilestoneSheet: View {
    @Environment(\.dismiss) private var dismiss
    let milestone: Studio.FanMilestone?

    var body: some View {
        VStack(spacing: 16) {
            Text("🎉")
                .font(.system(size: 40))

            if let milestone {
                Text("\(milestone.fans) FANS")
                    .font(Theme.display(24))
                    .foregroundStyle(Theme.ink)

                Text("Word's gotten around. The studio has a following now.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)

                Text("+$\(milestone.cashBonus)")
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.green)
                    .padding(.top, 4)
            }

            Button { dismiss() } label: { Text("NICE") }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
                .padding(.top, 6)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 60)
        .background(Theme.paper)
    }
}
