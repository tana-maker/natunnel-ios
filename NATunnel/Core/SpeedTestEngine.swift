//
//  SpeedTestEngine.swift
//  NATunnel
//
//  Created for NA Tunnel iOS.
//

import Foundation

public protocol SpeedTestDelegate: AnyObject {
    func speedTestDidUpdatePing(pingMs: Double, jitterMs: Double)
    func speedTestDidUpdateDownload(currentMbps: Double, progress: Double)
    func speedTestDidUpdateUpload(currentMbps: Double, progress: Double)
    func speedTestDidComplete(result: SpeedTestResult)
    func speedTestDidFail(error: String)
}

public final class SpeedTestEngine: NSObject, URLSessionDataDelegate {
    public weak var delegate: SpeedTestDelegate?

    private var session: URLSession?
    private var downloadTask: URLSessionDataTask?
    private var uploadTask: URLSessionUploadTask?

    private var isCancelled = false
    private var downloadBytesReceived: Int64 = 0
    private var uploadBytesSent: Int64 = 0
    private var downloadStartTime: CFAbsoluteTime = 0
    private var uploadStartTime: CFAbsoluteTime = 0

    private var pingResult: Double = 0
    private var jitterResult: Double = 0
    private var finalDownloadMbps: Double = 0
    private var finalUploadMbps: Double = 0

    private let downloadUrl = URL(string: "https://speed.cloudflare.com/__down?bytes=25000000")! // 25MB
    private let uploadUrl = URL(string: "https://speed.cloudflare.com/__up")!
    private let browserUa = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    public override init() {
        super.init()
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    public func startTest(serverName: String = "Auto Node") {
        isCancelled = false
        downloadBytesReceived = 0
        uploadBytesSent = 0

        // Step 1: Measure Ping & Jitter
        measurePing { [weak self] ping, jitter in
            guard let self = self, !self.isCancelled else { return }
            self.pingResult = ping
            self.jitterResult = jitter
            DispatchQueue.main.async {
                self.delegate?.speedTestDidUpdatePing(pingMs: ping, jitterMs: jitter)
            }

            // Step 2: Download Speed Test
            self.runDownloadTest {
                guard !self.isCancelled else { return }

                // Step 3: Upload Speed Test
                self.runUploadTest {
                    guard !self.isCancelled else { return }

                    let finalResult = SpeedTestResult(
                        downloadMbps: self.finalDownloadMbps,
                        uploadMbps: self.finalUploadMbps,
                        pingMs: self.pingResult,
                        jitterMs: self.jitterResult,
                        serverName: serverName,
                        timestamp: Date()
                    )
                    DispatchQueue.main.async {
                        self.delegate?.speedTestDidComplete(result: finalResult)
                    }
                }
            }
        }
    }

    public func cancel() {
        isCancelled = true
        downloadTask?.cancel()
        uploadTask?.cancel()
    }

    private func measurePing(completion: @escaping (Double, Double) -> Void) {
        let pingHost = "1.1.1.1"
        var samples: [Double] = []
        let group = DispatchGroup()

        for _ in 0..<4 {
            group.enter()
            let start = CFAbsoluteTimeGetCurrent()
            PingEngine.ping(host: pingHost, port: 443, timeout: 2.0) { ms in
                if ms > 0 {
                    samples.append(Double(ms))
                } else {
                    let diff = (CFAbsoluteTimeGetCurrent() - start) * 1000
                    samples.append(diff)
                }
                group.leave()
            }
        }

        group.notify(queue: .global()) {
            if samples.isEmpty {
                completion(45.0, 5.0)
                return
            }
            let avgPing = samples.reduce(0, +) / Double(samples.count)
            let diffs = zip(samples, samples.dropFirst()).map { abs($0 - $1) }
            let jitter = diffs.isEmpty ? 3.0 : diffs.reduce(0, +) / Double(diffs.count)
            completion(avgPing, jitter)
        }
    }

    private func runDownloadTest(completion: @escaping () -> Void) {
        downloadBytesReceived = 0
        downloadStartTime = CFAbsoluteTimeGetCurrent()
        var request = URLRequest(url: downloadUrl)
        request.httpMethod = "GET"
        request.setValue("https://speed.cloudflare.com/", forHTTPHeaderField: "Referer")
        request.setValue("https://speed.cloudflare.com", forHTTPHeaderField: "Origin")
        request.setValue(browserUa, forHTTPHeaderField: "User-Agent")

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 0.2, repeating: 0.2)
        timer.setEventHandler { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            let elapsed = CFAbsoluteTimeGetCurrent() - self.downloadStartTime
            if elapsed > 0 {
                let mbps = (Double(self.downloadBytesReceived * 8) / elapsed) / 1_000_000.0
                self.finalDownloadMbps = max(self.finalDownloadMbps, mbps)
                let progress = min(1.0, elapsed / 8.0)
                self.delegate?.speedTestDidUpdateDownload(currentMbps: mbps, progress: progress)
                if elapsed >= 8.0 {
                    timer.cancel()
                    self.downloadTask?.cancel()
                    completion()
                }
            }
        }
        timer.resume()

        downloadTask = session?.dataTask(with: request)
        downloadTask?.resume()
    }

    private func runUploadTest(completion: @escaping () -> Void) {
        uploadStartTime = CFAbsoluteTimeGetCurrent()
        uploadBytesSent = 0
        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("https://speed.cloudflare.com/", forHTTPHeaderField: "Referer")
        request.setValue("https://speed.cloudflare.com", forHTTPHeaderField: "Origin")
        request.setValue(browserUa, forHTTPHeaderField: "User-Agent")

        // 4MB upload payload
        let dummyData = Data(repeating: 0x55, count: 4 * 1024 * 1024)

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 0.2, repeating: 0.2)

        timer.setEventHandler { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            let elapsed = CFAbsoluteTimeGetCurrent() - self.uploadStartTime
            if elapsed > 0 {
                let bytes = max(self.uploadBytesSent, 1)
                let mbps = (Double(bytes * 8) / elapsed) / 1_000_000.0
                self.finalUploadMbps = mbps
                let progress = min(1.0, elapsed / 6.0)
                self.delegate?.speedTestDidUpdateUpload(currentMbps: mbps, progress: progress)
                if elapsed >= 6.0 || self.uploadBytesSent >= dummyData.count {
                    timer.cancel()
                    self.uploadTask?.cancel()
                    completion()
                }
            }
        }
        timer.resume()

        uploadTask = session?.uploadTask(with: request, from: dummyData)
        uploadTask?.resume()
    }

    // MARK: - URLSessionDataDelegate & URLSessionTaskDelegate
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        downloadBytesReceived += Int64(data.count)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if task == uploadTask {
            uploadBytesSent = totalBytesSent
        }
    }
}
