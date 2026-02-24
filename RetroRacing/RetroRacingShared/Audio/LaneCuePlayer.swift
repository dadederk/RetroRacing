//
//  LaneCuePlayer.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 17/02/2026.
//

import Foundation
import AVFoundation

public enum CueColumn: Int, CaseIterable, Sendable {
    case left = 0
    case middle = 1
    case right = 2
}

/// Central tuning profile for generated lane cues.
public struct LaneCueProfile: Equatable, Sendable {
    public let frequenciesHz: [CueColumn: Double]
    public let warningFrequencyHz: Double
    public let safeFeedbackFrequencyHz: Double
    public let unsafeFeedbackFrequencyHz: Double
    public let tickAmplitude: Double
    public let moveSafeAmplitude: Double
    public let moveUnsafeAmplitude: Double
    public let unsafeFrequencyMultiplier: Double
    public let chordDuration: TimeInterval
    public let arpeggioNoteDuration: TimeInterval
    public let lanePulseSlotDuration: TimeInterval
    public let moveLaneDuration: TimeInterval
    public let moveSafetyDuration: TimeInterval
    public let moveLaneToSafetyGapDuration: TimeInterval
    public let attack: TimeInterval
    public let decay: TimeInterval

    public init(
        frequenciesHz: [CueColumn: Double],
        warningFrequencyHz: Double,
        safeFeedbackFrequencyHz: Double,
        unsafeFeedbackFrequencyHz: Double,
        tickAmplitude: Double,
        moveSafeAmplitude: Double,
        moveUnsafeAmplitude: Double,
        unsafeFrequencyMultiplier: Double,
        chordDuration: TimeInterval,
        arpeggioNoteDuration: TimeInterval,
        lanePulseSlotDuration: TimeInterval,
        moveLaneDuration: TimeInterval,
        moveSafetyDuration: TimeInterval,
        moveLaneToSafetyGapDuration: TimeInterval,
        attack: TimeInterval,
        decay: TimeInterval
    ) {
        self.frequenciesHz = frequenciesHz
        self.warningFrequencyHz = warningFrequencyHz
        self.safeFeedbackFrequencyHz = safeFeedbackFrequencyHz
        self.unsafeFeedbackFrequencyHz = unsafeFeedbackFrequencyHz
        self.tickAmplitude = tickAmplitude
        self.moveSafeAmplitude = moveSafeAmplitude
        self.moveUnsafeAmplitude = moveUnsafeAmplitude
        self.unsafeFrequencyMultiplier = unsafeFrequencyMultiplier
        self.chordDuration = chordDuration
        self.arpeggioNoteDuration = arpeggioNoteDuration
        self.lanePulseSlotDuration = lanePulseSlotDuration
        self.moveLaneDuration = moveLaneDuration
        self.moveSafetyDuration = moveSafetyDuration
        self.moveLaneToSafetyGapDuration = moveLaneToSafetyGapDuration
        self.attack = attack
        self.decay = decay
    }

    public static let defaultPleasant = LaneCueProfile(
        frequenciesHz: [
            .left: 523.251,
            .middle: 659.255,
            .right: 783.991
        ],
        warningFrequencyHz: 440,
        safeFeedbackFrequencyHz: 987.767,
        unsafeFeedbackFrequencyHz: 415.305,
        tickAmplitude: 0.18,
        moveSafeAmplitude: 0.2,
        moveUnsafeAmplitude: 0.22,
        unsafeFrequencyMultiplier: 0.94,
        chordDuration: 0.07,
        arpeggioNoteDuration: 0.036,
        lanePulseSlotDuration: 0.03,
        moveLaneDuration: 0.045,
        moveSafetyDuration: 0.04,
        moveLaneToSafetyGapDuration: 0.006,
        attack: 0.003,
        decay: 0.02
    )
}

/// Audio guidance cues for lane safety and movement.
public protocol LaneCuePlayer {
    func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode)
    func playMoveCue(
        column: CueColumn,
        isSafe: Bool,
        mode: AudioFeedbackMode,
        style: LaneMoveCueStyle
    )
    func setVolume(_ volume: Double)
    func stopAll(fadeDuration: TimeInterval)
}

private enum CueWaveform {
    case sine
    case triangle
}

public final class AVLaneCuePlayer: LaneCuePlayer {
    private let engine = AVAudioEngine()
    private let tickPlayer = AVAudioPlayerNode()
    private let movePlayer = AVAudioPlayerNode()
    private let format: AVAudioFormat?
    private let profile: LaneCueProfile

    private var tickBuffers: [AudioFeedbackMode: [UInt8: AVAudioPCMBuffer]] = [:]
    private var laneMoveBuffers: [CueColumn: AVAudioPCMBuffer] = [:]
    private var safetyMoveBuffers: [Bool: AVAudioPCMBuffer] = [:]
    private var combinedMoveBuffers: [Bool: [CueColumn: AVAudioPCMBuffer]] = [:]
    private var volume: Float = Float(SoundPreferences.defaultVolume)
    private var fadeTask: Task<Void, Never>?

    public init(sampleRate: Double = 44_100, profile: LaneCueProfile = .defaultPleasant) {
        self.profile = profile
        self.format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)

        guard let format else {
            AppLog.error(AppLog.sound, "🔊 Lane cues unavailable: failed to create audio format")
            return
        }

        engine.attach(tickPlayer)
        engine.attach(movePlayer)
        engine.connect(tickPlayer, to: engine.mainMixerNode, format: format)
        engine.connect(movePlayer, to: engine.mainMixerNode, format: format)

        precomputeBuffers()
        startEngineIfNeeded()
        tickPlayer.play()
        movePlayer.play()
    }

    deinit {
        fadeTask?.cancel()
    }

    public func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode) {
        guard mode != .retro else { return }
        guard let modeBuffers = tickBuffers[mode] else { return }
        let mask = Self.mask(for: safeColumns)
        guard let buffer = modeBuffers[mask] else { return }
        play(buffer: buffer, on: tickPlayer)
    }

    public func playMoveCue(
        column: CueColumn,
        isSafe: Bool,
        mode: AudioFeedbackMode,
        style: LaneMoveCueStyle
    ) {
        guard mode != .retro else { return }
        let buffer: AVAudioPCMBuffer?
        switch style {
        case .laneConfirmation:
            buffer = laneMoveBuffers[column]
        case .safetyOnly:
            buffer = safetyMoveBuffers[isSafe]
        case .laneConfirmationAndSafety:
            buffer = combinedMoveBuffers[isSafe]?[column]
        case .haptics:
            buffer = nil
        }
        guard let buffer else { return }
        play(buffer: buffer, on: movePlayer)
    }

    public func setVolume(_ volume: Double) {
        self.volume = Float(min(max(volume, 0), 1))
        tickPlayer.volume = self.volume
        movePlayer.volume = self.volume
    }

    public func stopAll(fadeDuration: TimeInterval) {
        fadeTask?.cancel()
        let duration = max(0, fadeDuration)
        guard duration > 0 else {
            stopImmediately()
            return
        }

        let startTickVolume = tickPlayer.volume
        let startMoveVolume = movePlayer.volume
        let targetVolume = volume

        fadeTask = Task { [weak self] in
            guard let self else { return }
            let steps = 10
            let stepDuration = duration / Double(steps)

            for step in 0..<steps {
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                let fraction = Float(1.0 - Double(step + 1) / Double(steps))
                self.tickPlayer.volume = startTickVolume * fraction
                self.movePlayer.volume = startMoveVolume * fraction
            }

            self.stopImmediately()
            self.tickPlayer.volume = targetVolume
            self.movePlayer.volume = targetVolume
        }
    }

    private static func mask(for columns: Set<CueColumn>) -> UInt8 {
        columns.reduce(0) { partialResult, column in
            partialResult | (1 << UInt8(column.rawValue))
        }
    }

    private static func safeColumns(for mask: UInt8) -> [CueColumn] {
        CueColumn.allCases.filter { column in
            mask & (1 << UInt8(column.rawValue)) != 0
        }
    }

    private func precomputeBuffers() {
        for mode in [AudioFeedbackMode.cueChord, .cueArpeggio, .cueLanePulses] {
            var buffersByMask: [UInt8: AVAudioPCMBuffer] = [:]
            for mask in UInt8(0)...UInt8(7) {
                if let buffer = makeTickBuffer(mode: mode, safeMask: mask) {
                    buffersByMask[mask] = buffer
                }
            }
            tickBuffers[mode] = buffersByMask
        }

        var safeCombinedBuffers: [CueColumn: AVAudioPCMBuffer] = [:]
        var unsafeCombinedBuffers: [CueColumn: AVAudioPCMBuffer] = [:]
        guard let safeSafetyBuffer = makeToneBuffer(
            frequency: profile.safeFeedbackFrequencyHz,
            duration: profile.moveSafetyDuration,
            waveform: .sine,
            amplitude: profile.moveSafeAmplitude
        ), let unsafeSafetyBuffer = makeToneBuffer(
            frequency: profile.unsafeFeedbackFrequencyHz,
            duration: profile.moveSafetyDuration,
            waveform: .triangle,
            amplitude: profile.moveUnsafeAmplitude
        ) else {
            AppLog.error(AppLog.sound, "🔊 Lane cues unavailable: failed to create move safety buffers")
            return
        }
        safetyMoveBuffers[true] = safeSafetyBuffer
        safetyMoveBuffers[false] = unsafeSafetyBuffer
        for column in CueColumn.allCases {
            guard let frequency = profile.frequenciesHz[column] else { continue }

            guard let laneBuffer = makeToneBuffer(
                frequency: frequency,
                duration: profile.moveLaneDuration,
                waveform: .sine,
                amplitude: profile.moveSafeAmplitude
            ) else {
                continue
            }
            laneMoveBuffers[column] = laneBuffer

            if let safeCombined = makeSequentialBuffer(
                first: laneBuffer,
                second: safeSafetyBuffer,
                gapDuration: profile.moveLaneToSafetyGapDuration
            ) {
                safeCombinedBuffers[column] = safeCombined
            }

            if let unsafeCombined = makeSequentialBuffer(
                first: laneBuffer,
                second: unsafeSafetyBuffer,
                gapDuration: profile.moveLaneToSafetyGapDuration
            ) {
                unsafeCombinedBuffers[column] = unsafeCombined
            }
        }
        combinedMoveBuffers[true] = safeCombinedBuffers
        combinedMoveBuffers[false] = unsafeCombinedBuffers
    }

    private func makeTickBuffer(mode: AudioFeedbackMode, safeMask: UInt8) -> AVAudioPCMBuffer? {
        let safeColumns = Self.safeColumns(for: safeMask)
        let safeFrequencies = safeColumns.compactMap { profile.frequenciesHz[$0] }

        switch mode {
        case .retro:
            return nil
        case .cueChord:
            let frequencies = safeFrequencies.isEmpty ? [profile.warningFrequencyHz] : safeFrequencies
            return makeChordBuffer(
                frequencies: frequencies,
                duration: profile.chordDuration,
                amplitude: profile.tickAmplitude
            )
        case .cueArpeggio:
            let frequencies = safeFrequencies.isEmpty ? [profile.warningFrequencyHz] : safeFrequencies
            return makeArpeggioBuffer(
                frequencies: frequencies,
                noteDuration: profile.arpeggioNoteDuration,
                amplitude: profile.tickAmplitude
            )
        case .cueLanePulses:
            return makeLanePulseBuffer(
                safeColumns: Set(safeColumns),
                slotDuration: profile.lanePulseSlotDuration,
                amplitude: profile.tickAmplitude
            )
        }
    }

    private func makeChordBuffer(
        frequencies: [Double],
        duration: TimeInterval,
        amplitude: Double
    ) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }

        buffer.frameLength = frameCount
        let totalSamples = Int(frameCount)
        let attackSamples = max(1, Int(profile.attack * sampleRate))
        let decaySamples = max(1, Int(profile.decay * sampleRate))

        for sampleIndex in 0..<totalSamples {
            let time = Double(sampleIndex) / sampleRate
            var sampleValue = 0.0
            for frequency in frequencies {
                sampleValue += sin(2.0 * .pi * frequency * time)
            }
            sampleValue /= Double(max(1, frequencies.count))
            let envelope = envelopeValue(
                sampleIndex: sampleIndex,
                totalSamples: totalSamples,
                attackSamples: attackSamples,
                decaySamples: decaySamples
            )
            channel[sampleIndex] = Float(sampleValue * amplitude * envelope)
        }

        return buffer
    }

    private func makeArpeggioBuffer(
        frequencies: [Double],
        noteDuration: TimeInterval,
        amplitude: Double
    ) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let sampleRate = format.sampleRate
        let noteFrameCount = max(1, Int(noteDuration * sampleRate))
        let totalSamples = noteFrameCount * max(1, frequencies.count)

        guard totalSamples > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples)),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(totalSamples)

        let attackSamples = max(1, Int(profile.attack * sampleRate))
        let decaySamples = max(1, Int(profile.decay * sampleRate))

        for (noteIndex, frequency) in frequencies.enumerated() {
            let noteStart = noteIndex * noteFrameCount
            let noteEnd = min(totalSamples, noteStart + noteFrameCount)

            for sampleIndex in noteStart..<noteEnd {
                let localIndex = sampleIndex - noteStart
                let time = Double(localIndex) / sampleRate
                let wave = sin(2.0 * .pi * frequency * time)
                let envelope = envelopeValue(
                    sampleIndex: localIndex,
                    totalSamples: noteFrameCount,
                    attackSamples: attackSamples,
                    decaySamples: decaySamples
                )
                channel[sampleIndex] = Float(wave * amplitude * envelope)
            }
        }

        return buffer
    }

    private func makeLanePulseBuffer(
        safeColumns: Set<CueColumn>,
        slotDuration: TimeInterval,
        amplitude: Double
    ) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let sampleRate = format.sampleRate
        let slotSamples = max(1, Int(slotDuration * sampleRate))
        let totalSamples = slotSamples * CueColumn.allCases.count

        guard totalSamples > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples)),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(totalSamples)
        for sampleIndex in 0..<totalSamples {
            channel[sampleIndex] = 0
        }

        let attackSamples = max(1, Int(profile.attack * sampleRate))
        let decaySamples = max(1, Int(profile.decay * sampleRate))

        for (slotIndex, column) in CueColumn.allCases.enumerated() {
            guard safeColumns.contains(column),
                  let frequency = profile.frequenciesHz[column] else {
                continue
            }

            let slotStart = slotIndex * slotSamples
            let slotEnd = min(totalSamples, slotStart + slotSamples)
            for sampleIndex in slotStart..<slotEnd {
                let localIndex = sampleIndex - slotStart
                let time = Double(localIndex) / sampleRate
                let wave = sin(2.0 * .pi * frequency * time)
                let envelope = envelopeValue(
                    sampleIndex: localIndex,
                    totalSamples: slotSamples,
                    attackSamples: attackSamples,
                    decaySamples: decaySamples
                )
                channel[sampleIndex] = Float(wave * amplitude * envelope)
            }
        }

        if safeColumns.isEmpty,
           let warningBuffer = makeToneBuffer(
                frequency: profile.warningFrequencyHz,
                duration: slotDuration,
                waveform: .triangle,
                amplitude: amplitude
           ) {
            return warningBuffer
        }

        return buffer
    }

    private func makeToneBuffer(
        frequency: Double,
        duration: TimeInterval,
        waveform: CueWaveform,
        amplitude: Double
    ) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else {
            return nil
        }

        buffer.frameLength = frameCount
        let totalSamples = Int(frameCount)
        let attackSamples = max(1, Int(profile.attack * sampleRate))
        let decaySamples = max(1, Int(profile.decay * sampleRate))

        for sampleIndex in 0..<totalSamples {
            let time = Double(sampleIndex) / sampleRate
            let wave = waveformValue(
                waveform: waveform,
                frequency: frequency,
                time: time
            )
            let envelope = envelopeValue(
                sampleIndex: sampleIndex,
                totalSamples: totalSamples,
                attackSamples: attackSamples,
                decaySamples: decaySamples
            )
            channel[sampleIndex] = Float(wave * amplitude * envelope)
        }

        return buffer
    }

    private func makeSequentialBuffer(
        first: AVAudioPCMBuffer,
        second: AVAudioPCMBuffer,
        gapDuration: TimeInterval
    ) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let gapSamples = max(0, Int(gapDuration * format.sampleRate))
        let firstSamples = Int(first.frameLength)
        let secondSamples = Int(second.frameLength)
        let totalSamples = firstSamples + gapSamples + secondSamples
        guard totalSamples > 0,
              let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(totalSamples)
              ),
              let destination = buffer.floatChannelData?[0],
              let firstChannel = first.floatChannelData?[0],
              let secondChannel = second.floatChannelData?[0] else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(totalSamples)
        for sampleIndex in 0..<totalSamples {
            destination[sampleIndex] = 0
        }

        for sampleIndex in 0..<firstSamples {
            destination[sampleIndex] = firstChannel[sampleIndex]
        }

        let secondStart = firstSamples + gapSamples
        for sampleIndex in 0..<secondSamples {
            destination[secondStart + sampleIndex] = secondChannel[sampleIndex]
        }

        return buffer
    }

    private func waveformValue(
        waveform: CueWaveform,
        frequency: Double,
        time: Double
    ) -> Double {
        switch waveform {
        case .sine:
            return sin(2.0 * .pi * frequency * time)
        case .triangle:
            let phase = (frequency * time).truncatingRemainder(dividingBy: 1.0)
            return 4.0 * abs(phase - 0.5) - 1.0
        }
    }

    private func envelopeValue(
        sampleIndex: Int,
        totalSamples: Int,
        attackSamples: Int,
        decaySamples: Int
    ) -> Double {
        let sustainSamples = max(0, totalSamples - attackSamples - decaySamples)

        if sampleIndex < attackSamples {
            return Double(sampleIndex) / Double(attackSamples)
        }

        if sampleIndex < attackSamples + sustainSamples {
            return 1.0
        }

        let decayIndex = sampleIndex - attackSamples - sustainSamples
        return max(0.0, 1.0 - Double(decayIndex) / Double(decaySamples))
    }

    private func play(buffer: AVAudioPCMBuffer, on node: AVAudioPlayerNode) {
        fadeTask?.cancel()
        tickPlayer.volume = volume
        movePlayer.volume = volume
        startEngineIfNeeded()
        node.stop()
        if !node.isPlaying {
            node.play()
        }
        node.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
    }

    private func startEngineIfNeeded() {
        guard engine.isRunning == false else { return }
        do {
            try engine.start()
        } catch {
            AppLog.error(AppLog.sound, "🔊 Lane cue engine failed to start: \(error.localizedDescription)")
        }
    }

    private func stopImmediately() {
        tickPlayer.stop()
        movePlayer.stop()
    }
}
