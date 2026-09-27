//
//  TrafficStats.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public struct TrafficStats: Codable, Equatable {
    public var uplinkSpeedBytesPerSec: Int64
    public var downlinkSpeedBytesPerSec: Int64
    public var totalUplinkBytes: Int64
    public var totalDownlinkBytes: Int64
    public var connectedSince: Date?

    public init(
        uplinkSpeedBytesPerSec: Int64 = 0,
        downlinkSpeedBytesPerSec: Int64 = 0,
        totalUplinkBytes: Int64 = 0,
        totalDownlinkBytes: Int64 = 0,
        connectedSince: Date? = nil
    ) {
        self.uplinkSpeedBytesPerSec = uplinkSpeedBytesPerSec
        self.downlinkSpeedBytesPerSec = downlinkSpeedBytesPerSec
        self.totalUplinkBytes = totalUplinkBytes
        self.totalDownlinkBytes = totalDownlinkBytes
        self.connectedSince = connectedSince
    }

    public var formattedDownloadSpeed: String {
        formatSpeed(downlinkSpeedBytesPerSec)
    }

    public var formattedUploadSpeed: String {
        formatSpeed(uplinkSpeedBytesPerSec)
    }

    public var formattedTotalDownload: String {
        formatBytes(totalDownlinkBytes)
    }

    public var formattedTotalUpload: String {
        formatBytes(totalUplinkBytes)
    }

    public var formattedDuration: String {
        guard let start = connectedSince else { return "00:00:00" }
        let diff = max(0, Int(Date().timeIntervalSince(start)))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func formatSpeed(_ bytesPerSec: Int64) -> String {
        let bitsPerSec = Double(bytesPerSec * 8)
        if bitsPerSec >= 1_000_000_000 {
            return String(format: "%.1f Gbps", bitsPerSec / 1_000_000_000)
        } else if bitsPerSec >= 1_000_000 {
            return String(format: "%.1f Mbps", bitsPerSec / 1_000_000)
        } else if bitsPerSec >= 1_000 {
            return String(format: "%.0f Kbps", bitsPerSec / 1_000)
        } else {
            return "0 Kbps"
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let dBytes = Double(bytes)
        if dBytes >= 1_073_741_824 {
            return String(format: "%.2f GB", dBytes / 1_073_741_824)
        } else if dBytes >= 1_048_576 {
            return String(format: "%.1f MB", dBytes / 1_048_576)
        } else if dBytes >= 1_024 {
            return String(format: "%.0f KB", dBytes / 1_024)
        } else {
            return "\(bytes) B"
        }
    }
}
