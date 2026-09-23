import SwiftUI

@main
struct MindfulBellApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var bell = BellController.shared
    @StateObject private var history = HistoryStore.shared

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(bell)
                .environmentObject(history)
        } label: {
            MenuBarLabel()
                .environmentObject(bell)
        }
        .menuBarExtraStyle(.window)

        Window("Meditation History", id: WindowID.history) {
            HistoryView()
                .environmentObject(history)
        }
        .defaultSize(width: 560, height: 620)

        Window("Mindful Bell Settings", id: WindowID.settings) {
            SettingsView()
                .environmentObject(bell)
        }
        .windowResizability(.contentSize)
    }
}

enum WindowID {
    static let history = "history"
    static let settings = "settings"
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // A menu bar app should start with no windows, even if SwiftUI or window
        // restoration opened one. The menu bar panel itself can't become main.
        DispatchQueue.main.async {
            for window in NSApp.windows where window.isVisible && window.canBecomeMain {
                window.close()
            }
        }
    }
}

/// The menu bar shows a bell, or the time remaining while a sit is in progress.
struct MenuBarLabel: View {
    @EnvironmentObject private var bell: BellController

    var body: some View {
        if let text = bell.menuBarText {
            Text(text).monospacedDigit()
        } else {
            Image(systemName: bell.remindersEnabled ? "bell.fill" : "bell")
        }
    }
}
