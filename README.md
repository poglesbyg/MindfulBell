# Stillpoint

Previously called Mindful Bell; the repository, Xcode target, bundle ID and product ID keep that name.

A macOS menu bar app with a meditation timer, session history, and bells to bring you back to the present during the day.

- **Meditation**: choose a length, optional interval bells, and a short quiet time before the opening bell. One bell starts the sit, three bells end it. The menu bar shows the time remaining, and the Mac stays awake while you sit.
- **History**: every sit of a minute or more is saved. The History window shows your current and longest streaks, time sat, minutes per day for the last 30 days, and each sit (select one and press Delete to remove it).
- **Mindful day**: a single bell every so often, at regular or varied times, only during the hours you pick. It stays quiet during a sit, and any bell that came due while the Mac was asleep is skipped.
- **Shortcuts and Siri**: actions for Start Meditation (with an optional length; outputs when it will end), End Meditation, Ring Bell, Set Mindful Day and Get Meditation Minutes. Siri and Spotlight phrases work without any setup, e.g. "Start meditating with Stillpoint".
- **Focus**: add the Stillpoint filter to a Focus in System Settings › Focus to silence Mindful Day bells, or start a sit, while that Focus is on. In the app's Settings you can also name shortcuts to run when a sit begins and ends, e.g. to turn Do Not Disturb on and off.
- **Bells**: singing bowl, temple bell, or small chime, generated from each bell's vibration modes (no audio files). `previews/` has WAV renders of each; they are not part of the app.

Requires macOS 14 (Sonoma) or later and Xcode 16 or later.

## Free and Pro

The meditation timer, interval bells and the singing bowl are free. **Stillpoint Pro** is a one-time in-app purchase (product ID `com.poglesbyg.mindfulbell.pro`) that unlocks:

- the History window (sits are recorded for everyone, so earlier sits appear once Pro is unlocked)
- Mindful Day bells
- the temple bell and small chime (anyone can preview them in the Pro window)
- Shortcuts actions, Siri phrases, the Focus filter and the start/end shortcuts

Shortcuts actions stay listed for free users; running one says it needs Pro. The code is in `Store.swift` and `ProView.swift`.

### Testing purchases

The **MindfulBell** scheme uses `MindfulBell.storekit`, so runs from Xcode buy Pro from a local test store: no App Store Connect setup, no real money. To start over as a free user, open Debug › StoreKit › Manage Transactions and delete the purchase. If purchases fail with "product not found", check Product › Scheme › Edit Scheme › Run › Options › StoreKit Configuration is set to `MindfulBell.storekit`.

## Build and run

1. Open `MindfulBell.xcodeproj`.
2. Select the **MindfulBell** target › **Signing & Capabilities** and pick your team. The bundle identifier is `com.poglesbyg.mindfulbell`; it can't change once the app is uploaded to App Store Connect.
3. Press ⌘R. Look for the bell in the menu bar.

Every file inside the `MindfulBell/` folder is part of the target automatically; new files you add there are picked up without editing the project.

### Turning Do Not Disturb on while you sit

Apps can't switch Focus modes directly, so use a shortcut:

1. In Shortcuts, make a shortcut named **Sit Focus On** containing *Set Focus*: turn Do Not Disturb on. Make **Sit Focus Off** that turns it off.
2. In Stillpoint › Settings, enter those names under *Run a shortcut*.

The app runs them through the Shortcuts app, which may come to the front briefly.

## Screenshot demo mode

For App Store screenshots, run with sample data:

1. Product › Scheme › Edit Scheme › Run › Arguments, and tick `-StillpointDemo YES`.
2. Run (⌘R). History shows about ten weeks of practice with a three-week streak, and Pro is unlocked.

Demo mode never reads or writes your real `history.json` (sits you do during a demo aren't kept) and doesn't touch StoreKit. It exists only in Debug builds, so archived builds can't enter it. **Untick the argument afterwards**, or History will keep showing the sample data.

To shoot the Pro window as a free user, for the in-app purchase review screenshot, untick the argument.

## App Store checklist

Already in place: App Sandbox, Hardened Runtime, the app icon, a privacy manifest (`PrivacyInfo.xcprivacy`, declaring UserDefaults use and no data collection), the Health & Fitness category, the copyright line, and no network access.

Still to do:

- [ ] Join the Apple Developer Program and set your team (above).
- [ ] Create the app record in App Store Connect. Every field, the keywords and the description are in `AppStore/listing.md`.
- [x] Privacy policy and support URLs: https://poglesbyg.github.io/stillpoint/privacy.html and https://poglesbyg.github.io/stillpoint/ (source in the poglesbyg.github.io repository).
- [ ] In App Store Connect, add a **Non-Consumable** in-app purchase with product ID `com.poglesbyg.mindfulbell.pro`, a price, a display name and description, Family Sharing on, and a review screenshot of the Pro window (`AppStore/screenshots/final/iap-review-pro-window.png`). Submit it together with the first version of the app.
- [x] Screenshots and description: four 2880×1800 screenshots in `AppStore/screenshots/final/`, and the description in `AppStore/listing.md`. They still need uploading.
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
| `Store.swift` | Pro purchase, restore, and entitlement checks (StoreKit 2) |
| `ProView.swift` | Pro window and the PRO badge on locked features |
| `BellSynth.swift` | Bell sound generation and playback |
| `AppStore/make_icon.py` | Draws the app icon and writes every size into the asset catalog (`python3 AppStore/make_icon.py`, needs Pillow) |
