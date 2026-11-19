//
//  NATunnelActivityAttributes.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

public struct NATunnelActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var status: String
        public var downloadSpeed: String
        public var uploadSpeed: String
        public var totalData: String
        public var duration: String
        public var serverName: String
        public var pingMs: Int64

        public init(
            status: String = "CONNECTED",
            downloadSpeed: String = "0 Kbps",
            uploadSpeed: String = "0 Kbps",
            totalData: String = "0 MB",
            duration: String = "00:00:00",
            serverName: String = "",
            pingMs: Int64 = 0
        ) {
            self.status = status
            self.downloadSpeed = downloadSpeed
            self.uploadSpeed = uploadSpeed
            self.totalData = totalData
            self.duration = duration
            self.serverName = serverName
            self.pingMs = pingMs
        }
    }

    public var serverName: String
    public var protocolName: String
    public var flag: String

    public init(serverName: String, protocolName: String, flag: String) {
        self.serverName = serverName
        self.protocolName = protocolName
        self.flag = flag
    }
}
#endif
