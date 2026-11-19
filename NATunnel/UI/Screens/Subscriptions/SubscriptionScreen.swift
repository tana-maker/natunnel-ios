//
//  SubscriptionScreen.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import SwiftUI

public struct SubscriptionScreen: View {
    @State private var subscriptions: [SubscriptionItem] = []
    @State private var isUpdating = false
    @State private var showAddSheet = false

    @State private var newSubName: String = "VIP Subscription"
    @State private var newSubUrl: String = ""
    @State private var errorMessage: String?
    @State private var alertMessage: String?
    @State private var showAlert = false

    public var body: some View {
        NavigationView {
            ZStack {
                ThemeColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Header Banner
                        NeonCard {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(ThemeColor.primary)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("AUTO-SYNC PROFILES")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(ThemeColor.textSecondary)

                                    Text("Keep your server lists updated automatically with high-speed nodes.")
                                        .font(.system(size: 13))
                                        .foregroundColor(ThemeColor.textPrimary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        if subscriptions.isEmpty {
                            // Empty State
                            VStack(spacing: 14) {
                                Image(systemName: "link.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundColor(ThemeColor.textMuted)

                                Text("No Subscriptions Added")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(ThemeColor.textPrimary)

                                Text("Add a subscription link provided by your admin or service provider to import all nodes at once.")
                                    .font(.system(size: 13))
                                    .foregroundColor(ThemeColor.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)

                                Button(action: { showAddSheet = true }) {
                                    Text("+ Add Subscription")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(hex: 0x052E16))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 10)
                                        .background(ThemeColor.primary)
                                        .clipShape(Capsule())
                                }
                                .padding(.top, 8)
                            }
                            .padding(.vertical, 40)
                        } else {
                            // Subscriptions List
                            ForEach(subscriptions) { sub in
                                SubscriptionCardView(
                                    item: sub,
                                    onRefresh: { refreshSingle(sub) },
                                    onDelete: { deleteSubscription(sub) }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Subscriptions", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: updateAll) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isUpdating ? 360 : 0))
                            .animation(
                                isUpdating ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: isUpdating
                            )
                        Text(isUpdating ? "Updating..." : "Update All")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(ThemeColor.primary)
                }
                .disabled(isUpdating || subscriptions.isEmpty),
                trailing: Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ThemeColor.primary)
                }
            )
            .sheet(isPresented: $showAddSheet) {
                AddSubscriptionModal(
                    name: $newSubName,
                    url: $newSubUrl,
                    onSave: saveNewSubscription
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Subscriptions"), message: Text(alertMessage ?? ""), dismissButton: .default(Text("OK")))
            }
            .onAppear(perform: loadData)
        }
    }

    private func loadData() {
        self.subscriptions = StorageService.shared.loadSubscriptions()
    }

    private func saveNewSubscription() {
        guard !newSubUrl.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newItem = SubscriptionItem(
            name: newSubName.isEmpty ? "Subscription" : newSubName,
            url: newSubUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        subscriptions.append(newItem)
        StorageService.shared.saveSubscriptions(subscriptions)
        refreshSingle(newItem)
        newSubUrl = ""
    }

    private func refreshSingle(_ item: SubscriptionItem) {
        isUpdating = true
        SubscriptionService.shared.updateSubscription(item: item) { result in
            isUpdating = false
            loadData()
            switch result {
            case .success(let list):
                alertMessage = "Synced \(list.count) servers from \(item.name)"
                showAlert = true
            case .failure(let err):
                alertMessage = "Update failed: \(err.localizedDescription)"
                showAlert = true
            }
        }
    }

    private func updateAll() {
        isUpdating = true
        SubscriptionService.shared.updateAllSubscriptions {
            isUpdating = false
            loadData()
            alertMessage = "All subscriptions updated successfully!"
            showAlert = true
        }
    }

    private func deleteSubscription(_ item: SubscriptionItem) {
        subscriptions.removeAll { $0.id == item.id }
        StorageService.shared.saveSubscriptions(subscriptions)

        // Remove linked configs
        var configs = StorageService.shared.loadConfigs()
        configs.removeAll { $0.subscriptionId == item.id }
        StorageService.shared.saveConfigs(configs)
    }
}

struct SubscriptionCardView: View {
    let item: SubscriptionItem
    let onRefresh: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NeonCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(item.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(ThemeColor.textPrimary)

                            if item.hasExpiry {
                                let isExpired = item.isExpired
                                Text("⏳ \(item.formattedExpiry)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(isExpired ? Color.red : ThemeColor.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(isExpired ? Color.red.opacity(0.15) : ThemeColor.primary.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }

                        Text("\(item.serverCount) Servers  •  Updated \(item.formattedLastUpdated)")
                            .font(.system(size: 12))
                            .foregroundColor(ThemeColor.textSecondary)
                    }

                    Spacer()

                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ThemeColor.primary)
                    }
                }

                if item.hasTrafficQuota {
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(ThemeColor.surfaceVariant)
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.trafficProgress >= 0.9 ? Color.red : (item.trafficProgress >= 0.75 ? ThemeColor.accentAmber : ThemeColor.primary))
                                    .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(item.trafficProgress))), height: 6)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("\(item.formattedUsedTraffic) / \(item.formattedTotalTraffic)")
                                .font(.system(size: 11))
                                .foregroundColor(ThemeColor.textSecondary)

                            Spacer()

                            Text("\(item.formattedRemainingTraffic) remaining")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(item.trafficProgress >= 0.9 ? Color.red : ThemeColor.primary)
                        }
                    }
                    .padding(.vertical, 2)
                }

                let isOfficial = item.id.contains("sg01") || item.id.contains("sg02") ||
                                 item.id.contains("official") ||
                                 item.url.contains("workers.dev") ||
                                 item.url.contains("theworkpc.com")

                Text(isOfficial ? "🛡️ NA Tunnel Official Hub [System Protected]" : item.url)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(isOfficial ? ThemeColor.primary : ThemeColor.textMuted)
                    .lineLimit(1)
            }
        }
        .contextMenu {
            Button(action: onRefresh) {
                Label("Update Now", systemImage: "arrow.clockwise")
            }
            if !(item.id.contains("sg01") || item.id.contains("sg02") || item.id.contains("official") || item.url.contains("workers.dev") || item.url.contains("theworkpc.com")) {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Subscription", systemImage: "trash")
                }
            }
        }
    }
}

struct AddSubscriptionModal: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var name: String
    @Binding var url: String
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                ThemeColor.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    NeonCard {
                        VStack(spacing: 14) {
                            CustomTextField(label: "SUBSCRIPTION NAME", text: $name, placeholder: "e.g. NA Tunnel VIP")
                            CustomTextField(label: "SUBSCRIPTION URL", text: $url, placeholder: "https://...")

                            Button(action: {
                                if let clip = UIPasteboard.general.string {
                                    url = clip
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.clipboard")
                                    Text("Paste URL from Clipboard")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(ThemeColor.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    Button(action: {
                        onSave()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Add Subscription")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: 0x052E16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(ThemeColor.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitle("Add Subscription", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }.foregroundColor(ThemeColor.textSecondary)
            )
        }
    }
}
