import SwiftUI

/// The room: a desk per staffer, each occupied, each showing what that person
/// is working on. Points earned during a day pop from the desk that earned
/// them, so you can see who is actually producing.
struct WorkroomView: View {
    @Environment(GameState.self) private var game

    var skin: ShopSkin
    /// Popups currently in flight, already filtered to this room.
    var popups: [DayEvent]
    var isResolving: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Wall behind, floor under — a room rather than a strip.
            VStack(spacing: 0) {
                skin.walls
                Rectangle().fill(.black.opacity(0.18)).frame(height: 2)
                skin.floor
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(game.staff.enumerated()), id: \.element.id) { index, member in
                    DeskView(
                        member: member,
                        task: game.currentTask(for: member),
                        // Staff-driven events carry their own desk index; the
                        // shop-wide ones (sales, wages) cycle across desks.
                        popups: popups.filter { $0.lane == index },
                        isResolving: isResolving
                    )
                }
            }
            .padding(9)
        }
    }
}

/// One desk with its occupant.
private struct DeskView: View {
    let member: StaffMember
    let task: StaffTask
    let popups: [DayEvent]
    let isResolving: Bool

    @State private var bob: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Occupant, sitting behind the desk.
                characterSprite
                    .offset(y: bob ? -1.5 : 0)

                // The desk itself.
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.cream)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.line, lineWidth: 1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(task.tint.opacity(0.85))
                        .frame(width: 16, height: 11)
                        .offset(y: -1)
                }
                .frame(height: 20)

                VStack(spacing: 1) {
                    Text(member.name.uppercased())
                        .font(Theme.mono(7.5, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(task.label)
                        .font(Theme.mono(6.5, weight: .semibold))
                        .foregroundStyle(task.tint)
                        .lineLimit(1)
                }
                .padding(.top, 3)
            }
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(Theme.paper.opacity(task.isBusy ? 0.55 : 0.3))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(task.isBusy ? task.tint.opacity(0.7) : Theme.line.opacity(0.5),
                            lineWidth: task.isBusy ? 1.5 : 1)
            )

            // Points fly off the desk that earned them.
            ForEach(popups) { event in
                FloatingEventView(event: event)
                    .offset(y: -18)
            }
        }
        .onAppear {
            guard task.isBusy else { return }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
    }

    /// A seated figure — head, body, and a screen glow when they're working.
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
                    .fill(task.tint)
                    .frame(width: 19, height: 17)
            }

            if task.isBusy && isResolving {
                // A flicker of effort while the day resolves.
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.amber.opacity(0.35))
                    .frame(width: 26, height: 26)
                    .blur(radius: 5)
            }
        }
        .frame(height: 32)
    }
}
