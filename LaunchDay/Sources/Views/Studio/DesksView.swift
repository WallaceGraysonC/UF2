import SwiftUI

/// The room: a desk per employee. Points earned during a day pop from the
/// desk that earned them; bugs show up on a desk and can be tapped to squash.
struct DesksView: View {
    @Environment(Studio.self) private var studio

    var popups: [DayEvent]
    var isResolving: Bool
    var onSquashBug: (Bug) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.paper)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(studio.employees.enumerated()), id: \.element.id) { index, employee in
                    DeskView(
                        employee: employee,
                        isWorking: studio.currentProject != nil && !studio.needsShipDecision,
                        bug: bugAt(lane: index),
                        popups: popups.filter { $0.lane == index },
                        isResolving: isResolving,
                        onSquashBug: onSquashBug
                    )
                }
            }
            .padding(9)
        }
    }

    private func bugAt(lane: Int) -> Bug? {
        studio.currentProject?.bugs.first { $0.deskLane == lane }
    }
}

private struct DeskView: View {
    let employee: Employee
    let isWorking: Bool
    let bug: Bug?
    let popups: [DayEvent]
    let isResolving: Bool
    let onSquashBug: (Bug) -> Void

    @State private var bob: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                characterSprite.offset(y: bob ? -1.5 : 0)

                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.cream)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.line, lineWidth: 1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill((isWorking ? Theme.plum : Theme.inkSoft).opacity(0.8))
                        .frame(width: 16, height: 11)
                        .offset(y: -1)
                }
                .frame(height: 20)

                VStack(spacing: 1) {
                    Text(employee.name.uppercased())
                        .font(Theme.mono(7.5, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("D\(employee.design) · T\(employee.tech)")
                        .font(Theme.mono(6.5, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.top, 3)
            }
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(Theme.cream.opacity(isWorking ? 0.55 : 0.3))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isWorking ? Theme.plum.opacity(0.7) : Theme.line.opacity(0.5),
                            lineWidth: isWorking ? 1.5 : 1)
            )

            if let bug {
                Button { onSquashBug(bug) } label: {
                    Text("🐛")
                        .font(.system(size: 15))
                        .padding(4)
                        .background(Circle().fill(Theme.red))
                }
                .buttonStyle(.plain)
                .offset(x: 26, y: -6)
                .transition(.scale.combined(with: .opacity))
            }

            ForEach(popups) { event in
                FloatingEventView(event: event)
                    .offset(y: -18)
            }
        }
        .onAppear {
            guard isWorking else { return }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
    }

    private var characterSprite: some View {
        ZStack {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color(hex: 0xE8C9A0))
                    .frame(width: 13, height: 13)
                    .overlay(
                        Circle()
                            .fill(Theme.ink.opacity(0.75))
                            .frame(width: 13, height: 5)
                            .offset(y: -4)
                    )
                RoundedRectangle(cornerRadius: 4)
                    .fill(isWorking ? Theme.plum : Theme.inkSoft)
                    .frame(width: 19, height: 17)
            }

            if isWorking && isResolving {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.amber.opacity(0.35))
                    .frame(width: 26, height: 26)
                    .blur(radius: 5)
            }
        }
        .frame(height: 32)
    }
}
