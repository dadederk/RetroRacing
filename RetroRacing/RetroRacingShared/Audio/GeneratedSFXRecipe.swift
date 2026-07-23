internal import ArcadeAudioKit
import Foundation

public enum GeneratedSFXWaveform: String, Sendable, Equatable, CaseIterable {
    case sine
    case triangle
    case square
}

public enum GeneratedSFXNote: Sendable, Equatable, Hashable {
    case c5
    case e5
    case g5
    case b5
    case c6
}

public enum GeneratedSFXFrequency: Sendable, Equatable {
    case constant(GeneratedSFXNote)
    case constantHz(Double)
    case sweepHz(startHz: Double, endHz: Double)
}

public struct GeneratedSFXSegment: Sendable, Equatable {
    public let waveform: GeneratedSFXWaveform
    public let pitch: GeneratedSFXFrequency
    public let durationMilliseconds: Double
    public let amplitudePercent: Double
    public let attackMilliseconds: Double
    public let decayMilliseconds: Double

    public init(
        waveform: GeneratedSFXWaveform,
        pitch: GeneratedSFXFrequency,
        durationMilliseconds: Double,
        amplitudePercent: Double,
        attackMilliseconds: Double,
        decayMilliseconds: Double
    ) {
        self.waveform = waveform
        self.pitch = pitch
        self.durationMilliseconds = Self.nonNegative(durationMilliseconds)
        self.amplitudePercent = min(Self.nonNegative(amplitudePercent), 100)
        self.attackMilliseconds = Self.nonNegative(attackMilliseconds)
        self.decayMilliseconds = Self.nonNegative(decayMilliseconds)
    }

    public var duration: TimeInterval {
        durationMilliseconds / 1000.0
    }

    private static func nonNegative(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}

public struct GeneratedSFXTailPattern: Sendable, Equatable {
    public let motif: [GeneratedSFXSegment]
    public let repeatCount: Int

    public init(motif: [GeneratedSFXSegment], repeatCount: Int) {
        self.motif = motif
        self.repeatCount = max(0, repeatCount)
    }

    public var expandedSegments: [GeneratedSFXSegment] {
        guard motif.isEmpty == false, repeatCount > 0 else { return [] }
        var expanded: [GeneratedSFXSegment] = []
        expanded.reserveCapacity(motif.count * repeatCount)
        for _ in 0..<repeatCount {
            expanded.append(contentsOf: motif)
        }
        return expanded
    }

    var arcadeAudioMotif: AudioRepeatedMotif {
        AudioRepeatedMotif(
            segments: motif.map(\.arcadeAudioSegment),
            repeatCount: repeatCount
        )
    }
}

public struct GeneratedSFXRecipe: Sendable, Equatable {
    public let intro: [GeneratedSFXSegment]
    public let body: [GeneratedSFXSegment]
    public let tailPattern: GeneratedSFXTailPattern?

    public init(
        intro: [GeneratedSFXSegment],
        body: [GeneratedSFXSegment],
        tailPattern: GeneratedSFXTailPattern? = nil
    ) {
        self.intro = intro
        self.body = body
        self.tailPattern = tailPattern
    }

    public var expandedSegments: [GeneratedSFXSegment] {
        intro + body + (tailPattern?.expandedSegments ?? [])
    }

    public var duration: TimeInterval {
        expandedSegments.reduce(0) { partialResult, segment in
            partialResult + segment.duration
        }
    }

    var arcadeAudioRecipe: AudioRecipe {
        AudioRecipe(
            segments: (intro + body).map(\.arcadeAudioSegment),
            repeatedMotif: tailPattern?.arcadeAudioMotif
        )
    }
}

public struct GeneratedSFXProfile: Sendable, Equatable {
    public static let baselineFailTailRepeatCount = 4
    public static let defaultFailTailRepeatCount = baselineFailTailRepeatCount - 1

    public let failTailRepeatCount: Int
    public let start: GeneratedSFXRecipe
    public let bip: GeneratedSFXRecipe
    public let fail: GeneratedSFXRecipe
    public let sharePlayCountdownLow: GeneratedSFXRecipe
    public let sharePlayCountdownMid: GeneratedSFXRecipe
    public let sharePlayCountdownHigh: GeneratedSFXRecipe
    public let sharePlayCountdownGo: GeneratedSFXRecipe

    public init(failTailRepeatCount: Int = GeneratedSFXProfile.defaultFailTailRepeatCount) {
        let resolvedRepeatCount = max(0, failTailRepeatCount)
        self.failTailRepeatCount = resolvedRepeatCount
        self.start = Self.makeStartRecipe()
        self.bip = Self.makeBipRecipe()
        self.fail = Self.makeFailRecipe(failTailRepeatCount: resolvedRepeatCount)
        self.sharePlayCountdownLow = Self.makeSharePlayCountdownStepRecipe(
            pitch: .constant(.c5),
            durationMilliseconds: 100,
            amplitudePercent: 24
        )
        self.sharePlayCountdownMid = Self.makeSharePlayCountdownStepRecipe(
            pitch: .constant(.e5),
            durationMilliseconds: 100,
            amplitudePercent: 25
        )
        self.sharePlayCountdownHigh = Self.makeSharePlayCountdownStepRecipe(
            pitch: .constant(.g5),
            durationMilliseconds: 100,
            amplitudePercent: 26
        )
        self.sharePlayCountdownGo = Self.makeSharePlayCountdownGoRecipe()
    }

    public static let defaultProfile = GeneratedSFXProfile()

    public func withFailTailRepeatCount(_ repeatCount: Int) -> GeneratedSFXProfile {
        GeneratedSFXProfile(failTailRepeatCount: repeatCount)
    }

    public func recipe(for effect: SoundEffect) -> GeneratedSFXRecipe {
        switch effect {
        case .start:
            return start
        case .bip:
            return bip
        case .fail:
            return fail
        case .sharePlayCountdownLow:
            return sharePlayCountdownLow
        case .sharePlayCountdownMid:
            return sharePlayCountdownMid
        case .sharePlayCountdownHigh:
            return sharePlayCountdownHigh
        case .sharePlayCountdownGo:
            return sharePlayCountdownGo
        }
    }

    private static func makeStartRecipe() -> GeneratedSFXRecipe {
        GeneratedSFXRecipe(
            intro: [
                GeneratedSFXSegment(
                    waveform: .sine,
                    pitch: .constant(.c5),
                    durationMilliseconds: 110,
                    amplitudePercent: 23,
                    attackMilliseconds: 3,
                    decayMilliseconds: 22
                )
            ],
            body: [
                GeneratedSFXSegment(
                    waveform: .sine,
                    pitch: .constant(.e5),
                    durationMilliseconds: 110,
                    amplitudePercent: 24,
                    attackMilliseconds: 3,
                    decayMilliseconds: 22
                ),
                GeneratedSFXSegment(
                    waveform: .sine,
                    pitch: .constant(.g5),
                    durationMilliseconds: 130,
                    amplitudePercent: 25,
                    attackMilliseconds: 3,
                    decayMilliseconds: 26
                )
            ]
        )
    }

    private static func makeBipRecipe() -> GeneratedSFXRecipe {
        GeneratedSFXRecipe(
            intro: [
                GeneratedSFXSegment(
                    waveform: .sine,
                    pitch: .constant(.c5),
                    durationMilliseconds: 26,
                    amplitudePercent: 20,
                    attackMilliseconds: 1,
                    decayMilliseconds: 12
                )
            ],
            body: [
                GeneratedSFXSegment(
                    waveform: .sine,
                    pitch: .constant(.e5),
                    durationMilliseconds: 26,
                    amplitudePercent: 18,
                    attackMilliseconds: 1,
                    decayMilliseconds: 12
                ),
                GeneratedSFXSegment(
                    waveform: .sine,
                    pitch: .constant(.g5),
                    durationMilliseconds: 26,
                    amplitudePercent: 17,
                    attackMilliseconds: 1,
                    decayMilliseconds: 12
                )
            ]
        )
    }

    private static func makeFailRecipe(failTailRepeatCount: Int) -> GeneratedSFXRecipe {
        let intro = [
            GeneratedSFXSegment(
                waveform: .square,
                pitch: .constantHz(330),
                durationMilliseconds: 120,
                amplitudePercent: 24,
                attackMilliseconds: 2,
                decayMilliseconds: 18
            ),
            GeneratedSFXSegment(
                waveform: .square,
                pitch: .constantHz(277.18),
                durationMilliseconds: 120,
                amplitudePercent: 24,
                attackMilliseconds: 2,
                decayMilliseconds: 20
            )
        ]

        let downturn = [
            GeneratedSFXSegment(
                waveform: .triangle,
                pitch: .sweepHz(startHz: 260, endHz: 220),
                durationMilliseconds: 150,
                amplitudePercent: 22,
                attackMilliseconds: 2,
                decayMilliseconds: 20
            ),
            GeneratedSFXSegment(
                waveform: .triangle,
                pitch: .sweepHz(startHz: 220, endHz: 185),
                durationMilliseconds: 150,
                amplitudePercent: 22,
                attackMilliseconds: 2,
                decayMilliseconds: 20
            ),
            GeneratedSFXSegment(
                waveform: .triangle,
                pitch: .sweepHz(startHz: 185, endHz: 155),
                durationMilliseconds: 160,
                amplitudePercent: 21,
                attackMilliseconds: 2,
                decayMilliseconds: 22
            ),
            GeneratedSFXSegment(
                waveform: .triangle,
                pitch: .sweepHz(startHz: 155, endHz: 130),
                durationMilliseconds: 160,
                amplitudePercent: 20,
                attackMilliseconds: 2,
                decayMilliseconds: 22
            )
        ]

        let tailMotif = [
            GeneratedSFXSegment(
                waveform: .triangle,
                pitch: .sweepHz(startHz: 130, endHz: 118),
                durationMilliseconds: 180,
                amplitudePercent: 18,
                attackMilliseconds: 2,
                decayMilliseconds: 28
            ),
            GeneratedSFXSegment(
                waveform: .triangle,
                pitch: .sweepHz(startHz: 118, endHz: 104),
                durationMilliseconds: 160,
                amplitudePercent: 16,
                attackMilliseconds: 2,
                decayMilliseconds: 30
            )
        ]

        return GeneratedSFXRecipe(
            intro: intro,
            body: downturn,
            tailPattern: GeneratedSFXTailPattern(
                motif: tailMotif,
                repeatCount: failTailRepeatCount
            )
        )
    }

    private static func makeSharePlayCountdownStepRecipe(
        pitch: GeneratedSFXFrequency,
        durationMilliseconds: Double,
        amplitudePercent: Double
    ) -> GeneratedSFXRecipe {
        GeneratedSFXRecipe(
            intro: [],
            body: [
                GeneratedSFXSegment(
                    waveform: .sine,
                    pitch: pitch,
                    durationMilliseconds: durationMilliseconds,
                    amplitudePercent: amplitudePercent,
                    attackMilliseconds: 2,
                    decayMilliseconds: 28
                )
            ]
        )
    }

    private static func makeSharePlayCountdownGoRecipe() -> GeneratedSFXRecipe {
        GeneratedSFXRecipe(
            intro: [
                GeneratedSFXSegment(
                    waveform: .sine,
                    pitch: .constant(.b5),
                    durationMilliseconds: 90,
                    amplitudePercent: 26,
                    attackMilliseconds: 2,
                    decayMilliseconds: 12
                )
            ],
            body: [
                GeneratedSFXSegment(
                    waveform: .sine,
                    pitch: .constant(.c6),
                    durationMilliseconds: 330,
                    amplitudePercent: 28,
                    attackMilliseconds: 2,
                    decayMilliseconds: 70
                )
            ]
        )
    }
}

private extension GeneratedSFXWaveform {
    var arcadeAudioWaveform: AudioWaveform {
        switch self {
        case .sine:
            return .sine
        case .triangle:
            return .triangle
        case .square:
            return .square
        }
    }
}

private extension GeneratedSFXFrequency {
    var arcadeAudioPitch: AudioPitch {
        switch self {
        case .constant(let note):
            return .constant(note.arcadeAudioNote)
        case .constantHz(let frequency):
            return .constantHz(frequency)
        case .sweepHz(let startHz, let endHz):
            return .sweepHz(startHz: startHz, endHz: endHz)
        }
    }
}

private extension GeneratedSFXNote {
    var arcadeAudioNote: AudioNote {
        switch self {
        case .c5:
            return .c5
        case .e5:
            return .e5
        case .g5:
            return .g5
        case .b5:
            return .b5
        case .c6:
            return AudioNote(.c, octave: 6)
        }
    }
}

private extension GeneratedSFXSegment {
    var arcadeAudioSegment: AudioSegment {
        AudioSegment(
            waveform: waveform.arcadeAudioWaveform,
            pitch: pitch.arcadeAudioPitch,
            durationMilliseconds: durationMilliseconds,
            amplitudePercent: amplitudePercent,
            attackMilliseconds: attackMilliseconds,
            decayMilliseconds: decayMilliseconds
        )
    }
}
