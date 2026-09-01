import SwiftUI

/// The advertising menu, in the spirit of Kairosoft's: a plain tiered list of
/// paid options with the cost on the right and one line saying what it does.
struct AdvertisingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var game

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                if let campaign = game.activeCampaign {
                    running(campaign)
                } else {
                    VStack(spacing: 7) {
                        ForEach(AdMethod.allCases) { method in
                            methodRow(method)
                        }
                    }
                }

                Text("Reaches more people for a few days. Reputation is what makes them come back.")
                    .font(Theme.mono(8.5))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)

                Button { dismiss() } label: { Text("BACK") }
                    .buttonStyle(KairosoftButtonStyle(emphasis: .secondary))
            }
            .padding(20)
            .padding(.top, 24)
        }
        .background(Theme.paper)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("ADVERTISING")
                .font(Theme.display(20))
                .foregroundStyle(Theme.ink)
            Text("$\(game.cash) in the till")
                .font(Theme.mono(9, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private func running(_ campaign: AdCampaign) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(campaign.method.rawValue.uppercased())
                    .font(Theme.display(14))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(campaign.daysRemaining)D LEFT")
                    .font(Theme.mono(9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Theme.amberDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            Text("+\(Int(campaign.method.trafficBoost * 100))% chance on every sale while it runs.")
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.inkSoft)

            Text("One campaign at a time — wait it out before booking another.")
                .font(Theme.mono(8))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cream)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.amberDeep, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func methodRow(_ method: AdMethod) -> some View {
        let affordable = game.canAfford(method)
        return Button {
            game.runCampaign(method)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(method.rawValue.uppercased())
                        .font(Theme.display(13))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("$\(method.cost)")
                        .font(Theme.mono(11, weight: .bold))
                        .foregroundStyle(affordable ? Theme.green : Theme.red)
                }

                Text(method.blurb)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    tag("+\(Int(method.trafficBoost * 100))% TRAFFIC")
                    tag("\(method.days)D")
                    tag("\(method.reaches.count) CROWDS")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .background(Theme.cream)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .opacity(affordable ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(Theme.mono(7.5, weight: .semibold))
            .foregroundStyle(Theme.inkSoft)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Theme.line, lineWidth: 1))
    }
}

#Preview {
    AdvertisingSheet()
        .environment(GameState())
}
