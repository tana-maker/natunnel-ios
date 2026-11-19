//
//  NATunnelActivityWidget.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

#if canImport(WidgetKit) && canImport(ActivityKit)
import WidgetKit
import ActivityKit

public struct NATunnelActivityWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: NATunnelActivityAttributes.self) { context in
            // Lock Screen / Standby Banner presentation
            NATunnelLockScreenLiveView(context: context)
        } dynamicIsland: { context in
            // iPhone 14 Pro / 15 / 16 Dynamic Island presentation
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Text(context.attributes.flag)
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.serverName.isEmpty ? context.attributes.serverName : context.state.serverName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(ThemeColor.textPrimary)
                                .lineLimit(1)
                            Text(context.attributes.protocolName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(ThemeColor.primary)
                        }
                    }
                    .padding(.leading, 4)
                }

                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(ThemeColor.primary)
                                .frame(width: 7, height: 7)
                            Text(context.state.status)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(ThemeColor.primary)
                        }
                        if context.state.pingMs > 0 {
                            Text("\(context.state.pingMs) ms")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(ThemeColor.textSecondary)
                        }
                    }
                    .padding(.trailing, 4)
                }

                // Expanded Center / Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(alignment: .center, spacing: 14) {
                        // Download Speed
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(ThemeColor.primary)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("DOWN")
                                    .font(.system(size: 8, weight: .heavy))
                                    .foregroundColor(ThemeColor.textMuted)
                                Text(context.state.downloadSpeed)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(ThemeColor.primary)
                            }
                        }

                        Divider()
                            .frame(height: 24)
                            .background(ThemeColor.border)

                        // Upload Speed
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(ThemeColor.accentSky)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("UP")
                                    .font(.system(size: 8, weight: .heavy))
                                    .foregroundColor(ThemeColor.textMuted)
                                Text(context.state.uploadSpeed)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(ThemeColor.accentSky)
                            }
                        }

                        Spacer()

                        // Session Duration & Byte totals
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(context.state.duration)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(ThemeColor.textPrimary)
                            Text(context.state.totalData)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(ThemeColor.textSecondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Pill Leading
                HStack(spacing: 4) {
                    Text(context.attributes.flag)
                        .font(.system(size: 12))
                    Circle()
                        .fill(ThemeColor.primary)
                        .frame(width: 5, height: 5)
                }
            } compactTrailing: {
                // Pill Trailing: Live Download Speed
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ThemeColor.primary)
                    Text(context.state.downloadSpeed)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(ThemeColor.primary)
                }
            } minimal: {
                // Minimal Dot
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 11))
                    .foregroundColor(ThemeColor.primary)
            }
        }
    }
}

// MARK: - Lock Screen Banner Presentation
private struct NATunnelLockScreenLiveView: View {
    let context: ActivityViewContext<NATunnelActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Header: Flag, Name, Status, Protocol
            HStack(spacing: 10) {
                Text(context.attributes.flag)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.serverName.isEmpty ? context.attributes.serverName : context.state.serverName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ThemeColor.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(context.attributes.protocolName)
                            .font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ThemeColor.surfaceVariant)
                            .cornerRadius(4)
                            .foregroundColor(ThemeColor.primary)

                        if context.state.pingMs > 0 {
                            Text("\(context.state.pingMs) ms")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(ThemeColor.textSecondary)
                        }
                    }
                }

                Spacer()

                // Status Pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(ThemeColor.primary)
                        .frame(width: 7, height: 7)
                    Text("PROTECTED")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(ThemeColor.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ThemeColor.primary.opacity(0.12))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ThemeColor.primary.opacity(0.3), lineWidth: 1)
                )
            }

            // Divider
            Rectangle()
                .fill(ThemeColor.border)
                .frame(height: 1)

            // Metrics Row
            HStack(spacing: 16) {
                // Download
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ThemeColor.primary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("DOWNLOAD")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(ThemeColor.textMuted)
                        Text(context.state.downloadSpeed)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColor.primary)
                    }
                }

                // Upload
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ThemeColor.accentSky)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("UPLOAD")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(ThemeColor.textMuted)
                        Text(context.state.uploadSpeed)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColor.accentSky)
                    }
                }

                Spacer()

                // Duration & Total Transferred
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.duration)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(ThemeColor.textPrimary)
                    Text("Total: \(context.state.totalData)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ThemeColor.textSecondary)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [ThemeColor.background, ThemeColor.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ThemeColor.borderLight, lineWidth: 1)
        )
    }
}
#endif
