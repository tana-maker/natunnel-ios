//
//  Colors.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct ThemeColor {
    // Deep Forest Slate Dark Palette (matching NA Tunnel Android)
    public static let background = Color(hex: 0x0A140E)
    public static let surface = Color(hex: 0x112217)
    public static let surfaceVariant = Color(hex: 0x172E20)
    public static let card = Color(hex: 0x1D3828)
    public static let cardSecondary = Color(hex: 0x14281C)
    public static let border = Color(hex: 0x264934)
    public static let borderLight = Color(hex: 0x366348)

    // Vibrant Neon Accents
    public static let primary = Color(hex: 0x4ADE80)          // Neon Mint
    public static let primaryDark = Color(hex: 0x15803D)      // Forest Green
    public static let primaryGlow = Color(hex: 0x22C55E)      // Bright Glow
    public static let accentAmber = Color(hex: 0xF59E0B)      // Amber Orange (Hysteria)
    public static let accentSky = Color(hex: 0x38BDF8)        // Sky Blue (Upload)

    // Status Colors
    public static let connected = Color(hex: 0x16A34A)
    public static let disconnected = Color(hex: 0xEF4444)
    public static let connecting = Color(hex: 0xEA580C)
    public static let speedDown = Color(hex: 0x059669)
    public static let speedUp = Color(hex: 0x0284C7)

    // Text & Content
    public static let textPrimary = Color(hex: 0xE8F5E9)
    public static let textSecondary = Color(hex: 0x98C1A5)
    public static let textMuted = Color(hex: 0x628C70)

    // Gradients
    public static let cardGradient = LinearGradient(
        colors: [Color(hex: 0x193323), Color(hex: 0x122419)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let buttonConnectedGradient = LinearGradient(
        colors: [Color(hex: 0x22C55E), Color(hex: 0x15803D)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let buttonDisconnectedGradient = LinearGradient(
        colors: [Color(hex: 0x274332), Color(hex: 0x1B3024)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let buttonConnectingGradient = LinearGradient(
        colors: [Color(hex: 0xEA580C), Color(hex: 0xC2410C)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    public init(hex: Int, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255.0,
            green: Double((hex >> 8) & 0xff) / 255.0,
            blue: Double(hex & 0xff) / 255.0,
            opacity: alpha
        )
    }

    public init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255.0,
            green: Double((hex >> 8) & 0xff) / 255.0,
            blue: Double(hex & 0xff) / 255.0,
            opacity: alpha
        )
    }

    public init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
