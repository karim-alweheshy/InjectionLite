//
//  UnifiedLogger.swift
//  InjectionLite
//
//  Enhanced logging system for Console.app and InjectionNext app UI
//

import Foundation
import os.log
#if canImport(InjectionImplC)
import InjectionImplC
#endif

public enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO" 
    case warning = "WARNING"
    case error = "ERROR"
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "🔥"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

public class UnifiedLogger {
    public static let shared = UnifiedLogger()
    
    // os_log for Console.app visibility
    private let osLog = OSLog(subsystem: "com.johnholdsworth.InjectionNext", category: "InjectionLite")
    
    // Log storage for InjectionNext app UI
    public private(set) var logEntries: [LogEntry] = []
    private let logQueue = DispatchQueue(label: "unified.logger.queue", qos: .utility)
    private let maxLogEntries = 10000 // Prevent unlimited memory growth
    
    // Notification for real-time log updates
    public static let logUpdatedNotification = Notification.Name("UnifiedLogger.LogUpdated")
    
    public struct LogEntry {
        public let timestamp: Date
        public let level: LogLevel
        public let message: String
        public let file: String
        public let function: String
        public let line: Int
        
        public var formattedMessage: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            let timeString = formatter.string(from: timestamp)
            let fileName = (file as NSString).lastPathComponent
            return "\(timeString) \(level.emoji) [\(level.rawValue)] \(fileName):\(line) \(function) - \(message)"
        }
    }
    
    private init() {}
    
    public func log(
        level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let messageString = message()
        
        // Log to os_log for Console.app
        os_log("%{public}@", log: osLog, type: level.osLogType, messageString)
        
        // Store for InjectionNext app UI
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let entry = LogEntry(
                timestamp: Date(),
                level: level,
                message: messageString,
                file: file,
                function: function,
                line: line
            )
            
            self.logEntries.append(entry)
            
            // Trim old entries to prevent memory issues
            if self.logEntries.count > self.maxLogEntries {
                self.logEntries.removeFirst(self.logEntries.count - self.maxLogEntries)
            }
            
            // Notify UI on main thread
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Self.logUpdatedNotification,
                    object: entry
                )
            }
        }
        
        // Also maintain backward compatibility with existing console output
        print("\(level.emoji) \(messageString)")
    }
    
    // Convenience methods
    public func debug(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message(), file: file, function: function, line: line)
    }
    
    public func info(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message(), file: file, function: function, line: line)
    }
    
    public func warning(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message(), file: file, function: function, line: line)
    }
    
    public func error(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message(), file: file, function: function, line: line)
    }
    
    // Get logs filtered by level
    public func getLogs(minimumLevel: LogLevel? = nil) -> [LogEntry] {
        return logQueue.sync {
            guard let minLevel = minimumLevel else { return logEntries }
            
            let levelPriority: [LogLevel: Int] = [.debug: 0, .info: 1, .warning: 2, .error: 3]
            let minPriority = levelPriority[minLevel] ?? 0
            
            return logEntries.filter { entry in
                (levelPriority[entry.level] ?? 0) >= minPriority
            }
        }
    }
    
    // Clear log history
    public func clearLogs() {
        logQueue.async { [weak self] in
            self?.logEntries.removeAll()
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Self.logUpdatedNotification,
                    object: nil
                )
            }
        }
    }
    
    // Export logs to string
    public func exportLogs() -> String {
        return logQueue.sync {
            return logEntries.map { $0.formattedMessage }.joined(separator: "\n")
        }
    }
}

// MARK: - Global convenience functions for backward compatibility

/// Enhanced log function with level support
public func log(
    level: LogLevel = .info,
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    UnifiedLogger.shared.log(level: level, message(), file: file, function: function, line: line)
}

/// Backward compatible log function
public func log(
    _ what: Any...,
    prefix: String = APP_PREFIX,
    separator: String = " ",
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    let message = what.map { "\($0)" }.joined(separator: separator)
    UnifiedLogger.shared.info(message, file: file, function: function, line: line)
}