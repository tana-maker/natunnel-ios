//
//  NatConfigCrypto.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation
import CryptoKit
import CommonCrypto

public enum NatImportResult {
    case success(config: VpnConfig, message: String)
    case needsPassphrase(envelope: [String: Any], filename: String)
    case error(reason: String)
}

public final class NatConfigCrypto {

    // Master HMAC secret for NA Tunnel ecosystem
    private static let appMasterKeyBytes: [UInt8] = [
        0x4E, 0x41, 0x5F, 0x54, 0x55, 0x4E, 0x4E, 0x45,
        0x4C, 0x5F, 0x53, 0x45, 0x43, 0x55, 0x52, 0x45,
        0x5F, 0x4D, 0x41, 0x53, 0x54, 0x45, 0x52, 0x5F,
        0x4B, 0x45, 0x59, 0x5F, 0x32, 0x30, 0x32, 0x36
    ] // "NA_TUNNEL_SECURE_MASTER_KEY_2026"

    public static func importNat(content: String, passphrase: String? = nil) -> NatImportResult {
        guard let data = content.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return .error(reason: "Invalid JSON format in .na file")
        }

        let isLocked = (json["isLocked"] as? Bool) ?? false
        let filename = (json["filename"] as? String) ?? "imported.na"
        let userMessage = (json["userMessage"] as? String) ?? ""
        let encryption = (json["encryption"] as? String) ?? "NONE"

        if !isLocked || encryption.uppercased() == "NONE" {
            // Unlocked envelope: parse plaintext payload
            if let payloadB64 = json["payload"] as? String,
               let payloadData = Data(base64Encoded: payloadB64),
               let payloadJson = (try? JSONSerialization.jsonObject(with: payloadData)) as? [String: Any] {
                if let config = parseConfigFromDict(payloadJson, defaultName: json["remarks"] as? String ?? "Imported") {
                    return .success(config: config, message: userMessage)
                }
            } else if let shareUri = json["shareUri"] as? String,
                      let config = V2RayShareLinkParser.parse(link: shareUri) {
                return .success(config: config, message: userMessage)
            }
            return .error(reason: "Failed to parse unlocked payload")
        }

        // Locked envelope: Requires decryption
        guard let ciphertextB64 = json["ciphertext"] as? String ?? json["payload"] as? String,
              let cipherData = Data(base64Encoded: ciphertextB64),
              let ivB64 = json["iv"] as? String,
              let ivData = Data(base64Encoded: ivB64) else {
            return .error(reason: "Corrupted locked envelope structure")
        }

        // Try decrypting with app master key first (seamless import for app-locked profiles)
        if let decrypted = tryDecryptGCM(cipherData: cipherData, ivData: ivData, keyData: Data(appMasterKeyBytes)) {
            if let payloadJson = (try? JSONSerialization.jsonObject(with: decrypted)) as? [String: Any],
               let config = parseConfigFromDict(payloadJson, defaultName: json["remarks"] as? String ?? "Imported Locked") {
                return .success(config: config, message: userMessage)
            }
        }

        // If passphrase provided, try deriving key via PBKDF2
        if let pass = passphrase, !pass.isEmpty {
            let saltData: Data
            if let saltB64 = json["salt"] as? String, let s = Data(base64Encoded: saltB64) {
                saltData = s
            } else {
                saltData = Data("NA_TUNNEL_DEFAULT_SALT".utf8)
            }

            if let derivedKey = deriveKey(passphrase: pass, salt: saltData),
               let decrypted = tryDecryptGCM(cipherData: cipherData, ivData: ivData, keyData: derivedKey) {
                if let payloadJson = (try? JSONSerialization.jsonObject(with: decrypted)) as? [String: Any],
                   let config = parseConfigFromDict(payloadJson, defaultName: json["remarks"] as? String ?? "Imported Locked") {
                    return .success(config: config, message: userMessage)
                }
            }
            return .error(reason: "Incorrect passphrase. Please try again.")
        }

        return .needsPassphrase(envelope: json, filename: filename)
    }

    public static func exportNat(config: VpnConfig, isLocked: Bool = false, passphrase: String? = nil, userMessage: String = "") -> String? {
        var envelope: [String: Any] = [
            "version": "2.0",
            "format": "na",
            "client": "NA Tunnel iOS",
            "filename": "\(config.name).na",
            "isLocked": isLocked,
            "protocol": config.protocolType.rawValue,
            "remarks": config.name,
            "userMessage": userMessage
        ]

        let payloadDict: [String: Any] = [
            "name": config.name,
            "protocol": config.protocolType.rawValue,
            "server": config.server,
            "port": config.port,
            "uuid": config.uuid,
            "password": config.password,
            "method": config.method,
            "network": config.network,
            "security": config.security,
            "sni": config.sni,
            "host": config.host,
            "path": config.path,
            "flow": config.flow,
            "publicKey": config.publicKey,
            "shortId": config.shortId,
            "allowInsecure": config.allowInsecure,
            "obfsType": config.obfsType,
            "obfsPassword": config.obfsPassword
        ]

        guard let payloadData = try? JSONSerialization.data(withJSONObject: payloadDict) else {
            return nil
        }

        if !isLocked {
            envelope["encryption"] = "NONE"
            envelope["payload"] = payloadData.base64EncodedString()
            envelope["shareUri"] = V2RayShareLinkParser.export(config: config)
        } else {
            envelope["encryption"] = "AES-256-GCM"
            let salt = randomBytes(count: 16)
            let iv = randomBytes(count: 12)
            let keyData: Data
            if let pass = passphrase, !pass.isEmpty {
                keyData = deriveKey(passphrase: pass, salt: salt) ?? Data(appMasterKeyBytes)
                envelope["salt"] = salt.base64EncodedString()
            } else {
                keyData = Data(appMasterKeyBytes)
            }

            guard let (ciphertext, tag) = encryptGCM(plainData: payloadData, ivData: iv, keyData: keyData) else {
                return nil
            }
            envelope["iv"] = iv.base64EncodedString()
            envelope["ciphertext"] = (ciphertext + tag).base64EncodedString()
        }

        guard let finalData = try? JSONSerialization.data(withJSONObject: envelope, options: .prettyPrinted) else {
            return nil
        }
        return String(data: finalData, encoding: .utf8)
    }

    // MARK: - AES-GCM Helpers
    private static func tryDecryptGCM(cipherData: Data, ivData: Data, keyData: Data) -> Data? {
        guard keyData.count == 32, ivData.count == 12, cipherData.count >= 16 else { return nil }
        let symKey = SymmetricKey(data: keyData)
        guard let nonce = try? AES.GCM.Nonce(data: ivData) else { return nil }

        // Last 16 bytes is tag
        let tagLength = 16
        let actualCipher = cipherData.prefix(cipherData.count - tagLength)
        let tag = cipherData.suffix(tagLength)

        guard let sealedBox = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: actualCipher, tag: tag) else {
            return nil
        }
        return try? AES.GCM.open(sealedBox, using: symKey)
    }

    private static func encryptGCM(plainData: Data, ivData: Data, keyData: Data) -> (Data, Data)? {
        guard keyData.count == 32, ivData.count == 12 else { return nil }
        let symKey = SymmetricKey(data: keyData)
        guard let nonce = try? AES.GCM.Nonce(data: ivData),
              let sealedBox = try? AES.GCM.seal(plainData, using: symKey, nonce: nonce) else {
            return nil
        }
        return (sealedBox.ciphertext, sealedBox.tag)
    }

    private static func deriveKey(passphrase: String, salt: Data) -> Data? {
        var derivedKey = Data(repeating: 0, count: 32)
        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passphrase,
                    passphrase.utf8.count,
                    saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    65536,
                    derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    32
                )
            }
        }
        return result == kCCSuccess ? derivedKey : nil
    }

    private static func randomBytes(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }

    private static func parseConfigFromDict(_ dict: [String: Any], defaultName: String) -> VpnConfig? {
        let name = (dict["name"] as? String) ?? defaultName
        let protoStr = ((dict["protocol"] as? String) ?? "VLESS").uppercased()
        let proto = ProxyProtocol(rawValue: protoStr) ?? .vless
        let server = (dict["server"] as? String) ?? ""
        let port = (dict["port"] as? Int) ?? 443
        let uuid = (dict["uuid"] as? String) ?? ""
        let password = (dict["password"] as? String) ?? ""
        let method = (dict["method"] as? String) ?? "auto"
        let network = (dict["network"] as? String) ?? "tcp"
        let security = (dict["security"] as? String) ?? "tls"
        let sni = (dict["sni"] as? String) ?? ""
        let host = (dict["host"] as? String) ?? ""
        let path = (dict["path"] as? String) ?? "/"
        let flow = (dict["flow"] as? String) ?? ""
        let publicKey = (dict["publicKey"] as? String) ?? ""
        let shortId = (dict["shortId"] as? String) ?? ""
        let allowInsecure = (dict["allowInsecure"] as? Bool) ?? false
        let obfsType = (dict["obfsType"] as? String) ?? ""
        let obfsPassword = (dict["obfsPassword"] as? String) ?? ""

        return VpnConfig(
            name: name,
            protocolType: proto,
            server: server,
            port: port,
            uuid: uuid,
            password: password,
            method: method,
            network: network,
            security: security,
            sni: sni,
            host: host,
            path: path,
            flow: flow,
            publicKey: publicKey,
            shortId: shortId,
            allowInsecure: allowInsecure,
            obfsType: obfsType,
            obfsPassword: obfsPassword
        )
    }
}
