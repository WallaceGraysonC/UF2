import SwiftUI

/// Standing orders. This is now the main way you play: you set how the shop
/// is run rather than making the same six decisions every morning.
struct PolicySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game

    var body: some View {
        @Bindable var game = game

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("STANDING ORDERS")
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.ink)

                section("SOURCING") {
                    Toggle("Always have a run out", isOn: $game.policy.autoSource)
                        .tint(Theme.amberDeep)
                    if game.policy.autoSource {
                        picker("Go to", selection: $game.policy.sourceLocation,
                               options: SourcingLocation.allCases) { $0.rawValue }
                        stepperRow("Never spend below", value: $game.policy.cashFloor,
                                   step: 100, range: 0...5_000, prefix: "$")
                    }
                }

                section("THE BENCH") {
                    Toggle("Put idle Techs on jobs", isOn: $game.policy.autoStaffBench)
                        .tint(Theme.teal)
                }

                section("GRADING THE HAUL") {
                    picker("Shelve at or above", selection: $game.policy.shelveAtOrAbove,
                           options: ConditionGrade.allCases) { $0.label }
                    Toggle("Send the rest to the bench", isOn: $game.policy.benchBelowThreshold)
                        .tint(Theme.teal)
                    stepperRow("Bin anything under", value: $game.policy.binUnderValue,
                               step: 1, range: 0...50, prefix: "$")
                    Toggle("Always ask me about grails", isOn: $game.policy.alwaysAskOnGrails)
                        .tint(Theme.red)
                    Text("Finding something rare is the best moment in the game. Leave this on and it always comes to you.")
                        .font(Theme.mono(8))
                        .foregroundStyle(Theme.inkSoft)
                }

                section("DROPS") {
                    Toggle("Keep a Drop in prep", isOn: $game.policy.autoDrops)
                        .tint(Theme.plum)
                    if game.policy.autoDrops {
                        picker("Theme", selection: $game.policy.dropTheme,
                               options: game.availableThemes) { $0.rawValue }
                        picker("Angle", selection: $game.policy.dropAngle,
                               options: DropAngle.allCases) { $0.rawValue }
                    }
                }

                Button { dismiss() } label: { Text("DONE") }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
            }
            .padding(20)
            .padding(.top, 24)
        }
        .background(Theme.paper)
    }

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(Theme.display(13))
                .foregroundStyle(Theme.ink)
            content()
                .font(.system(size: 12))
                .foregroundStyle(Theme.ink)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func picker<T: Hashable>(_ label: String, selection: Binding<T>,
                                     options: [T],
                                     title: @escaping (T) -> String) -> some View {
        HStack {
            Text(label)
                .font(Theme.mono(9, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(title(option)) { selection.wrappedValue = option }
                }
            } label: {
                Text(title(selection.wrappedValue))
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(Theme.amberDeep)
            }
        }
    }

    private func stepperRow(_ label: String, value: Binding<Int>,
                            step: Int, range: ClosedRange<Int>,
                            prefix: String = "") -> some View {
        HStack {
            Text(label)
                .font(Theme.mono(9, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Stepper(value: value, in: range, step: step) {
                Text("\(prefix)\(value.wrappedValue)")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(Theme.amberDeep)
            }
            .labelsHidden()
            .fixedSize()
            Text("\(prefix)\(value.wrappedValue)")
                .font(Theme.mono(9, weight: .bold))
                .foregroundStyle(Theme.amberDeep)
        }
    }
}

#Preview {
    PolicySheet()
        .environment(GameState())
}
