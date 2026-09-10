import SwiftUI

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Studio.self) private var studio

    @State private var name: String = ""
    @State private var genre: Genre = .action
    @State private var topic: Topic = .fantasy
    @State private var size: ProjectSize = .small
    @State private var platform: Platform = .computer

    private var affinity: ComboAffinity { GenreTopicCombo.affinity(genre: genre, topic: topic) }
    private var known: Bool { studio.hasDiscovered(genre: genre, topic: topic) }
    private var totalCost: Int { studio.totalCost(size: size, platform: platform) }
    private var affordable: Bool { studio.canAfford(size: size, platform: platform) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("NEW PROJECT")
                    .font(Theme.display(20))
                    .foregroundStyle(Theme.ink)

                VStack(alignment: .leading, spacing: 4) {
                    Text("NAME IT")
                        .font(Theme.mono(9, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                    TextField("Untitled", text: $name)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(10)
                        .background(Theme.cream)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                genreGrid
                grid(title: "TOPIC", items: Topic.allCases, selection: $topic) { $0.rawValue }

                comboReadout

                VStack(alignment: .leading, spacing: 6) {
                    Text("PLATFORM")
                        .font(Theme.mono(9, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                    ForEach(Platform.allCases) { option in
                        platformRow(option)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("SIZE")
                        .font(Theme.mono(9, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                    ForEach(ProjectSize.allCases) { option in
                        sizeRow(option)
                    }
                }

                Button {
                    studio.startProject(name: name, genre: genre, topic: topic, size: size, platform: platform)
                    dismiss()
                } label: {
                    Text(affordable ? "START — $\(totalCost)" : "NOT ENOUGH CASH")
                }
                .buttonStyle(KairosoftButtonStyle(emphasis: .primary))
                .disabled(!affordable)
                .opacity(affordable ? 1 : 0.4)

                Button { dismiss() } label: { Text("CANCEL") }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
            }
            .padding(20)
            .padding(.top, 24)
        }
        .background(Theme.paper)
    }

    private func grid<T: Hashable>(title: String, items: [T], selection: Binding<T>,
                                   label: @escaping (T) -> String) -> some View {
        let columns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6),
                      GridItem(.flexible(), spacing: 6)]
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.mono(9, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    let isSelected = selection.wrappedValue == item
                    Button { selection.wrappedValue = item } label: {
                        Text(label(item).uppercased())
                            .font(Theme.mono(8.5, weight: .bold))
                            .foregroundStyle(isSelected ? .white : Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isSelected ? Theme.amberDeep : Theme.cream)
                            .overlay(RoundedRectangle(cornerRadius: 5)
                                .stroke(isSelected ? Theme.amberDeep : Theme.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Bespoke rather than the shared grid — locked genres stay visible with
    /// their level requirement instead of disappearing outright.
    private var genreGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6),
                      GridItem(.flexible(), spacing: 6)]
        return VStack(alignment: .leading, spacing: 6) {
            Text("GENRE")
                .font(Theme.mono(9, weight: .bold))
                .foregroundStyle(Theme.inkSoft)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Genre.allCases) { item in
                    let isSelected = genre == item
                    let unlocked = studio.isUnlocked(item)
                    Button { if unlocked { genre = item } } label: {
                        VStack(spacing: 2) {
                            Text(item.rawValue.uppercased())
                                .font(Theme.mono(8.5, weight: .bold))
                                .foregroundStyle(unlocked ? (isSelected ? .white : Theme.ink) : Theme.inkSoft)
                            if !unlocked {
                                Text("LV.\(item.unlockLevel)")
                                    .font(Theme.mono(6.5, weight: .semibold))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected && unlocked ? Theme.amberDeep : Theme.cream)
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .stroke(isSelected && unlocked ? Theme.amberDeep : Theme.line, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .opacity(unlocked ? 1 : 0.55)
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                }
            }
        }
    }

    private var comboReadout: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(genre.rawValue.uppercased()) × \(topic.rawValue.uppercased())")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(known ? "You've made this pairing before." : "Untried pairing — no telling until you try it.")
                    .font(Theme.mono(8))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Text(known ? affinity.label : "???")
                .font(Theme.display(13))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(known ? affinity.color : Theme.inkSoft)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(11)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6)
            .stroke(known ? affinity.color : Theme.line, lineWidth: known ? 2 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func platformRow(_ option: Platform) -> some View {
        let isSelected = platform == option
        let unlocked = studio.isUnlocked(option)
        return Button { if unlocked { platform = option } } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(option.rawValue.uppercased())
                        .font(Theme.display(12))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if unlocked {
                        Text(option.fitLabel(for: genre))
                            .font(Theme.mono(7.5, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(fitColor(option.fit(for: genre)))
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        Text("+$\(option.entryFee)")
                            .font(Theme.mono(8, weight: .bold))
                            .foregroundStyle(Theme.inkSoft)
                    } else {
                        Text("OFFICE LV.\(option.unlockLevel)")
                            .font(Theme.mono(7.5, weight: .bold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Text(option.blurb)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.leading)
            }
            .padding(10)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected && unlocked ? Theme.amberDeep : Theme.line,
                        lineWidth: isSelected && unlocked ? 2 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .opacity(unlocked ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    private func fitColor(_ fit: Double) -> Color {
        switch fit {
        case 1.4...: return Theme.teal
        case 1.15..<1.4: return Theme.green
        case ..<0.85: return Theme.red
        default: return Theme.inkSoft
        }
    }

    private func sizeRow(_ option: ProjectSize) -> some View {
        let isSelected = size == option
        return Button { size = option } label: {
            HStack {
                Text(option.rawValue.uppercased())
                    .font(Theme.display(12))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(option.devDays)D · $\(option.cost)")
                    .font(Theme.mono(8, weight: .bold))
                    .foregroundStyle(studio.cash >= option.cost ? Theme.green : Theme.red)
            }
            .padding(10)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? Theme.amberDeep : Theme.line, lineWidth: isSelected ? 2 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NewProjectSheet()
        .environment(Studio())
}
