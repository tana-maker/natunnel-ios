//
//  V2RayShareLinkParser.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public final class V2RayShareLinkParser {

    private static let ipv4Regex = try? NSRegularExpression(pattern: "^[0-9.]+$")

    public static func parse(link: String) -> VpnConfig? {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("vless://") {
            return parseVless(trimmed)
        } else if trimmed.hasPrefix("hy2://") || trimmed.hasPrefix("hysteria2://") {
            return parseHysteria2(trimmed)
        } else if trimmed.hasPrefix("trojan://") {
            return parseTrojan(trimmed)
        } else if trimmed.hasPrefix("ss://") {
            return parseShadowsocks(trimmed)
        } else if trimmed.hasPrefix("vmess://") {
            return parseVmess(trimmed)
        }
        return nil
    }

    public static func parseMultiple(content: String) -> [VpnConfig] {
        var configs: [VpnConfig] = []
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty, let cfg = parse(link: t) {
                configs.append(cfg)
            }
        }
        // If content is base64 encoded list of links
        if configs.isEmpty {
            if let decoded = decodeBase64(content) {
                let decodedLines = decoded.components(separatedBy: .newlines)
                for line in decodedLines {
                    let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !t.isEmpty, let cfg = parse(link: t) {
                        configs.append(cfg)
                    }
                }
            }
        }
        return configs
    }

    // MARK: - VLESS Parser
    private static func parseVless(_ uriString: String) -> VpnConfig? {
        guard uriString.hasPrefix("vless://") else { return nil }
        let withoutScheme = String(uriString.dropFirst("vless://".count))

        // Split fragment (#name)
        let hashParts = withoutScheme.components(separatedBy: "#")
        let mainPart = hashParts[0]
        let name = hashParts.count > 1 ? (hashParts[1].removingPercentEncoding ?? hashParts[1]) : "VLESS Server"

        // Split user@host:port?query
        guard let atIndex = mainPart.firstIndex(of: "@") else { return nil }
        let uuid = String(mainPart[..<atIndex])
        let remaining = String(mainPart[mainPart.index(after: atIndex)...])

        var hostPort = remaining
        var queryString = ""
        if let qIndex = remaining.firstIndex(of: "?") {
            hostPort = String(remaining[..<qIndex])
            queryString = String(remaining[remaining.index(after: qIndex)...])
        }

        let (server, port) = parseHostPort(hostPort, defaultPort: 443)
        let query = parseQueryParams(queryString)

        let network = query["type"] ?? query["network"] ?? "tcp"
        let rawSecurity = (query["security"] ?? "none").lowercased()
        let security = (rawSecurity == "reality" || rawSecurity == "tls") ? rawSecurity : "none"
        let sni = query["sni"] ?? ""
        let host = query["host"] ?? ""
        let rawPath = query["path"] ?? "/"
        let path = normalizePath(rawPath)
        let flow = query["flow"] ?? ""
        let fingerprint = query["fp"] ?? ""
        let alpn = query["alpn"] ?? ""
        let publicKey = query["pbk"] ?? ""
        let shortId = query["sid"] ?? ""

        return VpnConfig(
            name: name,
            protocolType: .vless,
            server: server,
            port: port,
            uuid: uuid,
            network: network,
            security: security,
            sni: sni,
            host: host,
            path: path,
            flow: flow,
            fingerprint: fingerprint,
            alpn: alpn,
            publicKey: publicKey,
            shortId: shortId
        )
    }

    // MARK: - Hysteria 2 Parser
    private static func parseHysteria2(_ uriString: String) -> VpnConfig? {
        let prefix = uriString.hasPrefix("hy2://") ? "hy2://" : "hysteria2://"
        let withoutScheme = String(uriString.dropFirst(prefix.count))

        let hashParts = withoutScheme.components(separatedBy: "#")
        let mainPart = hashParts[0]
        let name = hashParts.count > 1 ? (hashParts[1].removingPercentEncoding ?? hashParts[1]) : "Hysteria 2 Server"

        guard let atIndex = mainPart.firstIndex(of: "@") else { return nil }
        let rawAuth = String(mainPart[..<atIndex])
        let password = rawAuth.removingPercentEncoding ?? rawAuth
        let remaining = String(mainPart[mainPart.index(after: atIndex)...])

        var hostPort = remaining
        var queryString = ""
        if let qIndex = remaining.firstIndex(of: "?") {
            hostPort = String(remaining[..<qIndex])
            queryString = String(remaining[remaining.index(after: qIndex)...])
        }

        let (server, port) = parseHostPort(hostPort, defaultPort: 443)
        let query = parseQueryParams(queryString)

        let sni = query["sni"] ?? (server == "129.150.63.107" ? "m.mobilelegends.com" : server)
        let allowInsecure = query["insecure"] == "1" || query["insecure"] == "true"
        let obfsType = query["obfs"] ?? (server == "129.150.63.107" ? "salamander" : "")
        let obfsPassword = query["obfs-password"] ?? query["obfs_password"] ?? (server == "129.150.63.107" ? "NatunnelObfs@2026" : "")
        let portHop = query["mport"] ?? query["ports"] ?? query["hop"] ?? ""
        let alpn = query["alpn"] ?? ""

        return VpnConfig(
            name: name,
            protocolType: .hysteria2,
            server: server,
            port: port,
            password: password,
            network: "hysteria",
            security: "tls",
            sni: sni,
            alpn: alpn,
            allowInsecure: allowInsecure,
            obfsType: obfsType,
            obfsPassword: obfsPassword,
            portHop: portHop
        )
    }

    // MARK: - Trojan Parser
    private static func parseTrojan(_ uriString: String) -> VpnConfig? {
        guard uriString.hasPrefix("trojan://") else { return nil }
        let withoutScheme = String(uriString.dropFirst("trojan://".count))

        let hashParts = withoutScheme.components(separatedBy: "#")
        let mainPart = hashParts[0]
        let name = hashParts.count > 1 ? (hashParts[1].removingPercentEncoding ?? hashParts[1]) : "Trojan Server"

        guard let atIndex = mainPart.firstIndex(of: "@") else { return nil }
        let password = String(mainPart[..<atIndex])
        let remaining = String(mainPart[mainPart.index(after: atIndex)...])

        var hostPort = remaining
        var queryString = ""
        if let qIndex = remaining.firstIndex(of: "?") {
            hostPort = String(remaining[..<qIndex])
            queryString = String(remaining[remaining.index(after: qIndex)...])
        }

        let (server, port) = parseHostPort(hostPort, defaultPort: 443)
        let query = parseQueryParams(queryString)

        let network = query["type"] ?? "tcp"
        let security = (query["security"] ?? "tls").lowercased()
        let sni = query["sni"] ?? server
        let host = query["host"] ?? ""
        let path = normalizePath(query["path"] ?? "/")
        let alpn = query["alpn"] ?? ""
        let allowInsecure = query["allowInsecure"] == "1" || query["allowInsecure"] == "true"

        return VpnConfig(
            name: name,
            protocolType: .trojan,
            server: server,
            port: port,
            password: password,
            network: network,
            security: security,
            sni: sni,
            host: host,
            path: path,
            alpn: alpn,
            allowInsecure: allowInsecure
        )
    }

    // MARK: - Shadowsocks Parser
    private static func parseShadowsocks(_ uriString: String) -> VpnConfig? {
        guard uriString.hasPrefix("ss://") else { return nil }
        let withoutScheme = String(uriString.dropFirst("ss://".count))

        let hashParts = withoutScheme.components(separatedBy: "#")
        let mainPart = hashParts[0]
        let name = hashParts.count > 1 ? (hashParts[1].removingPercentEncoding ?? hashParts[1]) : "Shadowsocks Server"

        var userInfo = ""
        var hostPort = ""

        if let atIndex = mainPart.firstIndex(of: "@") {
            let encodedUser = String(mainPart[..<atIndex])
            userInfo = decodeBase64(encodedUser) ?? encodedUser
            hostPort = String(mainPart[mainPart.index(after: atIndex)...])
        } else {
            // Entire string is base64 encoded: method:password@host:port
            guard let decoded = decodeBase64(mainPart) else { return nil }
            if let atIndex = decoded.firstIndex(of: "@") {
                userInfo = String(decoded[..<atIndex])
                hostPort = String(decoded[decoded.index(after: atIndex)...])
            }
        }

        let (server, port) = parseHostPort(hostPort, defaultPort: 8388)
        let userParts = userInfo.components(separatedBy: ":")
        let method = userParts.count > 0 ? userParts[0] : "aes-256-gcm"
        let password = userParts.count > 1 ? userParts.dropFirst().joined(separator: ":") : ""

        return VpnConfig(
            name: name,
            protocolType: .shadowsocks,
            server: server,
            port: port,
            password: password,
            method: method,
            network: "tcp"
        )
    }

    // MARK: - VMess Parser
    private static func parseVmess(_ uriString: String) -> VpnConfig? {
        guard uriString.hasPrefix("vmess://") else { return nil }
        let b64 = String(uriString.dropFirst("vmess://".count))
        guard let jsonString = decodeBase64(b64),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let name = (json["ps"] as? String) ?? "VMess Server"
        let server = (json["add"] as? String) ?? ""
        let portInt = (json["port"] as? Int) ?? Int((json["port"] as? String) ?? "443") ?? 443
        let uuid = (json["id"] as? String) ?? ""
        let method = (json["scy"] as? String) ?? "auto"
        let network = (json["net"] as? String) ?? "tcp"
        let host = (json["host"] as? String) ?? ""
        let path = normalizePath((json["path"] as? String) ?? "/")
        let security = (json["tls"] as? String) ?? "none"
        let sni = (json["sni"] as? String) ?? host
        let alpn = (json["alpn"] as? String) ?? ""

        return VpnConfig(
            name: name,
            protocolType: .vmess,
            server: server,
            port: portInt,
            uuid: uuid,
            method: method,
            network: network,
            security: security,
            sni: sni,
            host: host,
            path: path,
            alpn: alpn
        )
    }

    // MARK: - Export to Link
    public static func export(config: VpnConfig) -> String {
        switch config.protocolType {
        case .vless:
            let encodedName = config.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.name
            let encodedPath = config.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.path
            var uri = "vless://\(config.uuid)@\(config.server):\(config.port)?security=\(config.security)&sni=\(config.sni)&type=\(config.network)&path=\(encodedPath)&flow=\(config.flow)"
            if !config.host.isEmpty {
                uri += "&host=\(config.host.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.host)"
            }
            if !config.fingerprint.isEmpty { uri += "&fp=\(config.fingerprint)" }
            if !config.alpn.isEmpty { uri += "&alpn=\(config.alpn)" }
            if !config.publicKey.isEmpty { uri += "&pbk=\(config.publicKey)" }
            if !config.shortId.isEmpty { uri += "&sid=\(config.shortId)" }
            uri += "#\(encodedName)"
            return uri

        case .hysteria2:
            let encodedName = config.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.name
            let encodedPass = config.password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.password
            var uri = "hy2://\(encodedPass)@\(config.server):\(config.port)?"
            var params: [String] = []
            if !config.sni.isEmpty {
                params.append("sni=\(config.sni.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.sni)")
            }
            if config.allowInsecure { params.append("insecure=1") }
            if !config.obfsType.isEmpty { params.append("obfs=\(config.obfsType)") }
            if !config.obfsPassword.isEmpty {
                params.append("obfs-password=\(config.obfsPassword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.obfsPassword)")
            }
            if !config.portHop.isEmpty { params.append("mport=\(config.portHop)") }
            uri += params.joined(separator: "&")
            uri += "#\(encodedName)"
            return uri

        case .trojan:
            let encodedName = config.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.name
            let encodedPath = config.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.path
            var uri = "trojan://\(config.password)@\(config.server):\(config.port)?security=\(config.security)&sni=\(config.sni)&type=\(config.network)&path=\(encodedPath)"
            if !config.host.isEmpty { uri += "&host=\(config.host)" }
            uri += "#\(encodedName)"
            return uri

        case .shadowsocks:
            let rawUser = "\(config.method):\(config.password)"
            let b64 = Data(rawUser.utf8).base64EncodedString()
            let encodedName = config.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? config.name
            return "ss://\(b64)@\(config.server):\(config.port)#\(encodedName)"

        case .vmess:
            let hostVal = config.host.isEmpty ? config.sni : config.host
            let jsonDict: [String: Any] = [
                "v": "2",
                "ps": config.name,
                "add": config.server,
                "port": config.port,
                "id": config.uuid,
                "aid": 0,
                "scy": config.method.isEmpty ? "auto" : config.method,
                "net": config.network,
                "type": "none",
                "host": hostVal,
                "path": config.path,
                "tls": config.security,
                "sni": config.sni,
                "alpn": config.alpn
            ]
            if let data = try? JSONSerialization.data(withJSONObject: jsonDict),
               let jsonString = String(data: data, encoding: .utf8) {
                return "vmess://" + Data(jsonString.utf8).base64EncodedString()
            }
            return ""
        }
    }

    // MARK: - Utilities
    private static func parseHostPort(_ string: String, defaultPort: Int) -> (String, Int) {
        if string.hasPrefix("[") {
            // IPv6 [::1]:port
            if let closeBracket = string.firstIndex(of: "]") {
                let host = String(string[string.index(after: string.startIndex)..<closeBracket])
                let after = String(string[string.index(after: closeBracket)...])
                if after.hasPrefix(":"), let p = Int(after.dropFirst()) {
                    return (host, p)
                }
                return (host, defaultPort)
            }
        }
        let parts = string.components(separatedBy: ":")
        if parts.count >= 2, let p = Int(parts.last!) {
            let host = parts.dropLast().joined(separator: ":")
            return (host, p)
        }
        return (string, defaultPort)
    }

    private static func parseQueryParams(_ queryString: String) -> [String: String] {
        guard !queryString.isEmpty else { return [:] }
        var result: [String: String] = [:]
        let pairs = queryString.components(separatedBy: "&")
        for pair in pairs {
            let kv = pair.components(separatedBy: "=")
            if kv.count == 2 {
                let key = kv[0].removingPercentEncoding ?? kv[0]
                let val = kv[1].removingPercentEncoding ?? kv[1]
                result[key] = val
            } else if !pair.isEmpty {
                result[pair.removingPercentEncoding ?? pair] = ""
            }
        }
        return result
    }

    public static func normalizePath(_ raw: String) -> String {
        var p = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if p.isEmpty { return "/" }
        while p.contains("%2F") || p.contains("%3D") || p.contains("%20") {
            let decoded = p.removingPercentEncoding ?? p
            if decoded == p { break }
            p = decoded
        }
        p = p.trimmingCharacters(in: .whitespacesAndNewlines)
        return p.hasPrefix("/") ? p : "/\(p)"
    }

    public static func decodeBase64(_ text: String) -> String? {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        trimmed = trimmed.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let pad = (4 - (trimmed.count % 4)) % 4
        if pad > 0 { trimmed += String(repeating: "=", count: pad) }
        guard let data = Data(base64Encoded: trimmed) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
