import Foundation
import os

/// Feature emojis for log filtering. Concatenate when a log touches multiple features.
/// 🖼️ assets (sprites, textures) · 🔊 sound · 🔤 font · 🌐 localization · 🎨 theme · 🎮 game
public enum AppLog {
    public static let assets = "🖼️"
    public static let sound = "🔊"
    public static let font = "🔤"
    public static let localization = "🌐"
    public static let theme = "🎨"
    public static let game = "🎮"

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.retroracing",
        category: "RetroRacing"
    )

    /// Logs a message with emoji prefix(es) using OSLog. Concatenate for multi-feature: AppLog.assets + AppLog.sound
    public static func log(_ emoji: String, _ message: String, file: String = #file, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        logger.info("\(emoji) [\(filename):\(line)] \(message)")
    }

    /// Logs at default level (info). Use for success/flow.
    public static func info(_ emoji: String, _ message: String, file: String = #file, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        logger.info("\(emoji) [\(filename):\(line)] \(message)")
    }

    /// Logs at error level. Use for failures (e.g. asset not found).
    public static func error(_ emoji: String, _ message: String, file: String = #file, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        logger.error("\(emoji) [\(filename):\(line)] \(message)")
    }
}
