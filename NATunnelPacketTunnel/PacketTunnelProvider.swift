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
        let conf = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration
        guard let configJson = conf?["singbox_config"] as? String else {
            let err = NSError(domain: "NATunnelPacketTunnel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Sing-box configuration"])
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

        // DNS configuration (Cloudflare 1.1.1.1 + Google 8.8.8.8)
        let dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        dnsSettings.matchDomains = [""]
        tunnelNetworkSettings.dnsSettings = dnsSettings

        // MTU (Default 1500)
        tunnelNetworkSettings.mtu = 1500

        setTunnelNetworkSettings(tunnelNetworkSettings) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                completionHandler(error)
                return
            }

            // 2. Start Sing-box engine
            let tunnelRunner = SingboxTunnelRunner(configJson: configJson, packetFlow: self.packetFlow)
            self.runner = tunnelRunner

            tunnelRunner.start { runnerError in
                if let runnerError = runnerError {
                    completionHandler(runnerError)
                    return
                }

                // 3. Start live stats reporting to Shared App Group
                self.startStatsReporting()
                self.logInfo("NA Tunnel connected successfully to \(serverName)")
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
        // App can query status or trigger ping from packet tunnel
        completionHandler?(nil)
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func wake() {
        // Reconnect if network transitioned
    }

    // MARK: - App Group Traffic Reporting
    private func startStatsReporting() {
        stopStatsReporting()
        statsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let runner = self.runner else { return }
            let stats = runner.collectStats()

            if let defaults = UserDefaults(suiteName: self.appGroupId) {
                defaults.set(stats.upSpeed, forKey: "traffic_up_speed")
                defaults.set(stats.downSpeed, forKey: "traffic_down_speed")
                defaults.set(stats.totalUp, forKey: "traffic_up_total")
                defaults.set(stats.totalDown, forKey: "traffic_down_total")
            }
        }
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
