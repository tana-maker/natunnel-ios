//
//  EditConfigSheet.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct EditConfigSheet: View {
    @Environment(\.presentationMode) var presentationMode
    let initialConfig: VpnConfig
    let onSave: (VpnConfig) -> Void

    @State private var config: VpnConfig

    public init(config: VpnConfig, onSave: @escaping (VpnConfig) -> Void) {
        self.initialConfig = config
        self._config = State(initialValue: config)
        self.onSave = onSave
    }

    public var body: some View {
        NavigationView {
            ZStack {
                ThemeColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        NeonCard {
                            VStack(alignment: .leading, spacing: 14) {
                                CustomTextField(label: "SERVER NAME", text: $config.name)

                                HStack(spacing: 12) {
                                    CustomTextField(label: "SERVER HOST / IP", text: $config.server)
                                    CustomTextField(
                                        label: "PORT",
                                        text: Binding(
                                            get: { "\(config.port)" },
                                            set: { config.port = Int($0) ?? config.port }
                                        ),
                                        keyboardType: .numberPad
                                    )
                                    .frame(width: 80)
                                }

                                if config.protocolType == .vless || config.protocolType == .vmess {
                                    CustomTextField(label: "UUID", text: $config.uuid)
                                }

                                if config.protocolType == .hysteria2 || config.protocolType == .trojan || config.protocolType == .shadowsocks {
                                    CustomTextField(label: "PASSWORD", text: $config.password)
                                }

                                CustomTextField(label: "SNI (BUG HOST)", text: $config.sni)

                                if config.protocolType == .vless {
                                    CustomTextField(label: "WEBSOCKET HOST", text: $config.host)
                                    CustomTextField(label: "WEBSOCKET PATH", text: $config.path)
                                    CustomTextField(label: "REALITY PUBLIC KEY", text: $config.publicKey)
                                    CustomTextField(label: "REALITY SHORT ID", text: $config.shortId)
                                }

                                Toggle("Allow Insecure (Skip TLS Verify)", isOn: $config.allowInsecure)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(ThemeColor.textPrimary)
                                    .tint(ThemeColor.primary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)

                        Button(action: {
                            onSave(config)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: 0x052E16))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(ThemeColor.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationBarTitle("Edit Server", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }.foregroundColor(ThemeColor.textSecondary)
            )
        }
    }
}
