//
//  PingEngine.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation
import Network

public final class PingEngine {

    public static func ping(host: String, port: Int, timeout: TimeInterval = 1.2, completion: @escaping (Int64) -> Void) {
        let endpointHost = NWEndpoint.Host(host)
        guard let endpointPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            completion(-1)
            return
        }

        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = Int(timeout)
        let params = NWParameters(tls: nil, tcp: tcpOptions)
        params.prohibitedInterfaceTypes = []

        let connection = NWConnection(host: endpointHost, port: endpointPort, using: params)
        let queue = DispatchQueue(label: "com.natunnel.ping.\(host).\(port)")
        let startTime = CFAbsoluteTimeGetCurrent()

        var hasFinished = false
        let finishOnce: (Int64) -> Void = { latency in
            if !hasFinished {
                hasFinished = true
                connection.cancel()
                DispatchQueue.main.async {
                    completion(latency)
                }
            }
        }

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                let ms = Int64(duration * 1000)
                finishOnce(max(1, ms))
            case .failed, .cancelled:
                finishOnce(-1)
            case .waiting:
                break
            default:
                break
            }
        }

        connection.start(queue: queue)

        queue.asyncAfter(deadline: .now() + timeout) {
            finishOnce(-1)
        }
    }

    public static func pingAll(configs: [VpnConfig], onUpdate: @escaping (String, Int64) -> Void, onComplete: @escaping () -> Void) {
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 2) // Concurrency of 2 prevents cellular bufferbloat and battery drain

        for cfg in configs {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                semaphore.wait()
                ping(host: cfg.server, port: cfg.port) { ms in
                    onUpdate(cfg.id, ms)
                    semaphore.signal()
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            onComplete()
        }
    }
}
