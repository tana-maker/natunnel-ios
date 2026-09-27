//
//  ProxyProtocol.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public enum ProxyProtocol: String, Codable, CaseIterable, Identifiable {
    case vless = "VLESS"
    case hysteria2 = "HYSTERIA2"
    case trojan = "TROJAN"
    case shadowsocks = "SHADOWSOCKS"
    case vmess = "VMESS"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vless:
            return "VLESS"
        case .hysteria2:
            return "Hysteria 2"
        case .trojan:
            return "Trojan"
        case .shadowsocks:
            return "Shadowsocks"
        case .vmess:
            return "VMess"
        }
    }

    public var badgeColorHex: String {
        switch self {
        case .vless:
            return "#4ADE80" // Neon Mint
        case .hysteria2:
            return "#F59E0B" // Neon Amber / Fast UDP
        case .trojan:
            return "#38BDF8" // Sky Blue
        case .shadowsocks:
            return "#A855F7" // Purple
        case .vmess:
            return "#EC4899" // Pink
        }
    }

    public var defaultPort: Int {
        switch self {
        case .vless, .hysteria2, .trojan:
            return 443
        case .shadowsocks:
            return 8388
        case .vmess:
            return 443
        }
    }
}
