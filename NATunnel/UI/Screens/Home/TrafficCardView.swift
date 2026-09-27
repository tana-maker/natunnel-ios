//
//  TrafficCardView.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct TrafficCardView: View {
    let stats: TrafficStats
    let isConnected: Bool

    public var body: some View {
        NeonCard {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    // Download Metric
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(ThemeColor.speedDown)
                                .font(.system(size: 16))
                            Text("DOWNLOAD")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(ThemeColor.textSecondary)
                        }

                        Text(isConnected ? stats.formattedDownloadSpeed : "0 Kbps")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColor.textPrimary)

                        Text("Total: \(stats.formattedTotalDownload)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(ThemeColor.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(hex: 0x14281C).opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Upload Metric
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(ThemeColor.speedUp)
                                .font(.system(size: 16))
                            Text("UPLOAD")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(ThemeColor.textSecondary)
                        }

                        Text(isConnected ? stats.formattedUploadSpeed : "0 Kbps")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColor.textPrimary)

                        Text("Total: \(stats.formattedTotalUpload)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(ThemeColor.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(hex: 0x14281C).opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Session Duration Bar
                if isConnected {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(ThemeColor.primary)

                        Text("Connection Time:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ThemeColor.textSecondary)

                        Text(stats.formattedDuration)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(ThemeColor.primary)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}
