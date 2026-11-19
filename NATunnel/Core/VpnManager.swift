//
//  VpnManager.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation
import NetworkExtension
import Combine

public enum VpnStatus: String {
    case disconnected = "DISCONNECTED"
    case connecting = "CONNECTING"
    case connected = "CONNECTED"
    case disconnecting = "DISCONNECTING"

    public var displayText: String {
        switch self {
        case .disconnected: return "DISCONNECTED"
        case .connecting: return "CONNECTING..."
        case .connected: return "CONNECTED"
        case .disconnecting: return "DISCONNECTING..."
        }
    }
}

public final class VpnManager: ObservableObject {
    public static let shared = VpnManager()

    @Published public var status: VpnStatus = .disconnected
    @Published public var activeConfig: VpnConfig?
    @Published public var trafficStats: TrafficStats = TrafficStats()
    @Published public var isPreparingVpn: Bool = false
    @Published public var lastErrorMessage: String?

    private var providerManager: NETunnelProviderManager?
    private var trafficTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private let storage = StorageService.shared
    private let tunnelBundleId = "com.natunnel.ios.PacketTunnel"

    private init() {
        loadActiveConfigFromStorage()
        setupNotificationObservers()
        refreshVpnManager()
    }

    // MARK: - Initializer & Active Config
    public func loadActiveConfigFromStorage() {
        let configs = storage.loadConfigs()
        if let activeId = storage.loadActiveConfigId(),
           let match = configs.first(where: { $0.id == activeId }) {
            self.activeConfig = match
        } else if let first = configs.first {
            self.activeConfig = first
            storage.saveActiveConfigId(first.id)
        }
    }

    public func selectConfig(_ config: VpnConfig) {
        var updated = config
        updated.isActive = true
        self.activeConfig = updated
        storage.saveActiveConfigId(config.id)

        // Mark in list
        var all = storage.loadConfigs()
        for i in 0..<all.count {
            all[i].isActive = (all[i].id == config.id)
        }
        storage.saveConfigs(all)

        // If currently connected, reconnect to apply new server
        if status == .connected {
            reconnect()
        }
    }

    // MARK: - NETunnelProviderManager Setup
    public func refreshVpnManager(completion: (() -> Void)? = nil) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            if let error = error {
                self.lastErrorMessage = "Failed to load VPN preferences: \(error.localizedDescription)"
                completion?()
                return
            }

            self.providerManager = managers?.first ?? NETunnelProviderManager()
            self.updateStatusFromManager()
            completion?()
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange(_:)),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }

    @objc private func vpnStatusDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateStatusFromManager()
        }
    }

    private func updateStatusFromManager() {
        guard let connection = providerManager?.connection else {
            status = .disconnected
            stopTrafficMonitoring()
            return
        }

        switch connection.status {
        case .connected:
            status = .connected
            startTrafficMonitoring()
            if let config = activeConfig {
                LiveActivityManager.shared.startLiveActivity(
                    serverName: config.name,
                    protocolName: config.protocolType.rawValue.uppercased(),
                    flag: config.flagEmoji,
                    pingMs: config.pingMs
                )
            }
        case .connecting:
            status = .connecting
        case .disconnecting:
            status = .disconnecting
        case .disconnected, .invalid:
            status = .disconnected
            stopTrafficMonitoring()
            LiveActivityManager.shared.endLiveActivity()
        case .reasserting:
            status = .connecting
        @unknown default:
            status = .disconnected
            stopTrafficMonitoring()
            LiveActivityManager.shared.endLiveActivity()
        }
    }

    // MARK: - Toggle Connection
    public func toggleConnection() {
        if status == .connected || status == .connecting {
            disconnect()
        } else {
            connect()
        }
    }

    public func connect() {
        guard let config = activeConfig else {
            lastErrorMessage = "No active server selected"
            return
        }

        // Security & Integrity check
        let sec = SecurityManager.shared.checkSecurity()
        if !sec.isAllowedToRun {
            lastErrorMessage = "Security Alert: Device integrity or hooking detected. Connection blocked."
            status = .disconnected
            isPreparingVpn = false
            return
        }

        isPreparingVpn = true
        status = .connecting

        let settings = storage.loadSettings()

        // Handle Smart Connect: Auto-select lowest latency node
        if settings.enableSmartConnect {
            let configs = storage.loadConfigs()
            PingEngine.pingAll(configs: configs, onUpdate: { _, _ in }) { [weak self] in
                guard let self = self else { return }
                let updated = self.storage.loadConfigs()
                if let best = updated.filter({ $0.pingMs > 0 }).min(by: { $0.pingMs < $1.pingMs }) {
                    self.activeConfig = best
                    self.storage.saveActiveConfigId(best.id)
                }
                self.startTunnel(with: self.activeConfig ?? config, settings: settings)
            }
        } else {
            startTunnel(with: config, settings: settings)
        }
    }

    private func startTunnel(with config: VpnConfig, settings: UserSettings) {
        refreshVpnManager { [weak self] in
            guard let self = self else { return }
            guard let manager = self.providerManager else {
                self.status = .disconnected
                self.isPreparingVpn = false
                return
            }

            guard let singboxConfigJson = SingboxConfigGenerator.generate(config: config, settings: settings) else {
                self.status = .disconnected
                self.isPreparingVpn = false
                self.lastErrorMessage = "Failed to generate Sing-box core configuration"
                return
            }

            let p = NETunnelProviderProtocol()
            p.providerBundleIdentifier = self.tunnelBundleId
            p.serverAddress = "\(config.server):\(config.port)"
            p.providerConfiguration = [
                "singbox_config": singboxConfigJson,
                "config_id": config.id,
                "server_name": config.name,
                "mtu": settings.mtu
            ]

            manager.protocolConfiguration = p
            manager.localizedDescription = "NA Tunnel (\(config.name))"
            manager.isEnabled = true

            // VPN On-Demand: Auto-connect when user turns on Mobile Data or Wi-Fi, even when app is closed!
            if settings.autoConnectOnMobileData || settings.enableAutoConnect {
                var rules: [NEOnDemandRule] = []
                if settings.autoConnectOnMobileData && settings.autoConnectOnWifi {
                    let connectAnyRule = NEOnDemandRuleConnect()
                    connectAnyRule.interfaceTypeMatch = .any
                    rules.append(connectAnyRule)
                } else if settings.autoConnectOnMobileData {
                    let connectCellularRule = NEOnDemandRuleConnect()
                    connectCellularRule.interfaceTypeMatch = .cellular
                    rules.append(connectCellularRule)

                    let ignoreWifiRule = NEOnDemandRuleIgnore()
                    ignoreWifiRule.interfaceTypeMatch = .wiFi
                    rules.append(ignoreWifiRule)
                } else if settings.autoConnectOnWifi {
                    let connectWifiRule = NEOnDemandRuleConnect()
                    connectWifiRule.interfaceTypeMatch = .wiFi
                    rules.append(connectWifiRule)

                    let ignoreCellularRule = NEOnDemandRuleIgnore()
                    ignoreCellularRule.interfaceTypeMatch = .cellular
                    rules.append(ignoreCellularRule)
                }
                manager.onDemandRules = rules
                manager.isOnDemandEnabled = true
            } else {
                manager.onDemandRules = []
                manager.isOnDemandEnabled = false
            }

            manager.saveToPreferences { [weak self] saveError in
                guard let self = self else { return }
                self.isPreparingVpn = false
                if let saveError = saveError {
                    self.status = .disconnected
                    self.lastErrorMessage = "VPN permission denied or failed to save: \(saveError.localizedDescription)"
                    return
                }

                manager.loadFromPreferences { loadError in
                    if let loadError = loadError {
                        self.status = .disconnected
                        self.lastErrorMessage = "Failed to reload VPN preferences: \(loadError.localizedDescription)"
                        return
                    }

                    do {
                        try manager.connection.startVPNTunnel(options: nil)
                    } catch {
                        self.status = .disconnected
                        self.lastErrorMessage = "Failed to start VPN tunnel: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    public func disconnect() {
        status = .disconnecting
        LiveActivityManager.shared.endLiveActivity()

        if let manager = providerManager {
            // When user manually disconnects, temporarily disable On-Demand so iOS does not
            // immediately trigger an unwanted background reconnection against user explicit action.
            manager.isOnDemandEnabled = false
            manager.saveToPreferences { [weak self] _ in
                self?.providerManager?.connection.stopVPNTunnel()
                self?.stopTrafficMonitoring()
                DispatchQueue.main.async {
                    self?.status = .disconnected
                }
            }
        } else {
            providerManager?.connection.stopVPNTunnel()
            stopTrafficMonitoring()
            status = .disconnected
        }
    }

    public func reconnect() {
        disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.connect()
        }
    }

    // MARK: - Traffic & Duration Monitoring
    private func startTrafficMonitoring() {
        stopTrafficMonitoring()
        let connectedDate = Date()
        trafficStats.connectedSince = connectedDate

        trafficTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Read live values from shared AppGroup UserDefaults
            if let sharedDefaults = UserDefaults(suiteName: StorageService.appGroupId) {
                let upSpeed = sharedDefaults.object(forKey: "traffic_up_speed") as? Int64 ?? 0
                let downSpeed = sharedDefaults.object(forKey: "traffic_down_speed") as? Int64 ?? 0
                let upTotal = sharedDefaults.object(forKey: "traffic_up_total") as? Int64 ?? 0
                let downTotal = sharedDefaults.object(forKey: "traffic_down_total") as? Int64 ?? 0

                DispatchQueue.main.async {
                    self.trafficStats.uplinkSpeedBytesPerSec = upSpeed
                    self.trafficStats.downlinkSpeedBytesPerSec = downSpeed
                    self.trafficStats.totalUplinkBytes = upTotal
                    self.trafficStats.totalDownlinkBytes = downTotal

                    // Push live speeds to Dynamic Island & Lock Screen
                    LiveActivityManager.shared.updateLiveActivity(
                        downloadSpeed: self.trafficStats.formattedDownloadSpeed,
                        uploadSpeed: self.trafficStats.formattedUploadSpeed,
                        totalData: self.trafficStats.formattedTotalDownload,
                        duration: self.trafficStats.formattedDuration,
                        serverName: self.activeConfig?.name ?? "NA Tunnel Node",
                        pingMs: self.activeConfig?.pingMs ?? 0
                    )
                }
            }
        }
    }

    private func stopTrafficMonitoring() {
        trafficTimer?.invalidate()
        trafficTimer = nil
        trafficStats.connectedSince = nil
        trafficStats.uplinkSpeedBytesPerSec = 0
        trafficStats.downlinkSpeedBytesPerSec = 0
    }
}
