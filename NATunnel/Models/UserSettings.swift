//
//  UserSettings.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public enum DnsProvider: String, Codable, CaseIterable, Identifiable {
    case cloudflare = "Cloudflare (1.1.1.1 DoH)"
    case google = "Google (8.8.8.8 DoH)"
    case direct = "Local Direct DNS"
    case custom = "Custom DoH"

    public var id: String { rawValue }

    public var dohUrl: String {
        switch self {
        case .cloudflare:
            return "https://1.1.1.1/dns-query"
        case .google:
            return "https://dns.google/dns-query"
        case .direct:
            return "local"
        case .custom:
            return ""
        }
    }
}

public enum RoutingMode: String, Codable, CaseIterable, Identifiable {
    case global = "Global VPN (Proxy All)"
    case bypassLan = "Bypass Local Network (LAN)"
    case bypassCambodia = "Bypass Cambodia Local IPs"
    case direct = "Direct Only"

    public var id: String { rawValue }
}

public struct UserSettings: Codable, Equatable {
    public var enableSmartConnect: Bool
    public var enableGameMode: Bool
    public var dnsProvider: DnsProvider
    public var customDnsUrl: String
    public var routingMode: RoutingMode
    public var mtu: Int
    public var autoConnectOnLaunch: Bool
    public var logLevel: String
    public var autoUpdateSubscriptions: Bool
    public var subscriptionUpdateIntervalHours: Int

    public init(
        enableSmartConnect: Bool = false,
        enableGameMode: Bool = false,
        dnsProvider: DnsProvider = .cloudflare,
        customDnsUrl: String = "",
        routingMode: RoutingMode = .bypassLan,
        mtu: Int = 1500,
        autoConnectOnLaunch: Bool = false,
        logLevel: String = "info",
        autoUpdateSubscriptions: Bool = true,
        subscriptionUpdateIntervalHours: Int = 24
    ) {
        self.enableSmartConnect = enableSmartConnect
        self.enableGameMode = enableGameMode
        self.dnsProvider = dnsProvider
        self.customDnsUrl = customDnsUrl
        self.routingMode = routingMode
        self.mtu = mtu
        self.autoConnectOnLaunch = autoConnectOnLaunch
        self.logLevel = logLevel
        self.autoUpdateSubscriptions = autoUpdateSubscriptions
        self.subscriptionUpdateIntervalHours = subscriptionUpdateIntervalHours
    }

    public static let `default` = UserSettings()
}
