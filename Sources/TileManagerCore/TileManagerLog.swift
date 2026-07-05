import Foundation
import os

enum TileManagerLog {
    private static let logger = Logger(subsystem: "com.local.TileManager", category: "TileManager")
    private static let fileURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/TileManager.log")

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        appendToFile("INFO", message)
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
        appendToFile("ERROR", message)
    }

    private static func appendToFile(_ level: String, _ message: String) {
        let line = "\(Date()) [\(level)] \(message)\n"
        guard let data = line.data(using: .utf8) else {
            return
        }

        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }

        guard let handle = try? FileHandle(forWritingTo: fileURL) else {
            return
        }

        defer {
            try? handle.close()
        }

        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            return
        }
    }
}
