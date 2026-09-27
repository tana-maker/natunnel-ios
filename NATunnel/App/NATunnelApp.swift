//
//  NATunnelApp.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

@main
struct NATunnelApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var vpnManager = VpnManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .environmentObject(vpnManager)
                .environmentObject(networkMonitor)
                .onAppear {
                    handleAppLaunch()
                }
        }
    }

    private func handleAppLaunch() {
        let settings = StorageService.shared.loadSettings()
        if settings.autoConnectOnLaunch {
            vpnManager.connect()
        }

        // Auto update subscriptions in background
        if settings.autoUpdateSubscriptions {
            SubscriptionService.shared.updateAllSubscriptions {}
        }
    }
}
