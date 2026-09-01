import SwiftUI

struct MainMenuView: View {
    @State private var showNewGameConfirm = false

    /// Set once a save exists — swap this for a real SwiftData query when the
    /// save model lands. Kept here as the single flag that governs Continue's
    /// enabled state and the New Game confirmation.
    var hasSave: Bool = false

    var onNewGame: () -> Void = {}
    var onContinue: () -> Void = {}

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer(minLength: 40)
                title
                Spacer(minLength: 28)
                menu
                Spacer(minLength: 20)
                footer
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .confirmationDialog(
            "Starting a new shop overwrites your current save.",
            isPresented: $showNewGameConfirm,
            titleVisibility: .visible
        ) {
            Button("Start New Shop", role: .destructive) {
                // TODO: reset save before real persistence exists
                onNewGame()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Background

    private var background: some View {
        ZStack {
            Theme.stageBackground.ignoresSafeArea()

            // Shop-floor strip along the bottom, same shelf-bin language as the
            // Shop Floor mockup, kept low-contrast so it reads as backdrop, not UI.
            VStack {
                Spacer()
                shelfStrip
                    .frame(height: 64)
                    .opacity(0.55)
            }
            .ignoresSafeArea()
        }
    }

    private var shelfStrip: some View {
        GeometryReader { geo in
            HStack(spacing: 6) {
                ForEach(0..<10, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(binColor(for: i))
                        .frame(width: (geo.size.width - 9 * 6) / 10)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func binColor(for index: Int) -> Color {
        let palette: [Color] = [Theme.plum, Theme.steel, Theme.amberDeep, Theme.green]
        return palette[index % palette.count]
    }

    // MARK: Title

    private var title: some View {
        VStack(spacing: 10) {
            LogoBadgeView()
                .frame(width: 92, height: 92)
                .padding(.bottom, 4)

            Text("SECOND SPIN")
                .font(Theme.display(34))
                .foregroundStyle(Theme.cream)
                .kerning(1)

            Text("SIM")
                .font(Theme.display(16))
                .foregroundStyle(Theme.amber)
                .kerning(6)

            Text("buy it. grade it. flip it.")
                .font(Theme.mono(11))
                .foregroundStyle(Theme.inkSoft.opacity(0.9))
                .padding(.top, 2)
        }
    }

    // MARK: Menu

    private var menu: some View {
        VStack(spacing: 12) {
            Button {
                if hasSave {
                    showNewGameConfirm = true
                } else {
                    onNewGame()
                }
            } label: {
                Text("NEW GAME")
            }
            .buttonStyle(KairosoftButtonStyle(emphasis: .primary))

            Button {
                onContinue()
            } label: {
                Text("CONTINUE")
            }
            .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
            .disabled(!hasSave)
            .opacity(hasSave ? 1 : 0.4)

            HStack(spacing: 12) {
                Button {
                    // TODO: navigate to Options
                } label: {
                    Text("OPTIONS")
                }
                .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))

                Button {
                    // TODO: navigate to Credits
                } label: {
                    Text("CREDITS")
                }
                .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
            }
        }
        .frame(maxWidth: 380)
    }

    // MARK: Footer

    private var footer: some View {
        Text("v0.1 — Second Spin Sim")
            .font(Theme.mono(10))
            .foregroundStyle(Theme.inkSoft.opacity(0.6))
    }
}

#Preview {
    MainMenuView()
}
