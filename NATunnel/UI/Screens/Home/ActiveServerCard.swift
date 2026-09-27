//
//  ActiveServerCard.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct ActiveServerCard: View {
    let config: VpnConfig?
    let onTap: () -> Void

    public var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap()
        }) {
            NeonCard {
                HStack(spacing: 14) {
                    // Flag Container
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: 0x14281C))
                            .frame(width: 48, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ThemeColor.border, lineWidth: 1)
                            )

                        Text(config?.flagEmoji ?? "🌐")
                            .font(.system(size: 26))
                    }

                    // Server Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(config?.name ?? "Select Server")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(ThemeColor.textPrimary)
                                .lineLimit(1)

                            if let proto = config?.protocolType {
                                ProtocolBadge(protocolType: proto)
                            }
                        }

                        Text(config?.routingDescription ?? "Tap to choose a node")
                            .font(.system(size: 12))
                            .foregroundColor(ThemeColor.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Ping Latency & Chevron
                    VStack(alignment: .trailing, spacing: 6) {
                        PingBadge(pingMs: config?.pingMs ?? 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ThemeColor.textMuted)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
