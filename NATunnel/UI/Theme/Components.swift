//
//  Components.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct NeonCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding()
            .background(ThemeColor.cardGradient)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(ThemeColor.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
    }
}

public struct ProtocolBadge: View {
    let protocolType: ProxyProtocol

    public var body: some View {
        Text(protocolType.displayName)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hexString: protocolType.badgeColorHex))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(hexString: protocolType.badgeColorHex).opacity(0.15))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hexString: protocolType.badgeColorHex).opacity(0.4), lineWidth: 1)
            )
    }
}

public struct PingBadge: View {
    let pingMs: Int64

    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(pingColor)
                .frame(width: 7, height: 7)

            if pingMs > 0 {
                Text("\(pingMs) ms")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(pingColor)
            } else if pingMs == -1 {
                Text("Timeout")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ThemeColor.disconnected)
            } else {
                Text("-- ms")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(ThemeColor.textMuted)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(pingColor.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(pingColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var pingColor: Color {
        if pingMs <= 0 { return ThemeColor.textMuted }
        if pingMs < 100 { return ThemeColor.connected }
        if pingMs < 250 { return ThemeColor.accentAmber }
        return ThemeColor.disconnected
    }
}

public struct StatusBadge: View {
    let status: VpnStatus

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusColor, radius: 4)

            Text(status.displayText)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(statusColor.opacity(0.4), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch status {
        case .connected: return ThemeColor.connected
        case .connecting, .disconnecting: return ThemeColor.connecting
        case .disconnected: return ThemeColor.disconnected
        }
    }
}
