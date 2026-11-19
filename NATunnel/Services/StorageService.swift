//
//  StorageService.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public final class StorageService {
    public static let shared = StorageService()

    public static let appGroupId = "group.com.natunnel.ios"

    private let defaults: UserDefaults

    private init() {
        if let sharedDefaults = UserDefaults(suiteName: StorageService.appGroupId) {
            self.defaults = sharedDefaults
        } else {
            self.defaults = UserDefaults.standard
        }
    }

    private let configsKey = "na_tunnel_saved_configs"
    private let activeConfigIdKey = "na_tunnel_active_config_id"
    private let settingsKey = "na_tunnel_user_settings"
    private let subscriptionsKey = "na_tunnel_subscriptions"
    private let logsKey = "na_tunnel_app_logs"

    // MARK: - Configurations
    public func loadConfigs() -> [VpnConfig] {
        if let data = defaults.data(forKey: configsKey),
           let list = try? JSONDecoder().decode([VpnConfig].self, from: data), !list.isEmpty {
            return list
        }
        // First launch: Preload official NA Tunnel servers
        let defaultsList = createDefaultServers()
        saveConfigs(defaultsList)
        if let first = defaultsList.first {
            saveActiveConfigId(first.id)
        }
        return defaultsList
    }

    public func saveConfigs(_ configs: [VpnConfig]) {
        if let data = try? JSONEncoder().encode(configs) {
            defaults.set(data, forKey: configsKey)
        }
    }

    public func loadActiveConfigId() -> String? {
        defaults.string(forKey: activeConfigIdKey)
    }

    public func saveActiveConfigId(_ id: String?) {
        defaults.set(id, forKey: activeConfigIdKey)
    }

    // MARK: - User Settings
    public func loadSettings() -> UserSettings {
        if let data = defaults.data(forKey: settingsKey),
           let s = try? JSONDecoder().decode(UserSettings.self, from: data) {
            return s
        }
        let def = UserSettings.default
        saveSettings(def)
        return def
    }

    public func saveSettings(_ settings: UserSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
    }

    // MARK: - Subscriptions
    public func loadSubscriptions() -> [SubscriptionItem] {
        if let data = defaults.data(forKey: subscriptionsKey),
           let list = try? JSONDecoder().decode([SubscriptionItem].self, from: data) {
            // Filter out official subscription links for pure blank VPN
            return list.filter {
                !$0.url.contains("theworkpc.com") &&
                !$0.name.contains("NA Tunnel - SG")
            }
        }
        // Blank VPN Client: Subscriptions start empty
        return []
    }

    public func saveSubscriptions(_ subscriptions: [SubscriptionItem]) {
        if let data = try? JSONEncoder().encode(subscriptions) {
            defaults.set(data, forKey: subscriptionsKey)
        }
    }

    // MARK: - Logs
    public func loadLogs() -> [LogEntry] {
        if let data = defaults.data(forKey: logsKey),
           let list = try? JSONDecoder().decode([LogEntry].self, from: data) {
            return list
        }
        return []
    }

    public func appendLog(_ entry: LogEntry) {
        var current = loadLogs()
        current.append(entry)
        if current.count > 500 {
            current.removeFirst(current.count - 500)
        }
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: logsKey)
        }
    }

    public func clearLogs() {
        defaults.removeObject(forKey: logsKey)
    }

    // MARK: - Default Official Servers
    private func createDefaultServers() -> [VpnConfig] {
        var list: [VpnConfig] = []

        // 1. Metfone $0 Balance Server 1
        if let s1 = V2RayShareLinkParser.parse(link: "vless://07b5bac3-4aac-4593-ab18-c9dd829cb794@na-metfone-free.theworkpc.com:80?encryption=none&security=none&type=ws&host=na-tunnel-sg.theworkpc.com&path=%2F#🇰🇭 Metfone-Free-01 🎁") {
            var cfg = s1
            cfg.isActive = true
            list.append(cfg)
        }

        // 2. Metfone $0 Balance Server 2 (Backup)
        if let s2 = V2RayShareLinkParser.parse(link: "vless://07b5bac3-4aac-4593-ab18-c9dd829cb794@na-metfone-free.theworkpc.com:80?encryption=none&security=none&type=ws&host=na-tunnel-sg2.theworkpc.com&path=%2F#🇰🇭 Metfone-Free-02 🎁") {
            list.append(s2)
        }

        // 3. Smart Axiata / WeChat Port 443 VLESS Reality (Server 1)
        if let s3 = V2RayShareLinkParser.parse(link: "vless://07b5bac3-4aac-4593-ab18-c9dd829cb794@129.150.63.107:443?security=reality&encryption=none&pbk=a2PAaVVSDRwLVTWnF9Mx44EDc9FBLL92tzbfPNUuhTE&headerType=none&fp=chrome&spx=%2F&type=tcp&flow=xtls-rprx-vision&sni=www.wechat.com&sid=907d4ae9#🇰🇭 Smart-VIP-01 ⚡") {
            list.append(s3)
        }

        // 4. Smart Axiata / WeChat Port 443 VLESS Reality (Server 2)
        if let s4 = V2RayShareLinkParser.parse(link: "vless://07b5bac3-4aac-4593-ab18-c9dd829cb794@152.69.223.67:443?security=reality&encryption=none&pbk=a2PAaVVSDRwLVTWnF9Mx44EDc9FBLL92tzbfPNUuhTE&headerType=none&fp=chrome&spx=%2F&type=tcp&flow=xtls-rprx-vision&sni=www.wechat.com&sid=907d4ae9#🇰🇭 Smart-VIP-02 ⚡") {
            list.append(s4)
        }

        // 5. Smart Axiata High Speed Gaming Hysteria 2 (UDP 443 - Mobile Legends)
        if let s5 = V2RayShareLinkParser.parse(link: "hy2://Natunnel%402026@129.150.63.107:443?insecure=1&sni=m.mobilelegends.com&obfs=salamander&obfs-password=NatunnelObfs%402026#🇰🇭 Smart-Gaming-HY2 🎮") {
            list.append(s5)
        }

        // 6. Smart Axiata Digital Learning Pack Hysteria 2 (UDP 443 - onesala.com)
        if let s6 = V2RayShareLinkParser.parse(link: "hy2://Natunnel%402026@129.150.63.107:443?insecure=1&sni=onesala.com&obfs=salamander&obfs-password=NatunnelObfs%402026#🇰🇭 Smart-Learning-HY2 📚") {
            list.append(s6)
        }

        // 7. Smart Axiata Server 2 High Speed Gaming Hysteria 2 (UDP 443 - SG-02)
        if let s7 = V2RayShareLinkParser.parse(link: "hy2://Natunnel%402026@152.69.223.67:443?insecure=1&sni=m.mobilelegends.com&obfs=salamander&obfs-password=NatunnelObfs%402026#🇰🇭 Smart-VIP-02-HY2 🎮") {
            list.append(s7)
        }

        return list
    }
}
