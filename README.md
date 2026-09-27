# 🌐 NA Tunnel for iOS

**NA Tunnel for iOS** is a high-speed, secure, next-generation proxy and VPN client built natively for iOS using **Swift**, **SwiftUI**, Apple's **NetworkExtension** (`NEPacketTunnelProvider`), and the **Sing-box (`libbox`)** high-performance Go core.

It brings the complete feature set, sleek cyberpunk aesthetic, and zero-rated bypass capabilities of the Android NA Tunnel app to iPhone and iPad users.

---

## 🚀 Key Features

* **⚡ Protocol Support:**
  * **VLESS:** WebSocket with Clean IP injection (`172.64.151.167:80`), TLS, and **XTLS-Reality** with Chrome uTLS fingerprinting.
  * **Hysteria 2:** High-speed QUIC over UDP (Port 443) with Salamander obfuscation.
  * **Trojan:** Standard TLS and WebSocket.
  * **Shadowsocks:** AEAD ciphers (`aes-256-gcm`, `chacha20-poly1305`).
  * **VMess:** WebSocket and TLS.

* **🇰🇭 Pre-loaded Official Cambodian Carrier Presets:**
  * **Metfone $0 Balance Node 1:** Port 80 WebSocket Clean IP reverse-proxy (`na-tunnel.hakrortanabun1.workers.dev`).
  * **Metfone $0 Balance Node 2:** Backup Port 80 WebSocket proxy.
  * **Smart Axiata VIP 01 & 02:** Port 443 VLESS Reality (`www.wechat.com` bug host).
  * **Smart High-Speed Gaming:** Hysteria 2 UDP low-jitter node for Mobile Legends and streaming.
  * **Smart Digital Learning:** `onesala.com` zero-rated pack node.

* **📱 Native iOS Experience:**
  * **SwiftUI Design System:** Dark Forest Slate (`#0A140E`) + Neon Mint (`#4ADE80`) palette, glowing animated power button with pulsating radar rings.
  * **Live Traffic Gauge:** Real-time upload and download throughput (Kbps / Mbps), session byte totals, and connection duration timer.
  * **Speedometer Gauge:** Built-in speed test measuring Ping, Jitter, Download, and Upload speeds.
  * **Smart Connect:** Automatic latency pinging to auto-route through the fastest node.
  * **Gaming Mode:** Low-jitter UDP optimization toggle.
  * **Subcription Manager:** Auto-sync remote V2Ray / Sing-box subscription links.
  * **Import & Export:**
    * QR Code scanning with live camera viewfinder (`AVFoundation`).
    * Clipboard import for `vless://`, `hy2://`, `trojan://`, `ss://`, `vmess://`.
    * Encrypted `.na` and `.nat` JSON envelope import/export with AES-256-GCM and Master Key support.
  * **Live Console Logs:** Real-time Sing-box tunnel logs with level filtering (`INFO`, `WARN`, `ERROR`).

---

## 🏗️ Project Architecture

```text
IOS/
├── NATunnel.xcodeproj/
│   ├── project.pbxproj                           # Multi-target Xcode project configuration
│   └── xcshareddata/xcschemes/NATunnel.xcscheme # Shared build scheme
├── NATunnel/                                     # Main SwiftUI Application
│   ├── App/
│   │   ├── NATunnelApp.swift                    # SwiftUI @main entry point
│   │   └── AppDelegate.swift                    # Background fetch & URL scheme handling
│   ├── Models/
│   │   ├── ProxyProtocol.swift                  # VLESS, HY2, Trojan, SS, VMess enums
│   │   ├── VpnConfig.swift                      # Server configuration model with flags & routing
│   │   ├── UserSettings.swift                   # DNS, routing modes, MTU, auto-connect
│   │   ├── TrafficStats.swift                   # Real-time speed and byte formatters
│   │   ├── SubscriptionItem.swift               # Remote subscription URL model
│   │   ├── SpeedTestResult.swift                # Speed test metrics model
│   │   └── LogEntry.swift                       # Colored log entry model
│   ├── Core/
│   │   ├── SingboxConfigGenerator.swift         # Generates JSON config for Sing-box engine
│   │   ├── V2RayShareLinkParser.swift           # Parser for vless://, hy2://, trojan://, etc.
│   │   ├── NatConfigCrypto.swift                # AES-256-GCM .na/.nat envelope crypto
│   │   ├── VpnManager.swift                     # NETunnelProviderManager controller
│   │   ├── PingEngine.swift                     # Millisecond TCP/ICMP latency tester
│   │   └── SpeedTestEngine.swift                # Async multi-stream speed tester
│   ├── Services/
│   │   ├── StorageService.swift                 # AppGroup shared storage & defaults
│   │   ├── SubscriptionService.swift            # Remote subscription downloader
│   │   └── NetworkMonitor.swift                 # NWPathMonitor Wi-Fi/Cellular tracker
│   ├── UI/
│   │   ├── Theme/
│   │   │   ├── Colors.swift                     # Neon Mint & Dark Slate design tokens
│   │   │   └── Components.swift                 # NeonCard, StatusBadge, ProtocolBadge, PingBadge
│   │   └── Screens/
│   │       ├── MainTabView.swift                # Bottom navigation bar
│   │       ├── Home/                            # Home screen with glowing power button
│   │       ├── Configs/                         # Server manager, QR scanner, add/edit sheets
│   │       ├── Subscriptions/                   # Remote subscription manager
│   │       ├── SpeedTest/                       # Speedometer gauge screen
│   │       ├── Settings/                        # DNS, routing, MTU, and diagnostics
│   │       └── Logs/                            # Live console logs screen
│   └── Resources/
│       ├── Info.plist                           # Camera & background permissions
│       ├── NATunnel.entitlements                # App Group & NetworkExtension entitlements
│       └── Assets.xcassets/                     # App icons & AccentColor
├── NATunnelPacketTunnel/                         # iOS NetworkExtension Target
│   ├── PacketTunnelProvider.swift               # NEPacketTunnelProvider implementation
│   ├── SingboxTunnelRunner.swift                # Sing-box (libbox) packet loop runner
│   ├── Info.plist                               # Extension plist
│   └── NATunnelPacketTunnel.entitlements        # Extension entitlements
├── Scripts/
│   └── download_libbox.sh                       # Downloads precompiled Libbox.xcframework
├── .github/
│   └── workflows/
│       └── ios-build.yml                        # GitHub Actions CI/CD to build .ipa
└── README.md
```

---

## 🛠️ How to Build and Deploy

### Option 1: Cloud Build via GitHub Actions (No Mac Needed! 🚀)

You can build the ready-to-install `.ipa` directly in the cloud using GitHub's macOS runners:

1. Push this repository to GitHub.
2. Go to the **Actions** tab in your GitHub repository.
3. Select the **Build NA Tunnel iOS (.ipa)** workflow and click **Run workflow**.
4. Once completed (approx. 3–5 minutes), download `NATunnel-iOS-v1.3.2.zip` from the **Artifacts** section.
5. Extract the `.ipa` file.

#### Sideloading the `.ipa` on your iPhone / iPad:
* **[Sideloadly](https://sideloadly.io/) (Windows & Mac):** Drag and drop the `.ipa`, enter your Apple ID, and click **Start**.
* **[AltStore](https://altstore.io/):** Send the `.ipa` to your iPhone and install via AltStore.
* **[TrollStore](https://github.com/opa334/TrollStore) (Jailbroken / Supported iOS versions):** Open `.ipa` directly in TrollStore for permanent installation with no 7-day expiration.

---

### Option 2: Build Locally on macOS (Xcode)

1. Clone or copy the `IOS` folder to your Mac.
2. Open terminal in the `IOS` directory and fetch the Sing-box core:
   ```bash
   chmod +x Scripts/download_libbox.sh
   ./Scripts/download_libbox.sh
   ```
3. Open `NATunnel.xcodeproj` in Xcode 15 or 16:
   ```bash
   open NATunnel.xcodeproj
   ```
4. In Xcode, select the **NATunnel** target:
   * Go to **Signing & Capabilities**.
   * Select your **Apple Developer Team**.
   * Xcode will automatically provision the App ID and NetworkExtension entitlements.
5. Connect your iPhone via USB, select your device in the top bar, and press **Cmd + R** (Run)!

---

## 🔒 Security & Privacy

* **App Group Sandbox:** Configurations and traffic metrics are strictly isolated within the secure `group.com.natunnel.ios` app group container.
* **Zero Telemetry:** The app connects directly to your chosen VPS nodes without any third-party analytics or external trackers.
* **Anti-DNS Leak:** Integrated Cloudflare DoH (`1.1.1.1`) and Google DoH (`8.8.8.8`) ensure your ISP cannot monitor or hijack DNS queries.
