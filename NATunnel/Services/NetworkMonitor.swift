//
//  NetworkMonitor.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation
import Network
import Combine

public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.natunnel.networkmonitor")

    @Published public var isConnected: Bool = true
    @Published public var isExpensive: Bool = false // Cellular
    @Published public var connectionType: String = "Wi-Fi"
    @Published public var carrierDisplayText: String = "Metfone / Smart 4G"

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
                self?.isExpensive = path.isExpensive

                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = "Wi-Fi"
                    self?.carrierDisplayText = "Wi-Fi Connected"
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = "Cellular"
                    self?.carrierDisplayText = "Cellular (Metfone / Smart)"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = "Ethernet"
                    self?.carrierDisplayText = "Ethernet"
                } else {
                    self?.connectionType = "Offline"
                    self?.carrierDisplayText = "No Internet Connection"
                }
            }
        }
        monitor.start(queue: queue)
    }
}
