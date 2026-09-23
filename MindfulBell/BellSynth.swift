import AppKit
import AVFoundation

/// The bell sounds are synthesised from their vibration modes, so the app ships no audio files.
enum BellTone: String, CaseIterable, Identifiable {
    case bowl, temple, chime

    var id: String { rawValue }

    var name: String {
        switch self {
        case .bowl: return "Singing bowl"
        case .temple: return "Temple bell"
        case .chime: return "Small chime"
        }
    }

    /// Frequency of the reference partial, in Hz.
    fileprivate var fundamental: Double {
        switch self {
        case .bowl: return 262
        case .temple: return 220
        case .chime: return 784
        }
    }

    /// Time for the longest-lived partial to fall by 60 dB.
    fileprivate var ringSeconds: Double {
        switch self {
        case .bowl: return 11
        case .temple: return 14
        case .chime: return 6
        }
    }

    /// Mode frequency ratios, relative amplitudes, and each mode's share of `ringSeconds`.
    fileprivate var partials: [(ratio: Double, amp: Double, decay: Double)] {
        switch self {
        case .bowl:
            // Measured modes of a Himalayan singing bowl are roughly 1 : 2.7 : 5.0 : 8.0 : 11.6.
            return [(1.00, 1.00, 1.00), (2.71, 0.50, 0.70), (5.03, 0.25, 0.45),
                    (7.99, 0.12, 0.30), (11.6, 0.06, 0.20)]
        case .temple:
            // Large cast bell: hum, prime, tierce, quint, nominal and upper partials.
            return [(0.50, 0.70, 1.00), (1.00, 1.00, 0.80), (1.19, 0.45, 0.55),
                    (1.50, 0.30, 0.45), (2.00, 0.50, 0.40), (2.51, 0.15, 0.25),
                    (2.66, 0.10, 0.20), (3.01, 0.08, 0.15)]
        case .chime:
            // Free-free bar / tube modes.
            return [(1.00, 1.00, 1.00), (2.76, 0.45, 0.50), (5.40, 0.20, 0.25),
                    (8.93, 0.08, 0.12)]
        }
    }

    fileprivate var strikeSpacing: Double { 4.0 }
}

final class BellSynth {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    private var cache: [String: AVAudioPCMBuffer] = [:]
    private var generation = 0

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    /// Renders a tone ahead of time so the first strike isn't delayed.
    func prepare(_ tone: BellTone) {
        _ = buffer(tone, strikes: 1)
    }

    func strike(_ tone: BellTone, times: Int = 1, volume: Float) {
        let buffer = buffer(tone, strikes: max(1, times))
        do {
            if !engine.isRunning {
                engine.prepare()
                try engine.start()
            }
        } catch {
            NSSound.beep()
            return
        }

        generation += 1
        let current = generation
        player.volume = volume
        player.scheduleBuffer(buffer, at: nil, options: .interrupts,
                              completionCallbackType: .dataPlayedBack) { [weak self] _ in
            // Release the audio device once the last bell has faded.
            DispatchQueue.main.async {
                guard let self, self.generation == current else { return }
                self.player.stop()
                self.engine.stop()
            }
        }
        if !player.isPlaying { player.play() }
    }

    private func buffer(_ tone: BellTone, strikes: Int) -> AVAudioPCMBuffer {
        let key = "\(tone.rawValue)-\(strikes)"
        if let cached = cache[key] { return cached }
        let rendered = render(tone, strikes: strikes)
        cache[key] = rendered
        return rendered
    }

    private func render(_ tone: BellTone, strikes: Int) -> AVAudioPCMBuffer {
        let rate = format.sampleRate
        let strikeFrames = Int(tone.ringSeconds * rate)
        let spacingFrames = Int(tone.strikeSpacing * rate)
        let total = spacingFrames * (strikes - 1) + strikeFrames

        // One strike, rendered once and mixed in at each strike offset.
        var strikeL = [Float](repeating: 0, count: strikeFrames)
        var strikeR = [Float](repeating: 0, count: strikeFrames)

        for (index, p) in tone.partials.enumerated() {
            let frequency = tone.fundamental * p.ratio
            // Real bells are slightly asymmetric, so each mode is a pair of near-equal
            // frequencies that beat slowly against each other; that's the shimmer.
            let beat = 0.4 + 0.25 * Double(index)
            let tau = p.decay * tone.ringSeconds / 6.9 // 6.9 ≈ ln(1000), i.e. −60 dB
            let w1 = 2 * Double.pi * frequency / rate
            let w2 = 2 * Double.pi * (frequency + beat) / rate
            let stereoPhase = 1.3 + 0.9 * Double(index)

            for n in 0..<strikeFrames {
                let t = Double(n) / rate
                let envelope = p.amp * exp(-t / tau) * min(1, t / 0.004)
                let a = sin(w1 * Double(n))
                strikeL[n] += Float(envelope * 0.5 * (a + sin(w2 * Double(n))))
                strikeR[n] += Float(envelope * 0.5 * (a + sin(w2 * Double(n) + stereoPhase)))
            }
        }

        // A soft mallet thump: a brief burst of low-passed noise.
        var lowpass: Float = 0
        let thumpFrames = Int(0.03 * rate)
        for n in 0..<thumpFrames {
            lowpass += 0.15 * (Float.random(in: -1...1) - lowpass)
            let envelope = Float(exp(-Double(n) / (0.006 * rate)))
            strikeL[n] += 0.6 * envelope * lowpass
            strikeR[n] += 0.6 * envelope * lowpass
        }

        // Fade the tail so the buffer ends without a click.
        let fadeFrames = Int(0.05 * rate)
        for n in 0..<fadeFrames {
            let gain = Float(n) / Float(fadeFrames)
            strikeL[strikeFrames - 1 - n] *= gain
            strikeR[strikeFrames - 1 - n] *= gain
        }

        let peak = max(strikeL.map(abs).max() ?? 1, strikeR.map(abs).max() ?? 1)
        let gain = 0.7 / max(peak, 1e-6)

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total))!
        buffer.frameLength = AVAudioFrameCount(total)
        let left = buffer.floatChannelData![0]
        let right = buffer.floatChannelData![1]
        for n in 0..<total {
            left[n] = 0
            right[n] = 0
        }
        for s in 0..<strikes {
            let offset = s * spacingFrames
            for n in 0..<strikeFrames {
                left[offset + n] += strikeL[n] * gain
                right[offset + n] += strikeR[n] * gain
            }
        }
        return buffer
    }
}
