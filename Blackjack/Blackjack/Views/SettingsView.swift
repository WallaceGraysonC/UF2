import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @EnvironmentObject var gameCenter: GameCenterManager
    @ObservedObject private var audio = AudioManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false
    @State private var hapticsEnabled = Haptics.isEnabled

    var body: some View {
        NavigationView {
            Form {
                Section("Bankroll") {
                    HStack {
                        Text("Current Chips")
                        Spacer()
                        Text("$\(bankroll.chips)").bold().foregroundColor(BJTheme.goldBright)
                    }
                    HStack {
                        Text("Best Ever")
                        Spacer()
                        Text("$\(bankroll.highestChips)").foregroundColor(.secondary)
                    }
                    Button("Top Up to $\(BankrollManager.bankrollTopUpFloor)") {
                        showResetConfirm = true
                    }
                    .disabled(!bankroll.canTopUpBankroll)
                    .foregroundColor(bankroll.canTopUpBankroll ? .red : .secondary)
                    Text(topUpHint)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Music") {
                    HStack(spacing: 12) {
                        Image(systemName: audio.musicVolume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundColor(audio.musicVolume == 0 ? .secondary : BJTheme.goldBright)
                            .frame(width: 22)
                        Slider(value: $audio.musicVolume, in: 0...1)
                        Text(audio.musicVolume == 0 ? "Off" : "\(Int(audio.musicVolume * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                            .frame(width: 38, alignment: .trailing)
                    }
                    Text("Off until you turn it up. Mixes with whatever you're already playing, and stays quiet when your ringer is on silent.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Haptics") {
                    Toggle("Table Feedback", isOn: $hapticsEnabled)
                        .onChange(of: hapticsEnabled) { _, on in
                            Haptics.isEnabled = on
                            if on { Haptics.tap() }
                        }
                    Text("A tap when the action reaches you, when you win a hand, and when you bust out.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Game Center") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(gameCenter.isAuthenticated ? "Signed in as \(gameCenter.localPlayerName)" : "Not signed in")
                            .foregroundColor(gameCenter.isAuthenticated ? .green : .secondary)
                    }
                    if !gameCenter.isAuthenticated {
                        Button("Sign in to Game Center") { gameCenter.authenticate() }
                    }
                }

                Section("iCloud Sync") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(bankroll.isCloudAvailable ? "Syncing" : "Unavailable")
                            .foregroundColor(bankroll.isCloudAvailable ? .green : .secondary)
                    }
                    Text("Your chip balance and owned cosmetics automatically sync across your devices using iCloud, as long as you're signed into iCloud with this app's iCloud capability enabled.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion).foregroundColor(.secondary)
                    }
                    Text("This game has no ads, no pop-ups, and no in-app purchases. Chips are a free virtual currency used only to keep score and unlock cosmetics -- they cannot be bought with real money or cashed out.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .tint(BJTheme.gold)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Top Up Your Bankroll?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Top Up") { bankroll.topUpBankroll() }
            } message: {
                Text("Brings your balance up to $\(BankrollManager.bankrollTopUpFloor) — enough for a couple of buy-ins at the main table. Your owned cosmetics are kept.")
            }
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    private var topUpHint: String {
        if bankroll.canTopUpBankroll {
            return "Available now — this adds $\(bankroll.topUpAmount), bringing you to $\(BankrollManager.bankrollTopUpFloor). It tops up to that figure rather than adding to it, so anything pricier has to be won at the table."
        }
        return "Available whenever you drop under $\(BankrollManager.bankrollTopUpFloor) — you're not short yet."
    }
}
