import Foundation

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case error = "ERROR"
}

struct AppLog {
    // Toggle this to enable/disable verbose debug logging
    static var isVerbose: Bool = false

    static func debug(_ message: @autoclosure () -> String) {
        guard isVerbose else { return }
        print("🟦 [DEBUG] \(message())")
    }

    static func info(_ message: @autoclosure () -> String) {
        print("🟩 [INFO] \(message())")
    }

    static func error(_ message: @autoclosure () -> String) {
        print("🟥 [ERROR] \(message())")
    }
}
