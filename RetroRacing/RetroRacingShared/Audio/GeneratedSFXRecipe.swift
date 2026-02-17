import Foundation

public enum GeneratedSFXWaveform: Sendable {
    case sine
    case triangle
    case square
}

public enum GeneratedSFXFrequency: Sendable, Equatable {
    case constant(Double)
    case linear(startHz: Double, endHz: Double)

    func value(at progress: Double) -> Double {
        let clamped = min(max(progress, 0), 1)
        switch self {
        case .constant(let hz):
            return hz
        case .linear(let startHz, let endHz):
            return startHz + ((endHz - startHz) * clamped)
        }
    }
}

public struct GeneratedSFXSegment: Sendable, Equatable {
    public let waveform: GeneratedSFXWaveform
    public let frequency: GeneratedSFXFrequency
    public let duration: TimeInterval
    public let amplitude: Double
    public let attack: TimeInterval
    public let decay: TimeInterval

    public init(
        waveform: GeneratedSFXWaveform,
        frequency: GeneratedSFXFrequency,
        duration: TimeInterval,
        amplitude: Double,
        attack: TimeInterval,
        decay: TimeInterval
    ) {
        self.waveform = waveform
        self.frequency = frequency
        self.duration = max(0, duration)
        self.amplitude = max(0, amplitude)
        self.attack = max(0, attack)
        self.decay = max(0, decay)
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
                    frequency: .constant(523.251),
                    duration: 0.11,
                    amplitude: 0.23,
                    attack: 0.003,
                    decay: 0.022
                )
            ],
            body: [
                GeneratedSFXSegment(
                    waveform: .sine,
                    frequency: .constant(659.255),
                    duration: 0.11,
                    amplitude: 0.24,
                    attack: 0.003,
                    decay: 0.022
                ),
                GeneratedSFXSegment(
                    waveform: .sine,
                    frequency: .constant(783.991),
                    duration: 0.13,
                    amplitude: 0.25,
                    attack: 0.003,
                    decay: 0.026
                )
            ]
        )
    }

    private static func makeBipRecipe() -> GeneratedSFXRecipe {
        GeneratedSFXRecipe(
            intro: [
                GeneratedSFXSegment(
                    waveform: .sine,
                    frequency: .constant(523.251),
                    duration: 0.026,
                    amplitude: 0.2,
                    attack: 0.001,
                    decay: 0.012
                )
            ],
            body: [
                GeneratedSFXSegment(
                    waveform: .sine,
                    frequency: .constant(659.255),
                    duration: 0.026,
                    amplitude: 0.18,
                    attack: 0.001,
                    decay: 0.012
                ),
                GeneratedSFXSegment(
                    waveform: .sine,
                    frequency: .constant(783.991),
                    duration: 0.026,
                    amplitude: 0.17,
                    attack: 0.001,
                    decay: 0.012
                )
            ]
        )
    }

    private static func makeFailRecipe(failTailRepeatCount: Int) -> GeneratedSFXRecipe {
        let intro = [
            GeneratedSFXSegment(
                waveform: .square,
                frequency: .constant(330),
                duration: 0.12,
                amplitude: 0.24,
                attack: 0.002,
                decay: 0.018
            ),
            GeneratedSFXSegment(
                waveform: .square,
                frequency: .constant(277.18),
                duration: 0.12,
                amplitude: 0.24,
                attack: 0.002,
                decay: 0.02
            )
        ]

        let downturn = [
            GeneratedSFXSegment(
                waveform: .triangle,
                frequency: .linear(startHz: 260, endHz: 220),
                duration: 0.15,
                amplitude: 0.22,
                attack: 0.002,
                decay: 0.02
            ),
            GeneratedSFXSegment(
                waveform: .triangle,
                frequency: .linear(startHz: 220, endHz: 185),
                duration: 0.15,
                amplitude: 0.22,
                attack: 0.002,
                decay: 0.02
            ),
            GeneratedSFXSegment(
                waveform: .triangle,
                frequency: .linear(startHz: 185, endHz: 155),
                duration: 0.16,
                amplitude: 0.21,
                attack: 0.002,
                decay: 0.022
            ),
            GeneratedSFXSegment(
                waveform: .triangle,
                frequency: .linear(startHz: 155, endHz: 130),
                duration: 0.16,
                amplitude: 0.2,
                attack: 0.002,
                decay: 0.022
            )
        ]

        let tailMotif = [
            GeneratedSFXSegment(
                waveform: .triangle,
                frequency: .linear(startHz: 130, endHz: 118),
                duration: 0.18,
                amplitude: 0.18,
                attack: 0.002,
                decay: 0.028
            ),
            GeneratedSFXSegment(
                waveform: .triangle,
                frequency: .linear(startHz: 118, endHz: 104),
                duration: 0.16,
                amplitude: 0.16,
                attack: 0.002,
                decay: 0.03
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
