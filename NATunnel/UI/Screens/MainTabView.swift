//
//  MainTabView.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public enum TabItem: Int, CaseIterable {
    case home = 0
    case servers = 1
    case subscriptions = 2
    case speedTest = 3
    case settings = 4

    var title: String {
        switch self {
        case .home: return "Home"
        case .servers: return "Servers"
        case .subscriptions: return "Sync"
        case .speedTest: return "Speed"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "bolt.shield.fill"
        case .servers: return "server.rack"
        case .subscriptions: return "arrow.triangle.2.circlepath.circle.fill"
        case .speedTest: return "gauge.with.needle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MainTabView: View {
    @State private var selectedTab: TabItem = .home

    public init() {
        // Customize default iOS tab bar appearance
        UITabBar.appearance().backgroundColor = UIColor(Color(hex: 0x0A140E))
        UITabBar.appearance().barTintColor = UIColor(Color(hex: 0x0A140E))
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color(hex: 0x628C70))
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem {
                    Label(TabItem.home.title, systemImage: TabItem.home.iconName)
                }
                .tag(TabItem.home)

            ConfigsScreen()
                .tabItem {
                    Label(TabItem.servers.title, systemImage: TabItem.servers.iconName)
                }
                .tag(TabItem.servers)

            SubscriptionScreen()
                .tabItem {
                    Label(TabItem.subscriptions.title, systemImage: TabItem.subscriptions.iconName)
                }
                .tag(TabItem.subscriptions)

            SpeedTestScreen()
                .tabItem {
                    Label(TabItem.speedTest.title, systemImage: TabItem.speedTest.iconName)
                }
                .tag(TabItem.speedTest)

            SettingsScreen()
                .tabItem {
                    Label(TabItem.settings.title, systemImage: TabItem.settings.iconName)
                }
                .tag(TabItem.settings)
        }
        .accentColor(ThemeColor.primary)
    }
}
