import SwiftUI

/// The idle-game homecoming: what the shop did while you weren't watching.
struct WhileYouWereOutSheet: View {
    @Environment(\.dismiss) private var dismiss

    let days: Int
    let cash: Int

    var body: some View {
        VStack(spacing: 16) {
            Text("WHILE YOU WERE OUT")
                .font(Theme.display(20))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text("The shop kept trading to your standing orders.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                HStack {
                    Text("DAYS TRADED")
                        .font(Theme.mono(9, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text("\(days)")
                        .font(Theme.display(18))
                        .foregroundStyle(Theme.amberDeep)
                }
                HStack {
                    Text("IN THE TILL")
                        .font(Theme.mono(9, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text("$\(cash)")
                        .font(Theme.display(18))
                        .foregroundStyle(cash >= 0 ? Theme.green : Theme.red)
                }
            }
            .padding(14)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Button { dismiss() } label: { Text("BACK TO IT") }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 40)
        .background(Theme.paper)
    }
}
