import SwiftUI

/// A chunky, beveled button in the spirit of Kairosoft's menu chrome:
/// a flat color face, a darker "baseboard" edge that reads as depth, and a
/// press animation that sinks the face into that edge instead of just dimming.
struct KairosoftButtonStyle: ButtonStyle {
    enum Emphasis {
        case primary, secondary

        var face: Color {
            switch self {
            case .primary: return Theme.amberDeep
            case .secondary: return Theme.ink
            }
        }

        var edge: Color {
            switch self {
            case .primary: return Color(hex: 0x7A5013)
            case .secondary: return Color(hex: 0x0F0D0A)
            }
        }

        var text: Color {
            .white.opacity(0.95)
        }
    }

    var emphasis: Emphasis = .primary

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(Theme.display(17))
            .kerning(0.5)
            .foregroundStyle(emphasis.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(emphasis.edge)
                        .offset(y: pressed ? 1 : 4)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(emphasis.face)
                        .offset(y: pressed ? 1 : 0)
                }
            )
            .offset(y: pressed ? 3 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}
