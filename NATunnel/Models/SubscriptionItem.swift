//
//  SubscriptionItem.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public struct SubscriptionItem: Codable, Identifiable, Hashable {
    public var id: String
    public var name: String
    public var url: String
    public var lastUpdated: Date?
    public var serverCount: Int
    public var autoUpdate: Bool
    public var uploadBytes: Int64
    public var downloadBytes: Int64
    public var totalBytes: Int64
    public var expireTimestamp: Int64

    public init(
        id: String = UUID().uuidString,
        name: String,
        url: String,
        lastUpdated: Date? = nil,
        serverCount: Int = 0,
        autoUpdate: Bool = true,
        uploadBytes: Int64 = 0,
        downloadBytes: Int64 = 0,
        totalBytes: Int64 = 0,
        expireTimestamp: Int64 = 0
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.lastUpdated = lastUpdated
        self.serverCount = serverCount
        self.autoUpdate = autoUpdate
        self.uploadBytes = uploadBytes
        self.downloadBytes = downloadBytes
        self.totalBytes = totalBytes
        self.expireTimestamp = expireTimestamp
    }

    public var formattedLastUpdated: String {
        guard let date = lastUpdated else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    public var usedBytes: Int64 {
        return max(0, uploadBytes + downloadBytes)
    }

    public var remainingBytes: Int64 {
        guard totalBytes > 0 else { return 0 }
        return max(0, totalBytes - usedBytes)
    }

    public var hasTrafficQuota: Bool {
        return totalBytes > 0
    }

    public var hasExpiry: Bool {
        return expireTimestamp > 0
    }

    public var isExpired: Bool {
        guard let exp = expiryDate else { return false }
        return exp <= Date()
    }

    public var formattedUsedTraffic: String {
        return ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .binary)
    }

    public var formattedTotalTraffic: String {
        guard totalBytes > 0 else { return "Unlimited" }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .binary)
    }

    public var formattedRemainingTraffic: String {
        guard totalBytes > 0 else { return "Unlimited" }
        return ByteCountFormatter.string(fromByteCount: remainingBytes, countStyle: .binary)
    }

    public var trafficProgress: Double {
        guard totalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(usedBytes) / Double(totalBytes)))
    }

    public var expiryDate: Date? {
        guard expireTimestamp > 0 else { return nil }
        let seconds = expireTimestamp > 100_000_000_000 ? expireTimestamp / 1000 : expireTimestamp
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }

    public var formattedExpiry: String {
        guard let exp = expiryDate else { return "No Expiry" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: exp).day ?? 0
        if days < 0 {
            return "Expired"
        } else if days == 0 {
            return "<1d left"
        } else {
            return "\(days)d left"
        }
    }
}
