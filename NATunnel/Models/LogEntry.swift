//
//  LogEntry.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public enum LogLevel: String, Codable, CaseIterable, Identifiable {
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"

    public var id: String { rawValue }

    public var colorHex: String {
        switch self {
        case .debug:
            return "#64748B" // Slate
        case .info:
            return "#10B981" // Emerald
        case .warn:
            return "#EA580C" // Orange
        case .error:
            return "#EF4444" // Red
        }
    }
}

public struct LogEntry: Identifiable, Codable {
    public var id: String
    public var timestamp: Date
    public var level: LogLevel
    public var message: String

    public init(id: String = UUID().uuidString, timestamp: Date = Date(), level: LogLevel = .info, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}
