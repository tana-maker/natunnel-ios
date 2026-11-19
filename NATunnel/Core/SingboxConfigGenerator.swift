//
//  SingboxConfigGenerator.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public final class SingboxConfigGenerator {

    public static func generate(config: VpnConfig, settings: UserSettings) -> String? {
        var root: [String: Any] = [:]

        // 1. Log configuration
        root["log"] = [
            "level": settings.logLevel.lowercased(),
            "timestamp": true
        ]

        // 2. DNS configuration
        let dohUrl = settings.dnsProvider.dohUrl.isEmpty ? "https://1.1.1.1/dns-query" : settings.dnsProvider.dohUrl
        root["dns"] = [
            "servers": [
                [
                    "tag": "dns-remote",
                    "address": dohUrl,
                    "detour": "proxy"
                ],
                [
                    "tag": "dns-direct",
                    "address": "local",
                    "detour": "direct"
                ]
            ],
            "rules": [
                [
                    "outbound": ["any"],
                    "server": "dns-remote"
                ]
            ],
            "strategy": "prefer_ipv4",
            "independent_cache": true
        ]

        // 3. Inbounds: TUN interface for iOS NetworkExtension
        let tunInbound: [String: Any] = [
            "type": "tun",
            "tag": "tun-in",
            "inet4_address": "172.19.0.1/30",
            "auto_route": true,
            "strict_route": true,
            "mtu": settings.mtu,
            "sniff": true,
            "platform": [
                "http_proxy": [
                    "enabled": true,
                    "server": "127.0.0.1",
                    "server_port": 2080
                ]
            ]
        ]
        root["inbounds"] = [tunInbound]

        // 4. Outbounds: Main Proxy + Direct + Block + DNS
        guard let proxyOutbound = buildProxyOutbound(config: config) else {
            return nil
        }

        let directOutbound: [String: Any] = [
            "type": "direct",
            "tag": "direct"
        ]

        let blockOutbound: [String: Any] = [
            "type": "block",
            "tag": "block"
        ]

        let dnsOutbound: [String: Any] = [
            "type": "dns",
            "tag": "dns-out"
        ]

        root["outbounds"] = [proxyOutbound, directOutbound, blockOutbound, dnsOutbound]

        // 5. Routing rules
        var routeRules: [[String: Any]] = [
            [
                "protocol": "dns",
                "outbound": "dns-out"
            ]
        ]

        if settings.routingMode == .bypassLan {
            routeRules.append([
                "ip_is_private": true,
                "outbound": "direct"
            ])
        } else if settings.routingMode == .bypassCambodia {
            routeRules.append([
                "ip_is_private": true,
                "outbound": "direct"
            ])
            routeRules.append([
                "geoip": ["kh"],
                "outbound": "direct"
            ])
            routeRules.append([
                "geosite": ["kh"],
                "outbound": "direct"
            ])
        }

        // Default route to proxy
        routeRules.append([
            "outbound": "proxy"
        ])

        root["route"] = [
            "rules": routeRules,
            "auto_detect_interface": true
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: root, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }

    private static func buildProxyOutbound(config: VpnConfig) -> [String: Any]? {
        var outbound: [String: Any] = [
            "tag": "proxy"
        ]

        switch config.protocolType {
        case .vless:
            outbound["type"] = "vless"
            outbound["server"] = config.server
            outbound["server_port"] = config.port
            outbound["uuid"] = config.uuid
            if !config.flow.isEmpty {
                outbound["flow"] = config.flow
            }

            // Transport (WebSocket Clean IP bypass support)
            if config.network.lowercased() == "ws" {
                var wsDict: [String: Any] = [
                    "type": "ws",
                    "path": config.path.isEmpty ? "/" : config.path
                ]
                let hostHeader = config.host.isEmpty ? config.sni : config.host
                if !hostHeader.isEmpty {
                    wsDict["headers"] = ["Host": hostHeader]
                }
                outbound["transport"] = wsDict
            }

            // Security & TLS / Reality
            if config.security.lowercased() == "reality" {
                var realityDict: [String: Any] = [
                    "enabled": true,
                    "public_key": config.publicKey
                ]
                if !config.shortId.isEmpty {
                    realityDict["short_id"] = config.shortId
                }

                var tlsDict: [String: Any] = [
                    "enabled": true,
                    "server_name": config.sni.isEmpty ? config.server : config.sni,
                    "reality": realityDict
                ]
                let fp = config.fingerprint.isEmpty ? "chrome" : config.fingerprint
                tlsDict["utls"] = [
                    "enabled": true,
                    "fingerprint": fp
                ]
                outbound["tls"] = tlsDict
            } else if config.security.lowercased() == "tls" {
                var tlsDict: [String: Any] = [
                    "enabled": true,
                    "server_name": config.sni.isEmpty ? config.server : config.sni,
                    "insecure": config.allowInsecure
                ]
                if !config.alpn.isEmpty {
                    tlsDict["alpn"] = config.alpn.components(separatedBy: ",")
                }
                outbound["tls"] = tlsDict
            }

        case .hysteria2:
            outbound["type"] = "hysteria2"
            outbound["server"] = config.server
            outbound["server_port"] = config.port
            outbound["password"] = config.password

            var tlsDict: [String: Any] = [
                "enabled": true,
                "server_name": config.sni.isEmpty ? config.server : config.sni,
                "insecure": config.allowInsecure
            ]
            if !config.alpn.isEmpty {
                tlsDict["alpn"] = config.alpn.components(separatedBy: ",")
            }
            outbound["tls"] = tlsDict

            if !config.obfsType.isEmpty && !config.obfsPassword.isEmpty {
                outbound["obfs"] = [
                    "type": config.obfsType,
                    "password": config.obfsPassword
                ]
            }

        case .trojan:
            outbound["type"] = "trojan"
            outbound["server"] = config.server
            outbound["server_port"] = config.port
            outbound["password"] = config.password

            if config.network.lowercased() == "ws" {
                var wsDict: [String: Any] = [
                    "type": "ws",
                    "path": config.path.isEmpty ? "/" : config.path
                ]
                let hostHeader = config.host.isEmpty ? config.sni : config.host
                if !hostHeader.isEmpty {
                    wsDict["headers"] = ["Host": hostHeader]
                }
                outbound["transport"] = wsDict
            }

            outbound["tls"] = [
                "enabled": true,
                "server_name": config.sni.isEmpty ? config.server : config.sni,
                "insecure": config.allowInsecure
            ]

        case .shadowsocks:
            outbound["type"] = "shadowsocks"
            outbound["server"] = config.server
            outbound["server_port"] = config.port
            outbound["method"] = config.method.isEmpty ? "aes-256-gcm" : config.method
            outbound["password"] = config.password

        case .vmess:
            outbound["type"] = "vmess"
            outbound["server"] = config.server
            outbound["server_port"] = config.port
            outbound["uuid"] = config.uuid
            outbound["security"] = config.method.isEmpty ? "auto" : config.method

            if config.network.lowercased() == "ws" {
                var wsDict: [String: Any] = [
                    "type": "ws",
                    "path": config.path.isEmpty ? "/" : config.path
                ]
                let hostHeader = config.host.isEmpty ? config.sni : config.host
                if !hostHeader.isEmpty {
                    wsDict["headers"] = ["Host": hostHeader]
                }
                outbound["transport"] = wsDict
            }

            if config.security.lowercased() == "tls" {
                outbound["tls"] = [
                    "enabled": true,
                    "server_name": config.sni.isEmpty ? config.server : config.sni
                ]
            }
        }

        // Performance & Low Latency optimizations
        // Note: tcp_fast_open is disabled on cellular to prevent carrier DPI drops on SYN data
        outbound["tcp_fast_open"] = false
        outbound["tcp_multi_path"] = true
        outbound["connect_timeout"] = "5s"

        return outbound
    }
}
