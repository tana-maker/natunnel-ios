//
//  SecurityManager.swift
//  NATunnel
//
//  Advanced Anti-Tamper, Anti-Jailbreak, Anti-Debugging, and Memory Protection
//

import Foundation
import UIKit
import MachO

public struct SecurityStatus {
    public let isJailbroken: Bool
    public let isDebuggerAttached: Bool
    public let isHookingDetected: Bool
    public let isTampered: Bool

    public var isAllowedToRun: Bool {
        return !isJailbroken && !isDebuggerAttached && !isHookingDetected && !isTampered
    }
}

public final class SecurityManager {
    public static let shared = SecurityManager()

    private init() {}

    // MARK: - Jailbreak Detection
    public func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // 1. Filesystem check
        let suspiciousPaths = [
            "/Applications/Cydia.app",
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/usr/bin/ssh",
            "/usr/libexec/sftp-server",
            "/var/binpack",
            "/var/jb"
        ]

        for path in suspiciousPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // 2. Writable system directory check
        let testPath = "/private/jailbreak_sentinel_\(UUID().uuidString).txt"
        do {
            try "sentinel".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            // Expected to fail on stock iOS
        }

        // 3. Symbolic link check
        let symlinks = [
            "/Applications",
            "/var/stash/Library/Ringtones",
            "/var/stash/Library/Wallpaper",
            "/var/stash/usr/include",
            "/var/stash/usr/share"
        ]
        for link in symlinks {
            if let dest = try? FileManager.default.destinationOfSymbolicLink(atPath: link), !dest.isEmpty {
                return true
            }
        }

        // 4. URL scheme check
        let suspiciousSchemes = ["cydia://", "sileo://", "zbra://", "undecimus://"]
        for scheme in suspiciousSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                return true
            }
        }

        return false
        #endif
    }

    // MARK: - Anti-Debugging (sysctl & ptrace)
    public func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        if junk == 0 {
            return (info.kp_proc.p_flag & P_TRACED) != 0
        }
        return false
    }

    public func denyDebuggerAttach() {
        #if !DEBUG
        typealias PtraceType = @convention(c) (Int32, pid_t, caddr_t?, Int32) -> Int32
        let PT_DENY_ATTACH: Int32 = 31
        let handle = dlopen(nil, RTLD_GLOBAL | RTLD_NOW)
        if let sym = dlsym(handle, "ptrace") {
            let ptrace = unsafeBitCast(sym, to: PtraceType.self)
            _ = ptrace(PT_DENY_ATTACH, 0, nil, 0)
        }
        #endif
    }

    // MARK: - Dynamic Library & Hooking Detection (Frida, Substrate, Cycript)
    public func isHookingDetected() -> Bool {
        let suspiciousLibraries = [
            "frida",
            "fridadetect",
            "frida-gadget",
            "cydiasubstrate",
            "mobilesubstrate",
            "cycript",
            "sslunpinning",
            "shadow",
            "libhooker"
        ]

        let count = _dyld_image_count()
        for i in 0..<count {
            if let cName = _dyld_get_image_name(i) {
                let name = String(cString: cName).lowercased()
                for sus in suspiciousLibraries {
                    if name.contains(sus) {
                        return true
                    }
                }
            }
        }

        return false
    }

    // MARK: - Overall Security Verification
    public func checkSecurity() -> SecurityStatus {
        let jb = isJailbroken()
        let dbg = isDebuggerAttached()
        let hook = isHookingDetected()
        let tampered = jb || dbg || hook

        return SecurityStatus(
            isJailbroken: jb,
            isDebuggerAttached: dbg,
            isHookingDetected: hook,
            isTampered: tampered
        )
    }
}

