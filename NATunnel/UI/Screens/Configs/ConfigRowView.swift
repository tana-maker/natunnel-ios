//
//  ConfigRowView.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct ConfigRowView: View {
    let config: VpnConfig
    let isSelected: Bool
    let onPing: () -> Void
    let onSelect: () -> Void

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Radio Circle / Checkmark
                ZStack {
                    Circle()
                        .stroke(isSelected ? ThemeColor.primary : ThemeColor.border, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(ThemeColor.primary)
                            .frame(width: 12, height: 12)
                    }
                }

                // Country Flag
                Text(config.flagEmoji)
                    .font(.system(size: 22))

                // Server Details
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(config.name)
                            .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                            .foregroundColor(ThemeColor.textPrimary)
                            .lineLimit(1)

                        ProtocolBadge(protocolType: config.protocolType)
                    }

                    Text(config.routingDescription)
                        .font(.system(size: 11))
                        .foregroundColor(ThemeColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Ping Button / Latency Pill
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onPing()
                }) {
                    PingBadge(pingMs: config.pingMs)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(isSelected ? ThemeColor.card : Color(hex: 0x14281C).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? ThemeColor.primary.opacity(0.6) : ThemeColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
