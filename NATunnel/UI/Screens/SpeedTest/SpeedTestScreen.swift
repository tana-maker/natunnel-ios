//
//  SpeedTestScreen.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct SpeedTestScreen: View, SpeedTestDelegate {
    @ObservedObject var vpnManager = VpnManager.shared

    @State private var isTesting = false
    @State private var currentDownloadMbps: Double = 0.0
    @State private var currentUploadMbps: Double = 0.0
    @State private var pingMs: Double = 0.0
    @State private var jitterMs: Double = 0.0
    @State private var testProgress: Double = 0.0
    @State private var statusText: String = "Ready to test"
    @State private var testResult: SpeedTestResult?

    private let engine = SpeedTestEngine()

    public var body: some View {
        NavigationView {
            ZStack {
                ThemeColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Current Server Banner
                        NeonCard {
                            HStack(spacing: 12) {
                                Text(vpnManager.activeConfig?.flagEmoji ?? "🌐")
                                    .font(.system(size: 28))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("TESTING NODE")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(ThemeColor.textSecondary)

                                    Text(vpnManager.activeConfig?.name ?? "Default Routing")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(ThemeColor.textPrimary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if vpnManager.status == .connected {
                                    Text("VPN ON")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(ThemeColor.connected)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(ThemeColor.connected.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Circular Speedometer Gauge
                        ZStack {
                            // Background Arc
                            Circle()
                                .trim(from: 0.15, to: 0.85)
                                .stroke(ThemeColor.border, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                                .frame(width: 240, height: 240)
                                .rotationEffect(.degrees(90))

                            // Colored Gauge Progress Arc
                            Circle()
                                .trim(from: 0.15, to: 0.15 + (0.7 * min(1.0, currentGaugeValue / 100.0)))
                                .stroke(
                                    LinearGradient(
                                        colors: [ThemeColor.primary, ThemeColor.accentAmber, ThemeColor.speedUp],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                                )
                                .frame(width: 240, height: 240)
                                .rotationEffect(.degrees(90))
                                .animation(.easeOut(duration: 0.3), value: currentGaugeValue)

                            // Digital Readout
                            VStack(spacing: 4) {
                                Text(statusText.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(ThemeColor.textSecondary)

                                Text(String(format: "%.1f", currentGaugeValue))
                                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                                    .foregroundColor(ThemeColor.textPrimary)

                                Text("Mbps")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(ThemeColor.primary)
                            }
                        }
                        .padding(.vertical, 8)

                        // Metrics 2x2 Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricBox(
                                title: "DOWNLOAD",
                                value: String(format: "%.1f", currentDownloadMbps),
                                unit: "Mbps",
                                icon: "arrow.down.circle.fill",
                                color: ThemeColor.speedDown
                            )

                            MetricBox(
                                title: "UPLOAD",
                                value: String(format: "%.1f", currentUploadMbps),
                                unit: "Mbps",
                                icon: "arrow.up.circle.fill",
                                color: ThemeColor.speedUp
                            )

                            MetricBox(
                                title: "PING",
                                value: String(format: "%.0f", pingMs),
                                unit: "ms",
                                icon: "bolt.fill",
                                color: ThemeColor.accentAmber
                            )

                            MetricBox(
                                title: "JITTER",
                                value: String(format: "%.0f", jitterMs),
                                unit: "ms",
                                icon: "waveform.path.ecg",
                                color: ThemeColor.primary
                            )
                        }
                        .padding(.horizontal)

                        // Start / Stop Button
                        Button(action: toggleTest) {
                            HStack(spacing: 8) {
                                Image(systemName: isTesting ? "stop.fill" : "play.fill")
                                Text(isTesting ? "Stop Test" : "Start Speed Test")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(isTesting ? .white : Color(hex: 0x052E16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(isTesting ? ThemeColor.disconnected : ThemeColor.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: (isTesting ? ThemeColor.disconnected : ThemeColor.primary).opacity(0.4), radius: 10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarTitle("Speed Test", displayMode: .inline)
            .onAppear {
                engine.delegate = self
            }
        }
    }

    private var currentGaugeValue: Double {
        if currentDownloadMbps > 0 { return currentDownloadMbps }
        if currentUploadMbps > 0 { return currentUploadMbps }
        return 0.0
    }

    private func toggleTest() {
        if isTesting {
            engine.cancel()
            isTesting = false
            statusText = "Cancelled"
        } else {
            isTesting = true
            currentDownloadMbps = 0.0
            currentUploadMbps = 0.0
            pingMs = 0.0
            jitterMs = 0.0
            statusText = "Testing Latency..."
            engine.startTest(serverName: vpnManager.activeConfig?.name ?? "Singapore Node")
        }
    }

    // MARK: - SpeedTestDelegate
    public func speedTestDidUpdatePing(pingMs: Double, jitterMs: Double) {
        self.pingMs = pingMs
        self.jitterMs = jitterMs
        self.statusText = "Testing Download..."
    }

    public func speedTestDidUpdateDownload(currentMbps: Double, progress: Double) {
        self.currentDownloadMbps = currentMbps
        self.statusText = "Downloading..."
    }

    public func speedTestDidUpdateUpload(currentMbps: Double, progress: Double) {
        self.currentUploadMbps = currentMbps
        self.statusText = "Uploading..."
    }

    public func speedTestDidComplete(result: SpeedTestResult) {
        self.isTesting = false
        self.testResult = result
        self.statusText = "Complete"
    }

    public func speedTestDidFail(error: String) {
        self.isTesting = false
        self.statusText = "Failed: \(error)"
    }
}

struct MetricBox: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 13))

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(ThemeColor.textSecondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(ThemeColor.textPrimary)

                Text(unit)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ThemeColor.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(hex: 0x14281C).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ThemeColor.border, lineWidth: 1))
    }
}
