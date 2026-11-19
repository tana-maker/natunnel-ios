//
//  VpnConfig.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public struct VpnConfig: Codable, Identifiable, Hashable, Equatable {
    public var id: String
    public var name: String
    public var protocolType: ProxyProtocol
    public var server: String
    public var port: Int
    public var uuid: String
    public var password: String
    public var method: String
    public var network: String
    public var security: String
    public var sni: String
    public var host: String
    public var path: String
    public var flow: String
    public var fingerprint: String
    public var alpn: String
    public var publicKey: String
    public var shortId: String
    public var isLocked: BooleanWrapper
    public var lockNote: String
    public var pingMs: Int64
    public var isActive: Bool
    public var createdAt: Int64
    public var allowInsecure: Bool
    public var obfsType: String
    public var obfsPassword: String
    public var portHop: String
    public var subscriptionId: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        protocolType: ProxyProtocol,
        server: String,
        port: Int,
        uuid: String = "",
        password: String = "",
        method: String = "auto",
        network: String = "tcp",
        security: String = "tls",
        sni: String = "",
        host: String = "",
        path: String = "/",
        flow: String = "",
        fingerprint: String = "",
        alpn: String = "",
        publicKey: String = "",
        shortId: String = "",
        isLocked: Bool = false,
        lockNote: String = "",
        pingMs: Int64 = 0,
        isActive: Bool = false,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        allowInsecure: Bool = false,
        obfsType: String = "",
        obfsPassword: String = "",
        portHop: String = "",
        subscriptionId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.protocolType = protocolType
        self.server = server
        self.port = port
        self.uuid = uuid
        self.password = password
        self.method = method
        self.network = network
        self.security = security
        self.sni = sni
        self.host = host
        self.path = path
        self.flow = flow
        self.fingerprint = fingerprint
        self.alpn = alpn
        self.publicKey = publicKey
        self.shortId = shortId
        self.isLocked = BooleanWrapper(isLocked)
        self.lockNote = lockNote
        self.pingMs = pingMs
        self.isActive = isActive
        self.createdAt = createdAt
        self.allowInsecure = allowInsecure
        self.obfsType = obfsType
        self.obfsPassword = obfsPassword
        self.portHop = portHop
        self.subscriptionId = subscriptionId
    }

    enum CodingKeys: String, CodingKey {
        case id, name, server, port, uuid, password, method, network, security, sni, host, path, flow
        case fingerprint, alpn, publicKey, shortId, lockNote, pingMs, isActive, createdAt
        case allowInsecure, obfsType, obfsPassword, portHop, subscriptionId
        case protocolType = "protocol"
        case isLocked
    }

    /// Extracts emoji flag or fallback country code from name or server
    public var flagEmoji: String {
        let nameLower = name.lowercased()
        if name.contains("🇰🇭") || nameLower.contains("cambodia") || nameLower.contains("metfone") || nameLower.contains("smart") || nameLower.contains("cellcard") {
            return "🇰🇭"
        }
        if name.contains("🇸🇬") || nameLower.contains("singapore") || nameLower.contains("sg") {
            return "🇸🇬"
        }
        if name.contains("🇯🇵") || nameLower.contains("japan") || nameLower.contains("jp") || nameLower.contains("tokyo") {
            return "🇯🇵"
        }
        if name.contains("🇺🇸") || nameLower.contains("united states") || nameLower.contains("usa") || nameLower.contains("us") {
            return "🇺🇸"
        }
        if name.contains("🇭🇰") || nameLower.contains("hong kong") || nameLower.contains("hk") {
            return "🇭🇰"
        }
        if name.contains("🇹🇼") || nameLower.contains("taiwan") || nameLower.contains("tw") {
            return "🇹🇼"
        }
        if name.contains("🇩🇪") || nameLower.contains("germany") || nameLower.contains("de") {
            return "🇩🇪"
        }
        return "🌐"
    }

    /// Masks the middle portion of a server domain or IP address for privacy in the UI list.
    /// Examples:
    ///   "na-metfone-free.theworkpc.com" -> "na-m****.com"
    ///   "na-metfone.duckdns.org"        -> "na-m****.org"
    ///   "172.64.151.167"                -> "172.****.167"
    public static func maskServerAddress(_ server: String) -> String {
        let clean = server.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty { return "" }

        // Handle host:port if single colon (not IPv6)
        let colonCount = clean.filter { $0 == ":" }.count
        if colonCount == 1 && !clean.hasPrefix("[") {
            let parts = clean.split(separator: ":", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                return "\(maskServerAddress(parts[0])):\(parts[1])"
            }
        }

        // IPv6
        if colonCount >= 2 {
            let colonParts = clean.split(separator: ":").map(String.init)
            if let first = colonParts.first, let last = colonParts.last {
                return "\(first)::****:\(last)"
            }
        }

        let parts = clean.split(separator: ".").map(String.init)
        // IPv4 check: 4 numeric octets
        if parts.count == 4 && parts.allSatisfy({ Int($0) != nil && (0...255).contains(Int($0)!) }) {
            return "\(parts[0]).****.\(parts[3])"
        }

        // Domain with TLD (at least one dot)
        if parts.count >= 2, let lastDotIndex = clean.lastIndex(of: ".") {
            let name = String(clean[..<lastDotIndex])
            let tld = String(clean[clean.index(after: lastDotIndex)...])
            let prefix: String
            if name.count >= 4 {
                prefix = String(name.prefix(4))
            } else if name.count > 2 {
                prefix = String(name.prefix(2))
            } else {
                prefix = name
            }
            return "\(prefix)****.\(tld)"
        }

        if clean.count > 4 {
            return "\(clean.prefix(2))****\(clean.suffix(2))"
        }
        return clean
    }

    public var maskedServer: String {
        return VpnConfig.maskServerAddress(server)
    }

    /// Clean display description with privacy-masked endpoint
    public var routingDescription: String {
        if isLocked.value {
            return "Protected · Encrypted"
        }
        let masked = maskedServer
        if port == 80 && (security.isEmpty || security.lowercased() == "none") {
            if !host.isEmpty {
                return "Zero-Rated Carrier Bypass (Host: \(VpnConfig.maskServerAddress(host)))"
            }
            return "\(masked):80"
        }
        if security.lowercased() == "reality" {
            let targetSni = sni.isEmpty ? server : sni
            return "VLESS Reality (SNI: \(VpnConfig.maskServerAddress(targetSni)))"
        }
        if protocolType == .hysteria2 {
            return "QUIC High-Speed UDP · \(masked)"
        }
        if !sni.isEmpty {
            return "TLS (SNI: \(VpnConfig.maskServerAddress(sni)))"
        }
        return "\(masked):\(port)"
    }
}

/// Helper to parse both boolean and string representations of boolean in JSON
public struct BooleanWrapper: Codable, Hashable, Equatable {
    public var value: Bool

    public init(_ value: Bool) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolVal = try? container.decode(Bool.self) {
            self.value = boolVal
        } else if let strVal = try? container.decode(String.self) {
            self.value = (strVal.lowercased() == "true" || strVal == "1")
        } else if let intVal = try? container.decode(Int.self) {
            self.value = (intVal != 0)
        } else {
            self.value = false
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
