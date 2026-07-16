import ArcadeAudioKit
import Foundation

public typealias GeneratedSFXFrequency = AudioPitch
public typealias GeneratedSFXSegment = AudioSegment
public typealias GeneratedSFXWaveform = AudioWaveform

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
        AudioRepeatedMotif(segments: motif, repeatCount: repeatCount)
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
            segments: intro + body,
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

    public init(failTailRepeatCount: Int = GeneratedSFXProfile.defaultFailTailRepeatCount) {
        let resolvedRepeatCount = max(0, failTailRepeatCount)
        self.failTailRepeatCount = resolvedRepeatCount
        self.start = Self.makeStartRecipe()
        self.bip = Self.makeBipRecipe()
        self.fail = Self.makeFailRecipe(failTailRepeatCount: resolvedRepeatCount)
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
}
