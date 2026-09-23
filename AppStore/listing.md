# Stillpoint: App Store Connect listing

Copy these into App Store Connect. The character counts are checked against Apple's limits.

## App information

| Field | Value |
|---|---|
| Name (27/30) | Stillpoint: Meditation Bell |
| Subtitle (25/30) | Menu bar meditation timer |
| Bundle ID | com.poglesbyg.mindfulbell |
| SKU | stillpoint-mac |
| Primary category | Health & Fitness |
| Secondary category | Lifestyle |
| Age rating | 4+ (answer "None" to every content question) |
| Copyright | 2026 Paul Greenwood |
| Support URL | https://poglesbyg.github.io/stillpoint/ |
| Marketing URL | https://poglesbyg.github.io/stillpoint/ |
| Privacy Policy URL | https://poglesbyg.github.io/stillpoint/privacy.html |

**App Privacy:** choose "No, we do not collect data from this app". Stillpoint has no analytics, accounts or network calls. StoreKit purchases are Apple's and don't count as collection by the developer.

## Keywords (98/100)

```
mindfulness,singing bowl,breathe,calm,zen,interval,chime,gong,tibetan,streak,pause,focus,sit,relax
```

Words already in the name and subtitle (meditation, bell, timer, menu bar) are indexed automatically, so they aren't repeated here.

## Promotional text (142/170)

Can be changed at any time without a new app review.

```
Sit with a singing bowl, temple bell or chime, right from your menu bar. Then let a gentle bell bring you back to your breath through the day.
```

## Description

```
Stillpoint is a quiet meditation timer that lives in your Mac's menu bar. No account, no feed, no streak notifications nagging you. Just a bell when it's time to begin, and a bell when it's time to return.

MEDITATE
• Choose a length from 5 to 90 minutes, with a short settle-in before the opening bell
• Optional interval bells to mark the time as you sit
• One bell opens the sit, three bells close it
• The time remaining shows in the menu bar, and your Mac stays awake until the last bell

BELLS WORTH LISTENING TO
Stillpoint's bells aren't recordings. Each one is synthesised from the way a real bell vibrates: the slow shimmer of a Himalayan singing bowl, the deep hum of a temple bell, the bright ring of a small chime.

STILLPOINT PRO
A one-time purchase, no subscription:
• History: every sit, your current and longest streaks, and minutes per day for the last month
• Mindful Day: a single bell now and then through your working hours, at regular or varied times, as a reminder to stop and take a breath. It stays quiet while you meditate.
• The temple bell and small chime
• Shortcuts and Siri: start or end a sit, ring the bell, or ask how long you've meditated today
• Focus filters: silence the day's bells during a Focus, or start a sit when one turns on
• Run your own shortcuts when a sit begins and ends, for example to turn on Do Not Disturb

The sits you record before upgrading are kept, so your history is all there when you unlock Pro.

PRIVATE BY DESIGN
Stillpoint collects nothing. Your settings and history stay on your Mac.

Requires macOS 14 Sonoma or later.
```

## In-app purchase

Create under **Monetization › In-App Purchases**, type **Non-Consumable**.

| Field | Value |
|---|---|
| Reference name | Stillpoint Pro |
| Product ID | com.poglesbyg.mindfulbell.pro (must match exactly) |
| Price | $4.99 (US), or your choice |
| Family Sharing | Optional. If you turn it on, update the support page's "Restoring a purchase" section to say so. |
| Display name (14/30) | Stillpoint Pro |
| Description (42/45) | History, Mindful Day, all bells, Shortcuts |
| Review screenshot | The Pro window (menu bar › Unlock Pro) |
| Review notes | Open the menu bar bell and click Unlock Pro to reach the purchase window. |

The first in-app purchase has to be submitted together with an app version: select it on the version page under "In-App Purchases and Subscriptions" before submitting.

## App Review notes

```
Stillpoint is a menu bar app with no Dock icon or main window. After launch, click the bell icon in the menu bar to open it.

To try a sit quickly, choose Duration 5 min and Settle in None, then click Begin.

In-app purchase: click "Unlock Pro" at the bottom of the menu to open the Pro window, which lists what Pro includes and offers the purchase and Restore Purchases.

Shortcuts, Siri and Focus features require Pro. After purchasing, the actions appear in the Shortcuts app under Stillpoint, and the Focus filter under System Settings › Focus › (any Focus) › Focus filters.

No sign-in is needed.
```

## Screenshots

Mac screenshots must be 16:10: 1280×800, 1440×900, 2560×1600 or 2880×1800. Up to 10; the first three matter most. Take them in screenshot demo mode (see the README) so History is populated.

How to capture: set a calm desktop picture, hide other menu bar items if you can, then press ⌘⇧5 and choose **Capture Entire Screen**. On a Retina display the capture is twice the "Looks like" size in System Settings › Displays, so a display set to look like 1440×900 gives 2880×1800 exactly. Otherwise, crop to 16:10 and resize to 2880×1800 in Preview (Tools › Adjust Size).

Suggested set:

1. The menu open over a calm desktop, idle, showing duration and bell choices. Caption: "Meditation, one click away"
2. A sit in progress: time remaining in the menu bar and the large countdown. Caption: "Just you and the bell"
3. The History window with a few weeks of sits. Caption: "See your practice grow"
4. The Mindful Day settings. Caption: "A bell to come back to your breath"
5. Shortcuts with the Stillpoint actions. Caption: "Works with Shortcuts, Siri and Focus"
