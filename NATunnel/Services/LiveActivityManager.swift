//
//  LiveActivityManager.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

/// Controls iOS 16.2+ Live Activity & Dynamic Island lifecycle for NA Tunnel
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private var currentActivity: Activity<NATunnelActivityAttributes>? {
        return Activity<NATunnelActivityAttributes>.activities.first
    }
    #endif

    private init() {}

    /// Starts a Live Activity widget showing the active node and speeds
    public func startLiveActivity(serverName: String, protocolName: String, flag: String, pingMs: Int64 = 0) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            NSLog("[LiveActivity] Activities are disabled by user or system.")
            return
        }

        // Clean up any stale activities before spawning
        endLiveActivity()

        let attributes = NATunnelActivityAttributes(
            serverName: serverName,
            protocolName: protocolName,
            flag: flag
        )
        let initialContentState = NATunnelActivityAttributes.ContentState(
            status: "CONNECTED",
            downloadSpeed: "0 Kbps",
            uploadSpeed: "0 Kbps",
            totalData: "0 MB",
            duration: "00:00:00",
            serverName: serverName,
            pingMs: pingMs
        )

        do {
            let activity = try Activity<NATunnelActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: nil
            )
            NSLog("[LiveActivity] Started Live Activity ID: %@", activity.id)
        } catch {
            NSLog("[LiveActivity] Failed to start Live Activity: %@", error.localizedDescription)
        }
        #endif
    }

    /// Pushes updated traffic speeds, duration, and metrics to Dynamic Island and Lock Screen
    public func updateLiveActivity(
        downloadSpeed: String,
        uploadSpeed: String,
        totalData: String,
        duration: String,
        serverName: String,
        pingMs: Int64
    ) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        guard let activity = currentActivity else { return }

        let updatedState = NATunnelActivityAttributes.ContentState(
            status: "CONNECTED",
            downloadSpeed: downloadSpeed,
            uploadSpeed: uploadSpeed,
            totalData: totalData,
            duration: duration,
            serverName: serverName,
            pingMs: pingMs
        )

        Task {
            await activity.update(
                ActivityContent<NATunnelActivityAttributes.ContentState>(
                    state: updatedState,
                    staleDate: Date().addingTimeInterval(15)
                )
            )
        }
        #endif
    }

    /// Dismisses the Live Activity when VPN is disconnected
    public func endLiveActivity() {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else { return }
        for activity in Activity<NATunnelActivityAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        #endif
    }
}
