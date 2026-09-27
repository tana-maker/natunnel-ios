//
//  AddConfigSheet.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct AddConfigSheet: View {
    @Environment(\.presentationMode) var presentationMode
    let onSave: (VpnConfig) -> Void

    @State private var mode: Int = 0 // 0 = Paste Link, 1 = Manual Entry
    @State private var rawLink: String = ""
    @State private var errorMessage: String?

    // Manual Fields
    @State private var name: String = "My Server"
    @State private var protocolType: ProxyProtocol = .vless
    @State private var server: String = ""
    @State private var port: String = "443"
    @State private var uuid: String = ""
    @State private var password: String = ""
    @State private var network: String = "tcp"
    @State private var security: String = "reality"
    @State private var sni: String = ""
    @State private var host: String = ""
    @State private var path: String = "/"
    @State private var publicKey: String = ""
    @State private var shortId: String = ""

    public var body: some View {
        NavigationView {
            ZStack {
                ThemeColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Mode Picker
                        Picker("Input Mode", selection: $mode) {
                            Text("Paste Share Link").tag(0)
                            Text("Manual Entry").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.top)

                        if mode == 0 {
                            // Paste Share Link Section
                            NeonCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("PASTE SHARE LINK")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(ThemeColor.textSecondary)

                                    TextEditor(text: $rawLink)
                                        .frame(height: 120)
                                        .padding(8)
                                        .background(Color(hex: 0x14281C))
                                        .foregroundColor(ThemeColor.textPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ThemeColor.border, lineWidth: 1))

                                    Button(action: {
                                        if let clip = UIPasteboard.general.string {
                                            rawLink = clip
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.on.clipboard")
                                            Text("Paste from Clipboard")
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(ThemeColor.primary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // Manual Input Section
                            NeonCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    CustomTextField(label: "SERVER NAME", text: $name, placeholder: "e.g. SG-VIP-01")

                                    Picker("Protocol", selection: $protocolType) {
                                        ForEach(ProxyProtocol.allCases) { proto in
                                            Text(proto.displayName).tag(proto)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(ThemeColor.primary)

                                    CustomTextField(label: "SERVER HOST / IP", text: $server, placeholder: "e.g. 129.150.63.107")
                                    CustomTextField(label: "PORT", text: $port, placeholder: "443", keyboardType: .numberPad)

                                    if protocolType == .vless || protocolType == .vmess {
                                        CustomTextField(label: "UUID", text: $uuid, placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
                                    }

                                    if protocolType == .hysteria2 || protocolType == .trojan || protocolType == .shadowsocks {
                                        CustomTextField(label: "PASSWORD", text: $password, placeholder: "Auth password")
                                    }

                                    CustomTextField(label: "SNI (BUG HOST)", text: $sni, placeholder: "e.g. www.wechat.com")

                                    if protocolType == .vless {
                                        CustomTextField(label: "WEBSOCKET HOST", text: $host, placeholder: "e.g. na-tunnel.workers.dev")
                                        CustomTextField(label: "WEBSOCKET PATH", text: $path, placeholder: "/vless")
                                        CustomTextField(label: "REALITY PUBLIC KEY", text: $publicKey, placeholder: "Base64 Public Key")
                                        CustomTextField(label: "REALITY SHORT ID", text: $shortId, placeholder: "Short ID")
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        if let err = errorMessage {
                            Text(err)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ThemeColor.disconnected)
                                .padding(.horizontal)
                        }

                        // Save Button
                        Button(action: handleSave) {
                            Text("Save Configuration")
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
            .navigationBarTitle("Add Configuration", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }.foregroundColor(ThemeColor.textSecondary)
            )
        }
    }

    private func handleSave() {
        errorMessage = nil
        if mode == 0 {
            if let config = V2RayShareLinkParser.parse(link: rawLink) {
                onSave(config)
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = "Invalid share link. Supported schemes: vless://, hy2://, trojan://, ss://, vmess://"
            }
        } else {
            guard !server.trimmingCharacters(in: .whitespaces).isEmpty else {
                errorMessage = "Server Host / IP is required"
                return
            }
            let portInt = Int(port) ?? 443
            let config = VpnConfig(
                name: name.isEmpty ? "Custom Server" : name,
                protocolType: protocolType,
                server: server,
                port: portInt,
                uuid: uuid,
                password: password,
                network: network,
                security: security,
                sni: sni,
                host: host,
                path: path,
                publicKey: publicKey,
                shortId: shortId
            )
            onSave(config)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct CustomTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(ThemeColor.textSecondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(10)
                .background(Color(hex: 0x14281C))
                .foregroundColor(ThemeColor.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ThemeColor.border, lineWidth: 1))
        }
    }
}
