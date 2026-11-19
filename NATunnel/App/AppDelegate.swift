//
//  AppDelegate.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Enforce anti-debugging & memory tampering protection
        SecurityManager.shared.denyDebuggerAttach()

        // Pre-load configs if first launch
        _ = StorageService.shared.loadConfigs()
        return true
    }

    // Handle deep links (natunnel://import?...) or .na files
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.isFileURL {
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                let res = NatConfigCrypto.importNat(content: content)
                if case .success(let config, _) = res {
                    var current = StorageService.shared.loadConfigs()
                    current.insert(config, at: 0)
                    StorageService.shared.saveConfigs(current)
                    VpnManager.shared.selectConfig(config)
                    return true
                }
            }
        } else if let scheme = url.scheme, scheme.lowercased() == "natunnel" {
            // URL Scheme handler
            let rawUrl = url.absoluteString.replacingOccurrences(of: "natunnel://", with: "")
            if let config = V2RayShareLinkParser.parse(link: rawUrl) {
                var current = StorageService.shared.loadConfigs()
                current.insert(config, at: 0)
                StorageService.shared.saveConfigs(current)
                VpnManager.shared.selectConfig(config)
                return true
            }
        }
        return false
    }
}
