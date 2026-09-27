//
//  LogsScreen.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct LogsScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var logs: [LogEntry] = []
    @State private var selectedLevel: String = "ALL"
    @State private var searchText: String = ""

    public var body: some View {
        NavigationView {
            ZStack {
                ThemeColor.background.ignoresSafeArea()

                VStack(spacing: 10) {
                    // Filter Picker
                    Picker("Log Level", selection: $selectedLevel) {
                        Text("ALL").tag("ALL")
                        Text("INFO").tag("INFO")
                        Text("WARN").tag("WARN")
                        Text("ERROR").tag("ERROR")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 4)

                    // Logs Scroll View
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            if filteredLogs.isEmpty {
                                Text("No logs recorded yet.")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(ThemeColor.textMuted)
                                    .padding()
                            } else {
                                ForEach(filteredLogs) { entry in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text(entry.formattedTime)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(ThemeColor.textMuted)

                                        Text("[\(entry.level.rawValue)]")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color(hexString: entry.level.colorHex))

                                        Text(entry.message)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(ThemeColor.textPrimary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(hex: 0x050C07))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(ThemeColor.border, lineWidth: 1))
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .navigationBarTitle("System Logs", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }.foregroundColor(ThemeColor.textSecondary),
                trailing: HStack(spacing: 14) {
                    Button(action: copyAllLogs) {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(ThemeColor.primary)
                    }

                    Button(action: clearLogs) {
                        Image(systemName: "trash")
                            .foregroundColor(ThemeColor.disconnected)
                    }
                }
            )
            .onAppear(perform: loadLogs)
        }
    }

    private var filteredLogs: [LogEntry] {
        logs.filter { entry in
            let matchesLevel = (selectedLevel == "ALL") || (entry.level.rawValue == selectedLevel)
            let matchesSearch = searchText.isEmpty || entry.message.localizedCaseInsensitiveContains(searchText)
            return matchesLevel && matchesSearch
        }
    }

    private func loadLogs() {
        var current = StorageService.shared.loadLogs()
        if current.isEmpty {
            // Sample start logs
            current.append(LogEntry(level: .info, message: "NA Tunnel Core initialized with Sing-box v1.10.0"))
            current.append(LogEntry(level: .info, message: "NetworkExtension Provider loaded successfully"))
            current.append(LogEntry(level: .info, message: "Cambodia carrier Clean IP routing engine active"))
            StorageService.shared.appendLog(current[0])
            StorageService.shared.appendLog(current[1])
            StorageService.shared.appendLog(current[2])
        }
        self.logs = current
    }

    private func copyAllLogs() {
        let text = filteredLogs.map { "\($0.formattedTime) [\($0.level.rawValue)] \($0.message)" }.joined(separator: "\n")
        UIPasteboard.general.string = text
    }

    private func clearLogs() {
        StorageService.shared.clearLogs()
        logs.removeAll()
    }
}
