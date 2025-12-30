//
//  LoggingService.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Logging levels for categorizing messages
enum LogLevel: String, Codable, CaseIterable, Comparable {
    case debug
    case info
    case warning
    case error
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.priority < rhs.priority
    }
}

/// A single log entry
struct LogEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String
    let context: [String: String]?
    let file: String
    let function: String
    let line: Int
    
    init(
        level: LogLevel,
        category: String,
        message: String,
        context: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.level = level
        self.category = category
        self.message = message
        self.context = context
        self.file = (file as NSString).lastPathComponent
        self.function = function
        self.line = line
    }
}

/// Service for logging and telemetry
actor LoggingService {
    
    // MARK: - Singleton
    
    static let shared = LoggingService()
    
    // MARK: - Configuration
    
    private var minimumLogLevel: LogLevel = .debug
    private var maxLogEntries: Int = 1000
    private var logToDisk: Bool = true
    
    // MARK: - Storage
    
    private var logEntries: [LogEntry] = []
    private let logFileURL: URL?
    
    // MARK: - Initialization
    
    init() {
        // Set up log file
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let bundleId = Bundle.main.bundleIdentifier ?? "SecureDesk"
            let logDir = appSupport.appendingPathComponent(bundleId).appendingPathComponent("Logs")
            
            try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let fileName = "securedesk_\(dateFormatter.string(from: Date())).log"
            
            self.logFileURL = logDir.appendingPathComponent(fileName)
        } else {
            self.logFileURL = nil
        }
    }
    
    // MARK: - Logging Methods
    
    func debug(_ message: String, category: String = "General", context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message: message, category: category, context: context, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "General", context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message: message, category: category, context: context, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "General", context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message: message, category: category, context: context, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: String = "General", context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message: message, category: category, context: context, file: file, function: function, line: line)
    }
    
    func error(_ error: Error, category: String = "General", context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var ctx = context ?? [:]
        ctx["error_type"] = String(describing: type(of: error))
        log(.error, message: error.localizedDescription, category: category, context: ctx, file: file, function: function, line: line)
    }
    
    // MARK: - Core Logging
    
    private func log(_ level: LogLevel, message: String, category: String, context: [String: String]?, file: String, function: String, line: Int) {
        guard level >= minimumLogLevel else { return }
        
        let entry = LogEntry(
            level: level,
            category: category,
            message: message,
            context: context,
            file: file,
            function: function,
            line: line
        )
        
        // Add to memory
        logEntries.append(entry)
        
        // Trim if needed
        if logEntries.count > maxLogEntries {
            logEntries.removeFirst(logEntries.count - maxLogEntries)
        }
        
        // Console output (always print in debug mode)
        #if DEBUG
        printToConsole(entry)
        #endif
        
        // Disk output
        if logToDisk {
            writeToDisk(entry)
        }
    }
    
    private func printToConsole(_ entry: LogEntry) {
        let timestamp = formatTimestamp(entry.timestamp)
        print("\(entry.level.emoji) [\(timestamp)] [\(entry.category)] \(entry.message)")
    }
    
    private func writeToDisk(_ entry: LogEntry) {
        guard let url = logFileURL else { return }
        
        let line = formatLogLine(entry)
        
        if let data = (line + "\n").data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path) {
                if let handle = try? FileHandle(forWritingTo: url) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: url)
            }
        }
    }
    
    // MARK: - Retrieval
    
    func getEntries(level: LogLevel? = nil, category: String? = nil, limit: Int = 100) -> [LogEntry] {
        var filtered = logEntries
        
        if let level = level {
            filtered = filtered.filter { $0.level >= level }
        }
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        return Array(filtered.suffix(limit))
    }
    
    func getErrorEntries(limit: Int = 50) -> [LogEntry] {
        getEntries(level: .error, limit: limit)
    }
    
    func exportLogs() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return (try? encoder.encode(logEntries)) ?? Data()
    }
    
    func clearLogs() {
        logEntries.removeAll()
        
        // Clear disk logs
        if let url = logFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    // MARK: - Configuration
    
    func setMinimumLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
    }
    
    func setLogToDisk(_ enabled: Bool) {
        logToDisk = enabled
    }
    
    // MARK: - Formatting
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    private func formatLogLine(_ entry: LogEntry) -> String {
        let timestamp = ISO8601DateFormatter().string(from: entry.timestamp)
        return "[\(timestamp)] [\(entry.level.rawValue.uppercased())] [\(entry.category)] \(entry.message) (\(entry.file):\(entry.line))"
    }
}

// MARK: - Convenience Global Functions

func logDebug(_ message: String, category: String = "General", context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await LoggingService.shared.debug(message, category: category, context: context, file: file, function: function, line: line)
    }
}

func logInfo(_ message: String, category: String = "General", context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await LoggingService.shared.info(message, category: category, context: context, file: file, function: function, line: line)
    }
}

func logWarning(_ message: String, category: String = "General", context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await LoggingService.shared.warning(message, category: category, context: context, file: file, function: function, line: line)
    }
}

func logError(_ message: String, category: String = "General", context: [String: String]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    Task {
        await LoggingService.shared.error(message, category: category, context: context, file: file, function: function, line: line)
    }
}
