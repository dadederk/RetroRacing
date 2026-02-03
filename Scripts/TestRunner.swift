import Foundation

struct CommandError: Error {
    let code: Int32
}

@discardableResult
func run(_ arguments: [String]) throws {
    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = arguments
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError
    process.launch()
    process.waitUntilExit()
    if process.terminationStatus != 0 {
        throw CommandError(code: process.terminationStatus)
    }
}

let projectRoot = FileManager.default.currentDirectoryPath
let destination = "platform=iOS Simulator,name=iPhone 17 Pro"

do {
    print("Running RetroRacingSharedTests…")
    try run(["xcodebuild", "-project", "\(projectRoot)/RetroRacing/RetroRacing.xcodeproj", "-scheme", "RetroRacingSharedTests", "-destination", destination, "test"])

    print("Running RetroRacingUniversalTests…")
    try run(["xcodebuild", "-project", "\(projectRoot)/RetroRacing/RetroRacing.xcodeproj", "-scheme", "RetroRacingUniversalTests", "-destination", destination, "test"])
} catch {
    fputs("Test runner failed: \(error)\n", stderr)
    exit(1)
}
