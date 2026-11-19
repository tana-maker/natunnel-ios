//
//  ConfigsScreen.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct ConfigsScreen: View {
    @ObservedObject var vpnManager = VpnManager.shared
    let isPickerMode: Bool
    let onSelectFromPicker: ((VpnConfig) -> Void)?

    @State private var configs: [VpnConfig] = []
    @State private var selectedFilter: Int = 0 // 0 = All, 1 = Metfone/Smart, 2 = Hysteria 2, 3 = Custom
    @State private var searchText: String = ""
    @State private var isPingingAll = false

    @State private var showAddSheet = false
    @State private var showEditSheet = false
    @State private var configToEdit: VpnConfig?
    @State private var showQRScanner = false
    @State private var showActionMenu = false
    @State private var alertMessage: String?
    @State private var showAlert = false

    public init(isPickerMode: Bool = false, onSelect: ((VpnConfig) -> Void)? = nil) {
        self.isPickerMode = isPickerMode
        self.onSelectFromPicker = onSelect
    }

    public var body: some View {
        NavigationView {
            ZStack {
                ThemeColor.background.ignoresSafeArea()

                VStack(spacing: 12) {
                    // Filter Bar
                    Picker("Server Filter", selection: $selectedFilter) {
                        Text("All").tag(0)
                        Text("🇰🇭 Metfone / Smart").tag(1)
                        Text("⚡ Hysteria 2").tag(2)
                        Text("Other").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 4)

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ThemeColor.textMuted)

                        TextField("Search servers by name, SNI, or port...", text: $searchText)
                            .foregroundColor(ThemeColor.textPrimary)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(ThemeColor.textMuted)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(hex: 0x14281C))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ThemeColor.border, lineWidth: 1))
                    .padding(.horizontal)

                    // Servers List
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredConfigs) { cfg in
                                ConfigRowView(
                                    config: cfg,
                                    isSelected: vpnManager.activeConfig?.id == cfg.id,
                                    onPing: {
                                        pingSingle(cfg)
                                    },
                                    onSelect: {
                                        if isPickerMode {
                                            onSelectFromPicker?(cfg)
                                        } else {
                                            vpnManager.selectConfig(cfg)
                                        }
                                    }
                                )
                                .contextMenu {
                                    if !cfg.isLocked.value {
                                        Button(action: {
                                            let link = V2RayShareLinkParser.export(config: cfg)
                                            UIPasteboard.general.string = link
                                            notifyUser("Share link copied to clipboard")
                                        }) {
                                            Label("Copy Share Link", systemImage: "doc.on.doc")
                                        }

                                        Button(action: {
                                            if let naJson = NatConfigCrypto.exportNat(config: cfg) {
                                                UIPasteboard.general.string = naJson
                                                notifyUser(".na configuration copied to clipboard")
                                            }
                                        }) {
                                            Label("Export .na Configuration", systemImage: "shield")
                                        }

                                        Button(action: {
                                            configToEdit = cfg
                                            showEditSheet = true
                                        }) {
                                            Label("Edit Server", systemImage: "pencil")
                                        }
                                    } else {
                                        Label("Protected Official Server", systemImage: "lock.shield.fill")
                                    }

                                    Button(role: .destructive, action: {
                                        deleteConfig(cfg)
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitle(isPickerMode ? "Select Server Node" : "Servers", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: pingAll) {
                    HStack(spacing: 4) {
                        Image(systemName: isPingingAll ? "arrow.triangle.2.circlepath" : "bolt.horizontal.fill")
                            .rotationEffect(.degrees(isPingingAll ? 360 : 0))
                            .animation(
                                isPingingAll ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: isPingingAll
                            )
                        Text(isPingingAll ? "Testing..." : "Ping All")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(ThemeColor.primary)
                }
                .disabled(isPingingAll),
                trailing: Button(action: { showActionMenu = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ThemeColor.primary)
                }
            )
            .actionSheet(isPresented: $showActionMenu) {
                ActionSheet(
                    title: Text("Add Server Configuration"),
                    buttons: [
                        .default(Text("📷 Scan QR Code")) {
                            showQRScanner = true
                        },
                        .default(Text("📋 Import from Clipboard")) {
                            importFromClipboard()
                        },
                        .default(Text("✏️ Add Manually")) {
                            showAddSheet = true
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showAddSheet) {
                AddConfigSheet { newConfig in
                    addConfig(newConfig)
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let cfg = configToEdit {
                    EditConfigSheet(config: cfg) { updated in
                        updateConfig(updated)
                    }
                }
            }
            .sheet(isPresented: $showQRScanner) {
                QRCodeScannerView { scannedText in
                    handleScannedText(scannedText)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("NA Tunnel"), message: Text(alertMessage ?? ""), dismissButton: .default(Text("OK")))
            }
            .onAppear(perform: loadData)
        }
    }

    private var filteredConfigs: [VpnConfig] {
        configs.filter { cfg in
            // Search text match
            let matchesSearch = searchText.isEmpty ||
                cfg.name.localizedCaseInsensitiveContains(searchText) ||
                cfg.server.localizedCaseInsensitiveContains(searchText) ||
                cfg.sni.localizedCaseInsensitiveContains(searchText)

            guard matchesSearch else { return false }

            switch selectedFilter {
            case 1: // Metfone / Smart
                let nameLower = cfg.name.lowercased()
                return nameLower.contains("metfone") || nameLower.contains("smart") || cfg.server.contains("129.150.63.107") || cfg.server.contains("152.69.223.67") || cfg.server.contains("172.64.151.167")
            case 2: // Hysteria 2
                return cfg.protocolType == .hysteria2
            case 3: // Custom / Others
                return cfg.subscriptionId == nil
            default:
                return true
            }
        }
    }

    private func loadData() {
        self.configs = StorageService.shared.loadConfigs()
    }

    private func pingSingle(_ config: VpnConfig) {
        PingEngine.ping(host: config.server, port: config.port) { ms in
            if let idx = configs.firstIndex(where: { $0.id == config.id }) {
                configs[idx].pingMs = ms
                StorageService.shared.saveConfigs(configs)
            }
        }
    }

    private func pingAll() {
        guard !isPingingAll else { return }
        isPingingAll = true
        PingEngine.pingAll(configs: configs, onUpdate: { id, ms in
            if let idx = configs.firstIndex(where: { $0.id == id }) {
                configs[idx].pingMs = ms
            }
        }) {
            isPingingAll = false
            StorageService.shared.saveConfigs(configs)
        }
    }

    private func importFromClipboard() {
        guard let text = UIPasteboard.general.string, !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            notifyUser("Clipboard is empty")
            return
        }

        // Try parsing .na format first
        let naResult = NatConfigCrypto.importNat(content: text)
        switch naResult {
        case .success(let config, let msg):
            addConfig(config)
            notifyUser("Successfully imported \(config.name)! \(msg)")
            return
        case .needsPassphrase:
            notifyUser("Encrypted .na configuration requires passphrase")
            return
        case .error:
            break
        }

        // Try parsing single share link or list of share links
        let parsed = V2RayShareLinkParser.parseMultiple(content: text)
        if !parsed.isEmpty {
            for cfg in parsed {
                addConfig(cfg)
            }
            notifyUser("Imported \(parsed.count) server(s) successfully!")
        } else {
            notifyUser("No valid V2Ray, VLESS, or Hysteria 2 configurations found in clipboard")
        }
    }

    private func handleScannedText(_ text: String) {
        if let config = V2RayShareLinkParser.parse(link: text) {
            addConfig(config)
            notifyUser("Successfully imported \(config.name)")
        } else {
            notifyUser("Scanned QR code does not contain a recognized VPN configuration")
        }
    }

    private func addConfig(_ config: VpnConfig) {
        configs.insert(config, at: 0)
        StorageService.shared.saveConfigs(configs)
    }

    private func updateConfig(_ config: VpnConfig) {
        if let idx = configs.firstIndex(where: { $0.id == config.id }) {
            configs[idx] = config
            StorageService.shared.saveConfigs(configs)
            if vpnManager.activeConfig?.id == config.id {
                vpnManager.activeConfig = config
            }
        }
    }

    private func deleteConfig(_ config: VpnConfig) {
        configs.removeAll { $0.id == config.id }
        StorageService.shared.saveConfigs(configs)
        if vpnManager.activeConfig?.id == config.id {
            vpnManager.activeConfig = configs.first
            StorageService.shared.saveActiveConfigId(configs.first?.id)
        }
    }

    private func notifyUser(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
