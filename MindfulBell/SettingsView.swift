import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var bell: BellController

    var body: some View {
        Form {
            Section {
                Toggle("Open at login", isOn: $bell.launchAtLogin)
            }

            Section {
                TextField("When a sit begins", text: $bell.startShortcutName, prompt: Text("Shortcut name"))
                TextField("When a sit ends", text: $bell.endShortcutName, prompt: Text("Shortcut name"))
                HStack {
                    Spacer()
                    Button("Open Shortcuts") { open("shortcuts://") }
                }
            } header: {
                Text("Run a shortcut")
            } footer: {
                Text("For example, a shortcut with “Set Focus: Do Not Disturb on” when a sit begins and “off” when it ends. Leave a field empty to skip it.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Text("In System Settings › Focus, choose a Focus and add the Mindful Bell filter. It can silence Mindful Day bells or start a sit while that Focus is on.")
                HStack {
                    Spacer()
                    Button("Open Focus Settings") {
                        open("x-apple.systempreferences:com.apple.Focus-Settings.extension",
                             fallback: "x-apple.systempreferences:")
                    }
                }
            } header: {
                Text("Focus")
            }

            Section {
                Text("Mindful Bell adds these actions to the Shortcuts app: Start Meditation, End Meditation, Ring Bell, Set Mindful Day and Get Meditation Minutes. You can also ask Siri to “Start meditating with Mindful Bell”.")
            } header: {
                Text("Shortcuts actions")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func open(_ address: String, fallback: String? = nil) {
        if let url = URL(string: address), NSWorkspace.shared.open(url) { return }
        if let fallback, let url = URL(string: fallback) { NSWorkspace.shared.open(url) }
    }
}
