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
}
