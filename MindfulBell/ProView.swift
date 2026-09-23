import StoreKit
import SwiftUI

struct ProView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var bell: BellController
    @Environment(\.purchase) private var purchase

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Stillpoint Pro").font(.title.weight(.semibold))
                Text(store.isPro ? "Unlocked. Thank you for supporting Stillpoint."
                                 : "One purchase, no subscription.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Feature(icon: "chart.bar", title: "History and streaks",
                        detail: "Every sit, your streaks, and minutes per day. Sits you've already done are included.")
                Feature(icon: "sun.max", title: "Mindful Day",
                        detail: "A bell now and then through the day, to stop and breathe.")
                Feature(icon: "bell.and.waves.left.and.right", title: "All bells",
                        detail: "Temple bell and small chime, as well as the singing bowl.")
                Feature(icon: "moon", title: "Shortcuts, Siri and Focus",
                        detail: "Start and end sits from Shortcuts or Siri, and link sits to your Focus modes.")
            }

            HStack(spacing: 8) {
                Text("Hear the bells:").foregroundStyle(.secondary)
                ForEach(BellTone.allCases) { tone in
                    Button(tone.name) { bell.preview(tone) }
                }
            }
            .font(.callout)

            Divider()

            if store.isPro {
                Label("Pro is unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                HStack {
                    if let product = store.product {
                        Button {
                            Task {
                                do {
                                    await store.handle(try await purchase(product))
                                } catch {
                                    store.message = error.localizedDescription
                                }
                            }
                        } label: {
                            Text("Unlock Pro for \(product.displayPrice)")
                                .frame(minWidth: 180)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    } else {
                        Text("The App Store can't be reached right now.")
                            .foregroundStyle(.secondary)
                        Button("Try Again") { Task { await store.loadProduct() } }
                    }
                    Spacer()
                    Button("Restore Purchases") { Task { await store.restore() } }
                        .disabled(store.isBusy)
                }
            }

            if let message = store.message {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: 440)
        .task { await store.loadProduct() }
    }
}

private struct Feature: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Small "Pro" label shown next to locked features; clicking it opens the Pro window.
struct ProBadge: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button {
            openWindow(id: WindowID.pro)
            NSApp.activate()
        } label: {
            Text("PRO")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .foregroundStyle(.white)
                .background(Color.accentColor, in: Capsule())
        }
        .buttonStyle(.plain)
        .help("Unlock with Stillpoint Pro")
    }
}
