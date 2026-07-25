//
//  WatchSimulatorClockWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation
import ScriptSupport

public enum WatchSimulatorClockError: LocalizedError {
    case systemClockChangeRequiresAdmin(String)

    public var errorDescription: String? {
        switch self {
        case let .systemClockChangeRequiresAdmin(message):
            return message
        }
    }
}

/// Sets Apple Watch simulator marketing time (10:09) by adjusting the host system clock.
/// watchOS simulators do not support `simctl status_bar override`.
public enum WatchSimulatorClockWorkflow {
    public static let marketingClockTime = "10:09"
    public static let marketingStatusBarYear = 2027
    public static let marketingStatusBarMonth = 1
    public static let marketingStatusBarDay = 27
    public static let marketingStatusBarHour = 10
    public static let marketingStatusBarMinute = 9

    public struct RestoreToken: Sendable {
        let savedEpoch: String
        let simulatorUDID: String
        let dryRun: Bool
    }

    /// macOS `date` set argument: `MMDDhhmmYYYY` (27 January 2027 10:09).
    public static var macOSDateSetArgument: String {
        String(
            format: "%02d%02d%02d%02d%04d",
            marketingStatusBarMonth,
            marketingStatusBarDay,
            marketingStatusBarHour,
            marketingStatusBarMinute,
            marketingStatusBarYear
        )
    }

    public static func shouldApply(platform: String, enabled: Bool) -> Bool {
        enabled
            && AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) == "appleWatch"
    }

    /// Shell body run with administrator privileges when applying marketing clock.
    public static var applyMarketingClockShellCommand: String {
        "/usr/sbin/systemsetup -setusingnetworktime off && /bin/date \(macOSDateSetArgument)"
    }

    public static func restoreMarketingClockShellCommand(savedEpoch: String) -> String {
        "/bin/date -r \(savedEpoch) && /usr/sbin/systemsetup -setusingnetworktime on"
    }

    @discardableResult
    public static func applyMarketingClock(
        destination: String,
        dryRun: Bool,
        run: (ProcessCommand) throws -> String = { try ProcessRunner.run($0, captureOutput: true) },
        runVoid: (ProcessCommand) throws -> Void = { try ProcessRunner.run($0) }
    ) throws -> RestoreToken {
        let simulatorReference = try SimulatorStatusBarWorkflow.resolveSimulatorReference(
            from: destination,
            dryRun: dryRun,
            run: runVoid
        )
        if dryRun {
            print(
                "Would set Mac system clock to \(marketingClockTime) " +
                "(2027-01-27) and restart watch simulator \(simulatorReference) " +
                "(watchOS does not support simctl status_bar)."
            )
            print("Would run privileged shell: \(applyMarketingClockShellCommand)")
            return RestoreToken(savedEpoch: "0", simulatorUDID: simulatorReference, dryRun: true)
        }

        let savedEpoch = try run(
            ProcessCommand(executable: "/bin/date", arguments: ["+%s"])
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        print(
            """
            Apple Watch marketing clock (\(marketingClockTime), 2027-01-27) requires temporarily changing \
            the Mac system clock (watchOS does not support simctl status_bar). \
            Approve the macOS authentication dialog when it appears; the clock is restored when capture finishes.
            """
        )

        do {
            try runVoid(
                privilegedShellCommand(applyMarketingClockShellCommand)
            )
        } catch {
            throw WatchSimulatorClockError.systemClockChangeRequiresAdmin(
                "Apple Watch screenshots use marketing time \(marketingClockTime), but watchOS simulators " +
                "do not support simctl status_bar. Temporarily setting the Mac system clock requires administrator " +
                "approval via the macOS authentication dialog. Approve the dialog and re-run, or pass " +
                "--no-status-bar-override to skip.\n" +
                "Underlying error: \(error.localizedDescription)"
            )
        }

        try restartSimulator(udid: simulatorReference, run: runVoid)
        print(
            "Applied Apple Watch marketing clock (\(marketingClockTime), 2027-01-27) " +
            "via host system time on \(simulatorReference)…"
        )

        return RestoreToken(
            savedEpoch: savedEpoch,
            simulatorUDID: simulatorReference,
            dryRun: false
        )
    }

    public static func restoreMarketingClock(
        _ token: RestoreToken,
        run: (ProcessCommand) throws -> String = { try ProcessRunner.run($0, captureOutput: true) },
        runVoid: (ProcessCommand) throws -> Void = { try ProcessRunner.run($0) }
    ) throws {
        guard token.dryRun == false else { return }

        do {
            try runVoid(
                privilegedShellCommand(
                    restoreMarketingClockShellCommand(savedEpoch: token.savedEpoch)
                )
            )
        } catch {
            fputs(
                "Warning: could not restore the Mac system clock after watch capture: " +
                "\(error.localizedDescription)\n",
                stderr
            )
        }

        do {
            try restartSimulator(udid: token.simulatorUDID, run: runVoid)
        } catch {
            fputs(
                "Warning: could not restart the watch simulator after restoring system time: " +
                "\(error.localizedDescription)\n",
                stderr
            )
        }
    }

    /// Builds an `osascript` command that runs `shellCommand` as root after the macOS authentication dialog.
    /// Prefer this over nested `sudo` because `sudo` reads `/dev/tty`, not forwarded stdin, and hangs in IDE terminals.
    static func privilegedShellCommand(_ shellCommand: String) -> ProcessCommand {
        ProcessCommand(
            executable: "/usr/bin/osascript",
            arguments: ["-e", appleScriptSource(for: shellCommand)]
        )
    }

    static func appleScriptSource(for shellCommand: String) -> String {
        let escaped = shellCommand
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "do shell script \"\(escaped)\" with administrator privileges"
    }

    private static func restartSimulator(
        udid: String,
        run: (ProcessCommand) throws -> Void
    ) throws {
        try? run(
            ProcessCommand(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "shutdown", udid]
            )
        )
        try run(
            ProcessCommand(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "boot", udid]
            )
        )
        try run(
            ProcessCommand(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "bootstatus", udid, "-b"]
            )
        )
    }
}
