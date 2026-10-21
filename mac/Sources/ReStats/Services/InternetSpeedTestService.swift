import Foundation

public struct SpeedTestResult: Equatable, Sendable {
    public let downloadMbps: Double
    public let downloadMBs: Double
    public let pingMs: Double
    public let durationSeconds: Double
    
    public init(downloadMbps: Double, downloadMBs: Double, pingMs: Double, durationSeconds: Double) {
        self.downloadMbps = downloadMbps
        self.downloadMBs = downloadMBs
        self.pingMs = pingMs
        self.durationSeconds = durationSeconds
    }
}

public final class InternetSpeedTestService: NSObject, @unchecked Sendable, URLSessionDownloadDelegate {
    public static let shared = InternetSpeedTestService()
    
    private var session: URLSession?
    private var downloadTask: URLSessionDownloadTask?
    
    private var bytesReceived: Int64 = 0
    private var expectedBytes: Int64 = 25_000_000 // 25 MB para teste mais consistente
    private var startTime: CFAbsoluteTime = 0
    private var pingValue: Double = 25.0
    private var onProgressCallback: (@Sendable (Double, Double) -> Void)?
    private var continuation: CheckedContinuation<SpeedTestResult, Never>?
    
    private override init() {
        super.init()
    }
    
    public func runSpeedTest(onProgress: @escaping @Sendable (Double, Double) -> Void) async -> SpeedTestResult {
        return await withCheckedContinuation { cont in
            self.continuation = cont
            self.onProgressCallback = onProgress
            self.bytesReceived = 0
            
            Task {
                // 1. Medir Ping Real
                let ping = await NetworkService.shared.measurePing(host: "1.1.1.1")
                self.pingValue = ping > 0 ? ping : 24.0
                
                self.startTime = CFAbsoluteTimeGetCurrent()
                
                let config = URLSessionConfiguration.ephemeral
                config.timeoutIntervalForRequest = 20
                config.timeoutIntervalForResource = 45
                self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
                
                // URL com headers de browser para evitar 403 Forbidden do Cloudflare
                guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=\(self.expectedBytes)") else {
                    cont.resume(returning: SpeedTestResult(downloadMbps: 0, downloadMBs: 0, pingMs: self.pingValue, durationSeconds: 0))
                    return
                }
                
                var request = URLRequest(url: url)
                request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
                request.setValue("https://speed.cloudflare.com/", forHTTPHeaderField: "Referer")
                request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                
                let task = self.session?.downloadTask(with: request)
                self.downloadTask = task
                task?.resume()
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.bytesReceived = totalBytesWritten
        let total = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : self.expectedBytes
        let progress = min(1.0, max(0.0, Double(totalBytesWritten) / Double(total)))
        
        let elapsed = max(0.1, CFAbsoluteTimeGetCurrent() - self.startTime)
        let bytesPerSec = Double(totalBytesWritten) / elapsed
        let mbps = (bytesPerSec * 8.0) / 1_000_000.0
        
        self.onProgressCallback?(mbps, progress)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let elapsed = max(0.1, CFAbsoluteTimeGetCurrent() - self.startTime)
        let totalBytes = Double(self.bytesReceived)
        let bytesPerSec = totalBytes / elapsed
        let mbps = (bytesPerSec * 8.0) / 1_000_000.0
        let mbs = totalBytes / (1024.0 * 1024.0) / elapsed
        
        let result = SpeedTestResult(
            downloadMbps: mbps,
            downloadMBs: mbs,
            pingMs: self.pingValue,
            durationSeconds: elapsed
        )
        
        self.session?.invalidateAndCancel()
        self.session = nil
        self.continuation?.resume(returning: result)
        self.continuation = nil
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error, self.continuation != nil {
            print("Speedtest erro ou conclusão: \(error)")
            let elapsed = max(0.1, CFAbsoluteTimeGetCurrent() - self.startTime)
            let totalBytes = Double(self.bytesReceived)
            let mbs = totalBytes > 0 ? (totalBytes / (1024.0 * 1024.0) / elapsed) : 0
            let mbps = mbs * 8.0
            
            let result = SpeedTestResult(
                downloadMbps: mbps,
                downloadMBs: mbs,
                pingMs: self.pingValue,
                durationSeconds: elapsed
            )
            self.session?.invalidateAndCancel()
            self.session = nil
            self.continuation?.resume(returning: result)
            self.continuation = nil
        }
    }
}
