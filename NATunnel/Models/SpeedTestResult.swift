//
//  SpeedTestResult.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public struct SpeedTestResult: Codable, Identifiable {
    public var id: String
    public var downloadMbps: Double
    public var uploadMbps: Double
    public var pingMs: Double
    public var jitterMs: Double
    public var serverName: String
    public var timestamp: Date

    public init(
        id: String = UUID().uuidString,
        downloadMbps: Double = 0.0,
        uploadMbps: Double = 0.0,
        pingMs: Double = 0.0,
        jitterMs: Double = 0.0,
        serverName: String = "",
        timestamp: Date = Date()
    ) {
        self.id = id
        self.downloadMbps = downloadMbps
        self.uploadMbps = uploadMbps
        self.pingMs = pingMs
        self.jitterMs = jitterMs
        self.serverName = serverName
        self.timestamp = timestamp
    }
}
