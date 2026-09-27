//
//  ConnectionButton.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct ConnectionButton: View {
    let status: VpnStatus
    let action: () -> Void

    @State private var isPulsing = false
    @State private var isPressed = false

    public init(status: VpnStatus, action: @escaping () -> Void) {
        self.status = status
        self.action = action
    }

    public var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            ZStack {
                // Outer Pulsing Ripple Rings (when connected or connecting)
                if status == .connected || status == .connecting {
                    Circle()
                        .stroke(ringColor.opacity(0.35), lineWidth: 2)
                        .frame(width: 220, height: 220)
                        .scaleEffect(isPulsing ? 1.15 : 0.95)
                        .opacity(isPulsing ? 0.0 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 1.8)
                                .repeatForever(autoreverses: false),
                            value: isPulsing
                        )

                    Circle()
                        .stroke(ringColor.opacity(0.2), lineWidth: 3)
                        .frame(width: 245, height: 245)
                        .scaleEffect(isPulsing ? 1.25 : 0.9)
                        .opacity(isPulsing ? 0.0 : 0.6)
                        .animation(
                            Animation.easeInOut(duration: 2.2)
                                .repeatForever(autoreverses: false)
                                .delay(0.4),
                            value: isPulsing
                        )
                }

                // Middle Glow Ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [ringColor.opacity(0.6), ringColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 180, height: 180)
                    .shadow(color: ringColor.opacity(0.5), radius: 15, x: 0, y: 0)

                // Main Circular Button
                Circle()
                    .fill(buttonGradient)
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 14, x: 0, y: 8)

                // Center Icon and Status
                VStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(iconColor)
                        .rotationEffect(.degrees(status == .connecting ? 360 : 0))
                        .animation(
                            status == .connecting ?
                                Animation.linear(duration: 1.5).repeatForever(autoreverses: false) :
                                .default,
                            value: status
                        )

                    Text(buttonSubtext)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(iconColor)
                        .tracking(1.2)
                }
            }
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            isPulsing = true
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var buttonGradient: LinearGradient {
        switch status {
        case .connected:
            return ThemeColor.buttonConnectedGradient
        case .connecting, .disconnecting:
            return ThemeColor.buttonConnectingGradient
        case .disconnected:
            return ThemeColor.buttonDisconnectedGradient
        }
    }

    private var ringColor: Color {
        switch status {
        case .connected:
            return ThemeColor.primaryGlow
        case .connecting, .disconnecting:
            return ThemeColor.connecting
        case .disconnected:
            return ThemeColor.border
        }
    }

    private var iconName: String {
        switch status {
        case .connected:
            return "checkmark.shield.fill"
        case .connecting, .disconnecting:
            return "arrow.triangle.2.circlepath"
        case .disconnected:
            return "power"
        }
    }

    private var iconColor: Color {
        switch status {
        case .connected:
            return Color(hex: 0x052E16)
        case .connecting, .disconnecting:
            return Color.white
        case .disconnected:
            return ThemeColor.primary
        }
    }

    private var buttonSubtext: String {
        switch status {
        case .connected:
            return "PROTECTED"
        case .connecting:
            return "STARTING..."
        case .disconnecting:
            return "STOPPING..."
        case .disconnected:
            return "TAP TO CONNECT"
        }
    }
}
