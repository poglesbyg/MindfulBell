# Mindful Bell

A macOS menu bar app with a meditation timer, session history, and bells to bring you back to the present during the day.

- **Meditation**: choose a length, optional interval bells, and a short quiet time before the opening bell. One bell starts the sit, three bells end it. The menu bar shows the time remaining, and the Mac stays awake while you sit.
- **History**: every sit of a minute or more is saved. The History window shows your current and longest streaks, time sat, minutes per day for the last 30 days, and each sit (select one and press Delete to remove it).
- **Mindful day**: a single bell every so often, at regular or varied times, only during the hours you pick. It stays quiet during a sit, and any bell that came due while the Mac was asleep is skipped.
- **Shortcuts and Siri**: actions for Start Meditation (with an optional length; outputs when it will end), End Meditation, Ring Bell, Set Mindful Day and Get Meditation Minutes. Siri and Spotlight phrases work without any setup, e.g. "Start meditating with Mindful Bell".
- **Focus**: add the Mindful Bell filter to a Focus in System Settings › Focus to silence Mindful Day bells, or start a sit, while that Focus is on. In the app's Settings you can also name shortcuts to run when a sit begins and ends, e.g. to turn Do Not Disturb on and off.
- **Bells**: singing bowl, temple bell, or small chime, generated from each bell's vibration modes (no audio files). `previews/` has WAV renders of each; they are not part of the app.

Requires macOS 14 (Sonoma) or later and Xcode 16 or later.

## Build and run

1. Open `MindfulBell.xcodeproj`.
2. Select the **MindfulBell** target › **Signing & Capabilities** and pick your team. The bundle identifier is `com.poglesbyg.mindfulbell`; it can't change once the app is uploaded to App Store Connect.
3. Press ⌘R. Look for the bell in the menu bar.

Every file inside the `MindfulBell/` folder is part of the target automatically; new files you add there are picked up without editing the project.

### Turning Do Not Disturb on while you sit

Apps can't switch Focus modes directly, so use a shortcut:

1. In Shortcuts, make a shortcut named **Sit Focus On** containing *Set Focus*: turn Do Not Disturb on. Make **Sit Focus Off** that turns it off.
2. In Mindful Bell › Settings, enter those names under *Run a shortcut*.

The app runs them through the Shortcuts app, which may come to the front briefly.

## App Store checklist

Already in place: App Sandbox, Hardened Runtime, the app icon, a privacy manifest (`PrivacyInfo.xcprivacy`, declaring UserDefaults use and no data collection), the Health & Fitness category, and no network access.

Still to do:

- [ ] Join the Apple Developer Program and set your team (above).
- [ ] Create the app record in App Store Connect and check the name is available.
- [ ] Privacy policy URL and support URL (a one-page site is enough; the app collects nothing).
- [ ] Screenshots (at least one, 2880×1800 or another accepted Mac size) and a description.
- [ ] App Privacy questionnaire: "Data Not Collected".
- [ ] Product › Archive, then Distribute App › App Store Connect.

## Layout

| File | Purpose |
|---|---|
| `MindfulBellApp.swift` | App entry point, menu bar icon, History and Settings windows |
| `ContentView.swift` | The panel that opens from the menu bar |
| `BellController.swift` | Session timing, reminder scheduling, Focus handling, saved settings |
| `HistoryStore.swift` | Saved sits (`~/Library/Containers/<bundle id>/Data/Library/Application Support/Mindful Bell/history.json`) and streak statistics |
| `HistoryView.swift` | History window |
| `SettingsView.swift` | Settings window |
| `Intents.swift` | Shortcuts actions, Siri phrases, Focus filter |
| `BellSynth.swift` | Bell sound generation and playback |
