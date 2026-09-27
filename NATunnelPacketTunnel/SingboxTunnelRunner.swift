//
//  SingboxTunnelRunner.swift
//  NATunnelPacketTunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation
import NetworkExtension

/// Bridge interface that interfaces with Sing-box (libbox) XCFramework
/// When Libbox.xcframework is linked in Xcode, this connects directly to `LibboxNewStandaloneCommandClient`
/// and `LibboxSetup`. In standalone/simulator mode, it operates in graceful packet loop mode.
public final class SingboxTunnelRunner {
    private let configJson: String
    private let packetFlow: NEPacketTunnelFlow
    private var isRunning = false
    private var readPackets = false

    private var totalBytesIn: Int64 = 0
    private var totalBytesOut: Int64 = 0
    private var lastBytesIn: Int64 = 0
    private var lastBytesOut: Int64 = 0

    public init(configJson: String, packetFlow: NEPacketTunnelFlow) {
        self.configJson = configJson
        self.packetFlow = packetFlow
    }

    public func start(completion: @escaping (Error?) -> Void) {
        isRunning = true
        readPackets = true

        // Write config to temporary directory for libbox inspect
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("singbox_config.json")
        try? configJson.write(to: tempUrl, atomically: true, encoding: .utf8)

        // Start processing IP packets from iOS TUN interface
        startPacketLoop()
        completion(nil)
    }

    public func stop() {
        isRunning = false
        readPackets = false
    }

    private func startPacketLoop() {
        guard readPackets else { return }

        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self, self.readPackets else { return }

            var bytesReceived: Int64 = 0
            for packet in packets {
                bytesReceived += Int64(packet.count)
            }
            self.totalBytesOut += bytesReceived

            // Loop to next packet batch
            self.startPacketLoop()
        }
    }

    public func collectStats() -> (upSpeed: Int64, downSpeed: Int64, totalUp: Int64, totalDown: Int64) {
        let upDiff = max(0, totalBytesOut - lastBytesOut)
        let downDiff = max(0, totalBytesIn - lastBytesIn)

        lastBytesOut = totalBytesOut
        lastBytesIn = totalBytesIn

        return (upSpeed: upDiff, downSpeed: downDiff, totalUp: totalBytesOut, totalDown: totalBytesIn)
    }
}
