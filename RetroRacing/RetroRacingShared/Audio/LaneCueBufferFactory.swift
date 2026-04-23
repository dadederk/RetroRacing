//
//  LaneCueBufferFactory.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 21/04/2026.
//

import Foundation
import AVFoundation

struct LaneCueBuffers {
    var tickBuffers: [AudioFeedbackMode: [UInt8: AVAudioPCMBuffer]]
    var laneMoveBuffers: [CueColumn: AVAudioPCMBuffer]
    var safetyMoveBuffers: [Bool: AVAudioPCMBuffer]
    var combinedMoveBuffers: [Bool: [CueColumn: AVAudioPCMBuffer]]
    var speedWarningBuffer: AVAudioPCMBuffer?

    static let empty = LaneCueBuffers(
        tickBuffers: [:],
        laneMoveBuffers: [:],
        safetyMoveBuffers: [:],
        combinedMoveBuffers: [:],
        speedWarningBuffer: nil
    )
}

private enum LaneCueWaveform {
    case sine
    case triangle
}

private enum SpeedWarningCueConstants {
    static let noteFrequencies: [Double] = [293.665, 349.228, 440.0]
    static let noteDuration: TimeInterval = 0.04
    static let intraNoteGapDuration: TimeInterval = 0.006
    static let interRepeatGapDuration: TimeInterval = 0.02
    static let repeatCount = 2
    static let amplitude = 0.22
}

final class LaneCueBufferFactory {
    private let format: AVAudioFormat?
    private let profile: LaneCueProfile

    init(format: AVAudioFormat?, profile: LaneCueProfile) {
        self.format = format
        self.profile = profile
    }

    func makeBuffers() -> LaneCueBuffers {
        guard format != nil else {
            return .empty
        }

        var buffers = LaneCueBuffers.empty

        for mode in [AudioFeedbackMode.cueChord, .cueArpeggio, .cueLanePulses] {
            var buffersByMask: [UInt8: AVAudioPCMBuffer] = [:]
            for mask in UInt8(0)...UInt8(7) {
                if let buffer = makeTickBuffer(mode: mode, safeMask: mask) {
                    buffersByMask[mask] = buffer
                }
            }
            buffers.tickBuffers[mode] = buffersByMask
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
            AppLog.error(
                AppLog.sound,
                "LANE_CUE_BUFFER_BUILD",
                outcome: .failed,
                fields: [.reason("move_safety_buffer_creation_failed")]
            )
            return buffers
        }

        buffers.safetyMoveBuffers[true] = safeSafetyBuffer
        buffers.safetyMoveBuffers[false] = unsafeSafetyBuffer

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
            buffers.laneMoveBuffers[column] = laneBuffer

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

        buffers.combinedMoveBuffers[true] = safeCombinedBuffers
        buffers.combinedMoveBuffers[false] = unsafeCombinedBuffers
        buffers.speedWarningBuffer = makeSpeedWarningBuffer()
        return buffers
    }

    private static func safeColumns(for mask: UInt8) -> [CueColumn] {
        CueColumn.allCases.filter { column in
            mask & (1 << UInt8(column.rawValue)) != 0
        }
    }

    private func makeSpeedWarningBuffer() -> AVAudioPCMBuffer? {
        guard let format else { return nil }

        let noteBuffers: [AVAudioPCMBuffer] = SpeedWarningCueConstants.noteFrequencies.compactMap { frequency in
            makeToneBuffer(
                frequency: frequency,
                duration: SpeedWarningCueConstants.noteDuration,
                waveform: .triangle,
                amplitude: SpeedWarningCueConstants.amplitude
            )
        }
        guard noteBuffers.count == SpeedWarningCueConstants.noteFrequencies.count else {
            return nil
        }

        let noteSamples = noteBuffers.map { Int($0.frameLength) }
        let intraNoteGapSamples = max(0, Int(SpeedWarningCueConstants.intraNoteGapDuration * format.sampleRate))
        let interRepeatGapSamples = max(0, Int(SpeedWarningCueConstants.interRepeatGapDuration * format.sampleRate))
        let notesPerRepeat = noteBuffers.count
        let repeatCount = max(1, SpeedWarningCueConstants.repeatCount)
        let samplesPerRepeat = noteSamples.reduce(0, +) + intraNoteGapSamples * max(0, notesPerRepeat - 1)
        let totalSamples = (samplesPerRepeat * repeatCount)
            + (interRepeatGapSamples * max(0, repeatCount - 1))

        guard totalSamples > 0,
              let combinedBuffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(totalSamples)
              ),
              let destination = combinedBuffer.floatChannelData?[0] else {
            return nil
        }
        combinedBuffer.frameLength = AVAudioFrameCount(totalSamples)
        for sampleIndex in 0..<totalSamples {
            destination[sampleIndex] = 0
        }

        var writeIndex = 0
        for repeatIndex in 0..<repeatCount {
            for (noteIndex, noteBuffer) in noteBuffers.enumerated() {
                guard let noteChannel = noteBuffer.floatChannelData?[0] else { continue }
                let currentNoteSamples = Int(noteBuffer.frameLength)
                for sampleIndex in 0..<currentNoteSamples {
                    destination[writeIndex + sampleIndex] = noteChannel[sampleIndex]
                }
                writeIndex += currentNoteSamples

                let isLastNoteInRepeat = noteIndex == (notesPerRepeat - 1)
                if isLastNoteInRepeat == false {
                    writeIndex += intraNoteGapSamples
                }
            }

            let isLastRepeat = repeatIndex == (repeatCount - 1)
            if isLastRepeat == false {
                writeIndex += interRepeatGapSamples
            }
        }

        return combinedBuffer
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
        waveform: LaneCueWaveform,
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
        waveform: LaneCueWaveform,
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
}
