//
//  SubscriptionService.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public final class SubscriptionService {
    public static let shared = SubscriptionService()

    private let storage = StorageService.shared

    public func updateSubscription(item: SubscriptionItem, completion: @escaping (Result<[VpnConfig], Error>) -> Void) {
        guard let url = URL(string: item.url.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            completion(.failure(NSError(domain: "NATunnel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid subscription URL"])))
            return
        }

        let isOfficial = item.id.contains("sg01") || item.id.contains("sg02") ||
                         item.id.contains("official") ||
                         item.url.contains("workers.dev") ||
                         item.url.contains("theworkpc.com")

        var request = URLRequest(url: url)
        request.setValue("v2rayNG/1.8.19", forHTTPHeaderField: "User-Agent")
        if isOfficial {
            request.setValue("NATunnel-Auth-2026-SecretToken", forHTTPHeaderField: "X-NATunnel-Auth")
        }
        request.timeoutInterval = 15

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "NATunnel", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty or invalid subscription response"])))
                }
                return
            }

            // Extract User-Info header if present (upload, download, total, expire)
            var upload: Int64 = 0
            var download: Int64 = 0
            var total: Int64 = 0
            var expire: Int64 = 0

            if let httpResp = response as? HTTPURLResponse {
                if let userInfo = httpResp.value(forHTTPHeaderField: "Subscription-Userinfo") ?? httpResp.value(forHTTPHeaderField: "subscription-userinfo") {
                    let parts = userInfo.components(separatedBy: ";")
                    for p in parts {
                        let kv = p.trimmingCharacters(in: .whitespaces).components(separatedBy: "=")
                        if kv.count == 2 {
                            let k = kv[0].lowercased()
                            let v = Int64(kv[1]) ?? 0
                            if k == "upload" { upload = v }
                            else if k == "download" { download = v }
                            else if k == "total" { total = v }
                            else if k == "expire" { expire = v }
                        }
                    }
                }
            }

            var parsedConfigs = V2RayShareLinkParser.parseMultiple(content: content)
            let isOfficial = item.id.contains("sg01") || item.id.contains("sg02") ||
                             item.id.contains("official") ||
                             item.url.contains("workers.dev") ||
                             item.url.contains("theworkpc.com")

            // Tag with subscription ID and lock official nodes
            for i in 0..<parsedConfigs.count {
                parsedConfigs[i].subscriptionId = item.id
                let nodeIsOfficial = isOfficial ||
                                     parsedConfigs[i].host.contains("workers.dev") ||
                                     parsedConfigs[i].server.contains("theworkpc.com")
                if nodeIsOfficial {
                    parsedConfigs[i].isLocked = BooleanWrapper(true)
                }
            }

            DispatchQueue.main.async {
                // Update subscription metadata
                var subs = self.storage.loadSubscriptions()
                if let idx = subs.firstIndex(where: { $0.id == item.id }) {
                    subs[idx].lastUpdated = Date()
                    subs[idx].serverCount = parsedConfigs.count
                    subs[idx].uploadBytes = upload
                    subs[idx].downloadBytes = download
                    subs[idx].totalBytes = total
                    subs[idx].expireTimestamp = expire
                    self.storage.saveSubscriptions(subs)
                }

                // Merge into configs list (replace old ones with this subscriptionId)
                var currentConfigs = self.storage.loadConfigs()
                currentConfigs.removeAll { $0.subscriptionId == item.id }
                currentConfigs.append(contentsOf: parsedConfigs)
                self.storage.saveConfigs(currentConfigs)

                completion(.success(parsedConfigs))
            }
        }.resume()
    }

    public func updateAllSubscriptions(completion: @escaping () -> Void) {
        let subs = storage.loadSubscriptions()
        let group = DispatchGroup()

        for sub in subs where sub.autoUpdate {
            group.enter()
            updateSubscription(item: sub) { _ in
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }
}
