//
//  SettingsScreen.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct SettingsScreen: View {
    @State private var settings = StorageService.shared.loadSettings()
    @State private var showLogs = false
    @State private var showResetConfirm = false

    public var body: some View {
        NavigationView {
            ZStack {
                ThemeColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Section: Routing & Rules
                        SettingsSection(title: "ROUTING & NETWORK") {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Routing Mode")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ThemeColor.textPrimary)

                                    Spacer()

                                    Picker("Routing Mode", selection: $settings.routingMode) {
                                        ForEach(RoutingMode.allCases) { mode in
                                            Text(mode.rawValue).tag(mode)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(ThemeColor.primary)
                                }

                                Divider().background(ThemeColor.border)

                                HStack {
                                    Text("DNS Provider")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ThemeColor.textPrimary)

                                    Spacer()

                                    Picker("DNS Provider", selection: $settings.dnsProvider) {
                                        ForEach(DnsProvider.allCases) { dns in
                                            Text(dns.rawValue).tag(dns)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(ThemeColor.primary)
                                }

                                Divider().background(ThemeColor.border)

                                HStack {
                                    Text("Tunnel MTU")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(ThemeColor.textPrimary)

                                    Spacer()

                                    TextField("1500", value: $settings.mtu, formatter: NumberFormatter())
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                        .foregroundColor(ThemeColor.primary)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                }
                            }
                        }

                        // Section: Automation
                        SettingsSection(title: "BEHAVIOR & AUTOMATION") {
                            VStack(spacing: 12) {
                                Toggle("Auto-connect on Mobile Data", isOn: $settings.autoConnectOnMobileData)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ThemeColor.textPrimary)
                                    .tint(ThemeColor.primary)

                                Divider().background(ThemeColor.border)

                                Toggle("Auto-connect on Wi-Fi", isOn: $settings.autoConnectOnWifi)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ThemeColor.textPrimary)
                                    .tint(ThemeColor.primary)

                                Divider().background(ThemeColor.border)

                                Toggle("Auto-connect on Launch", isOn: $settings.autoConnectOnLaunch)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ThemeColor.textPrimary)
                                    .tint(ThemeColor.primary)

                                Divider().background(ThemeColor.border)

                                Toggle("Auto-update Subscriptions", isOn: $settings.autoUpdateSubscriptions)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ThemeColor.textPrimary)
                                    .tint(ThemeColor.primary)
                            }
                        }

                        // Section: Diagnostics & Logs
                        SettingsSection(title: "DIAGNOSTICS") {
                            VStack(spacing: 12) {
                                Button(action: { showLogs = true }) {
                                    HStack {
                                        Image(systemName: "terminal.fill")
                                            .foregroundColor(ThemeColor.primary)
                                        Text("View Live Sing-box Logs")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(ThemeColor.textPrimary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(ThemeColor.textMuted)
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                }

                                Divider().background(ThemeColor.border)

                                Button(action: { showResetConfirm = true }) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                            .foregroundColor(ThemeColor.disconnected)
                                        Text("Restore Default Servers")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(ThemeColor.disconnected)
                                        Spacer()
                                    }
                                }
                            }
                        }

                        // Section: About
                        SettingsSection(title: "ABOUT NA TUNNEL") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Application Version")
                                        .font(.system(size: 13))
                                        .foregroundColor(ThemeColor.textSecondary)
                                    Spacer()
                                    Text("1.3.2 (Build 34)")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(ThemeColor.textPrimary)
                                }

                                HStack {
                                    Text("Tunnel Engine")
                                        .font(.system(size: 13))
                                        .foregroundColor(ThemeColor.textSecondary)
                                    Spacer()
                                    Text("Sing-box / libbox (Go)")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(ThemeColor.primary)
                                }

                                HStack {
                                    Text("Telegram Bot")
                                        .font(.system(size: 13))
                                        .foregroundColor(ThemeColor.textSecondary)
                                    Spacer()
                                    Link("@natunnel_vip_bot", destination: URL(string: "https://t.me/natunnel_vip_bot")!)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(ThemeColor.accentSky)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .onChange(of: settings) { newSettings in
                StorageService.shared.saveSettings(newSettings)
            }
            .sheet(isPresented: $showLogs) {
                LogsScreen()
            }
            .alert(isPresented: $showResetConfirm) {
                Alert(
                    title: Text("Restore Default Servers"),
                    message: Text("This will reinstall the official Metfone $0 Balance and Smart Reality servers."),
                    primaryButton: .destructive(Text("Restore")) {
                        resetDefaults()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func resetDefaults() {
        _ = StorageService.shared.loadConfigs()
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(ThemeColor.textSecondary)
                .padding(.leading, 6)

            NeonCard {
                content
            }
        }
    }
}
