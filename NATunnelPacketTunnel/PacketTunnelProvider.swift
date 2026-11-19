//
//  PacketTunnelProvider.swift
//  NATunnelPacketTunnel
//
//  Created for NA Tunnel iOS.
//

import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var runner: SingboxTunnelRunner?
    private var statsTimer: Timer?
    private let appGroupId = "group.com.natunnel.ios"

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Apply Go runtime memory limit early to prevent iOS Jetsam kills (15MB-30MB ceiling)
        setenv("GOMEMLIMIT", "15MiB", 1)
        setenv("GOGC", "20", 1)

        let conf = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration
        guard let configJson = conf?["singbox_config"] as? String else {
            let err = NSError(
                domain: "NATunnelPacketTunnel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Missing Sing-box configuration"]
            )
            completionHandler(err)
            return
        }

        let serverName = (conf?["server_name"] as? String) ?? "NA Tunnel Node"

        // 1. Configure iOS TUN Virtual Network Interface
        let tunnelNetworkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")

        // IPv4 configuration (172.19.0.1/30)
        let ipv4Settings = NEIPv4Settings(addresses: ["172.19.0.1"], subnetMasks: ["255.255.255.252"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        tunnelNetworkSettings.ipv4Settings = ipv4Settings

        // 2. IPv6 Leak Protection (Crucial for Cambodian carriers like Smart Axiata & Metfone with dual-stack APNs)
        // Routing default IPv6 through tunnel prevents ISP from observing plain-text queries over cellular IPv6
        let ipv6Settings = NEIPv6Settings(addresses: ["2001:db8::1"], networkPrefixLengths: [126])
        ipv6Settings.includedRoutes = [NEIPv6Route.default()]
        tunnelNetworkSettings.ipv6Settings = ipv6Settings

        // 3. DNS configuration (Cloudflare 1.1.1.1 + Google 8.8.8.8 with catch-all matchDomains)
        let dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        dnsSettings.matchDomains = [""] // Catch-all wildcard forces 100% of device DNS queries into tunnel
        tunnelNetworkSettings.dnsSettings = dnsSettings

        // 4. MTU (Default 1380 for mobile carrier payload & zero-rated bypass stability)
        let mtu = (conf?["mtu"] as? Int) ?? 1380
        tunnelNetworkSettings.mtu = NSNumber(value: mtu)

        setTunnelNetworkSettings(tunnelNetworkSettings) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completionHandler(error)
                return
            }

            // 5. Start Sing-box core engine
            let tunnelRunner = SingboxTunnelRunner(configJson: configJson, packetFlow: self.packetFlow)
            self.runner = tunnelRunner

            tunnelRunner.start { runnerError in
                if let runnerError = runnerError {
                    completionHandler(runnerError)
                    return
                }

                // 6. Start live stats reporting to Shared App Group
                self.startStatsReporting()
                self.logInfo("NA Tunnel connected successfully to \(serverName) (IPv4/IPv6 protected, MTU: \(mtu))")
                completionHandler(nil)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopStatsReporting()
        runner?.stop()
        runner = nil
        logInfo("NA Tunnel stopped (Reason: \(reason.rawValue))")
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        guard let message = String(data: messageData, encoding: .utf8) else {
            completionHandler?(nil)
            return
        }

        switch message {
        case "query_status":
            let status = ["status": "running", "memory_limit": "15MiB"]
            let res = try? JSONSerialization.data(withJSONObject: status)
            completionHandler?(res)
        case "reset_network":
            runner?.resetNetwork()
            completionHandler?(Data("ok".utf8))
        case "query_stats":
            if let stats = runner?.collectStats() {
                let dict: [String: Any] = [
                    "up_speed": stats.upSpeed,
                    "down_speed": stats.downSpeed,
                    "total_up": stats.totalUp,
                    "total_down": stats.totalDown
                ]
                let res = try? JSONSerialization.data(withJSONObject: dict)
                completionHandler?(res)
            } else {
                completionHandler?(nil)
            }
        default:
            completionHandler?(nil)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        logInfo("Device entering sleep, pausing background telemetry")
        stopStatsReporting()
        completionHandler()
    }

    override func wake() {
        logInfo("Device waking from sleep, recovering tunnel routes and network interface")
        runner?.resetNetwork()
        startStatsReporting()
    }

    // MARK: - App Group Traffic Reporting
    private func startStatsReporting() {
        stopStatsReporting()
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let runner = self.runner else { return }
            let stats = runner.collectStats()

            if let defaults = UserDefaults(suiteName: self.appGroupId) {
                defaults.set(stats.upSpeed, forKey: "traffic_up_speed")
                defaults.set(stats.downSpeed, forKey: "traffic_down_speed")
                defaults.set(stats.totalUp, forKey: "traffic_up_total")
                defaults.set(stats.totalDown, forKey: "traffic_down_total")
            }
        }
        // Power efficiency: Allow 200ms timer coalescing to align CPU wakeups with iOS power management
        timer.tolerance = 0.2
        RunLoop.current.add(timer, forMode: .common)
        statsTimer = timer
    }

    private func stopStatsReporting() {
        statsTimer?.invalidate()
        statsTimer = nil
        if let defaults = UserDefaults(suiteName: appGroupId) {
            defaults.set(0, forKey: "traffic_up_speed")
            defaults.set(0, forKey: "traffic_down_speed")
        }
    }

    private func logInfo(_ message: String) {
        NSLog("[NATunnelPacketTunnel] %@", message)
    }
}
