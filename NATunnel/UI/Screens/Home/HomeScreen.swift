//
//  HomeScreen.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct HomeScreen: View {
    @ObservedObject var vpnManager = VpnManager.shared
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    @State private var showServerPicker = false
    @State private var showSpeedTest = false
    @State private var settings = StorageService.shared.loadSettings()
    @State private var showErrorAlert = false

    public var body: some View {
        ZStack {
            ThemeColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Top App Bar
                    HStack(spacing: 10) {
                        Image("app_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(ThemeColor.primary.opacity(0.35), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("NA Tunnel")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundColor(ThemeColor.textPrimary)

                            Text("Cambodia High-Speed Edition")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(ThemeColor.primary)
                        }

                        Spacer()

                        // Network Carrier Pill
                        HStack(spacing: 6) {
                            Circle()
                                .fill(networkMonitor.isConnected ? ThemeColor.connected : ThemeColor.disconnected)
                                .frame(width: 7, height: 7)

                            Text(networkMonitor.carrierDisplayText)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ThemeColor.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: 0x14281C))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(ThemeColor.border, lineWidth: 1))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // VPN Status Badge
                    StatusBadge(status: vpnManager.status)
                        .padding(.top, 8)

                    // Large Glowing Connection Button
                    ConnectionButton(status: vpnManager.status) {
                        vpnManager.toggleConnection()
                    }
                    .padding(.vertical, 12)

                    // Active Server Selector Card
                    ActiveServerCard(config: vpnManager.activeConfig) {
                        showServerPicker = true
                    }
                    .padding(.horizontal)

                    // Live Traffic Stats Card
                    TrafficCardView(
                        stats: vpnManager.trafficStats,
                        isConnected: vpnManager.status == .connected
                    )
                    .padding(.horizontal)

                    // Quick Feature Toggles
                    NeonCard {
                        VStack(spacing: 14) {
                            // Smart Connect
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(ThemeColor.primary)
                                    .font(.system(size: 16))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Smart Connect")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(ThemeColor.textPrimary)
                                    Text("Automatically routes through lowest ping node")
                                        .font(.system(size: 11))
                                        .foregroundColor(ThemeColor.textSecondary)
                                }

                                Spacer()

                                Toggle("", isOn: $settings.enableSmartConnect)
                                    .labelsHidden()
                                    .tint(ThemeColor.primary)
                                    .onChange(of: settings.enableSmartConnect) { _ in
                                        StorageService.shared.saveSettings(settings)
                                    }
                            }

                            Divider().background(ThemeColor.border)

                            // Game Mode
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                    .foregroundColor(ThemeColor.accentAmber)
                                    .font(.system(size: 16))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Gaming Low-Jitter Mode")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(ThemeColor.textPrimary)
                                    Text("Optimizes QUIC & UDP packet handling for Mobile Legends")
                                        .font(.system(size: 11))
                                        .foregroundColor(ThemeColor.textSecondary)
                                }

                                Spacer()

                                Toggle("", isOn: $settings.enableGameMode)
                                    .labelsHidden()
                                    .tint(ThemeColor.accentAmber)
                                    .onChange(of: settings.enableGameMode) { _ in
                                        StorageService.shared.saveSettings(settings)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showServerPicker) {
            ConfigsScreen(isPickerMode: true) { selected in
                vpnManager.selectConfig(selected)
                showServerPicker = false
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("VPN Error"),
                message: Text(vpnManager.lastErrorMessage ?? "Unknown connection error occurred"),
                dismissButton: .default(Text("OK")) {
                    vpnManager.lastErrorMessage = nil
                }
            )
        }
        .onChange(of: vpnManager.lastErrorMessage) { newMsg in
            if newMsg != nil {
                showErrorAlert = true
            }
        }
    }
}
