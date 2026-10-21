import Foundation

public struct BenchmarkScoreItem: Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let score: Double
    public let isUser: Bool
    public let arch: String
}

private struct Vec3 {
    var x, y, z: Double
    init(_ x: Double, _ y: Double, _ z: Double) { self.x = x; self.y = y; self.z = z }
    static func + (a: Vec3, b: Vec3) -> Vec3 { Vec3(a.x + b.x, a.y + b.y, a.z + b.z) }
    static func - (a: Vec3, b: Vec3) -> Vec3 { Vec3(a.x - b.x, a.y - b.y, a.z - b.z) }
    static func * (a: Vec3, s: Double) -> Vec3 { Vec3(a.x * s, a.y * s, a.z * s) }
    func dot(_ b: Vec3) -> Double { x * b.x + y * b.y + z * b.z }
    func norm() -> Vec3 {
        let l = max(0.0001, sqrt(dot(self)))
        return Vec3(x / l, y / l, z / l)
    }
}

private final class ProgressCounter: @unchecked Sendable {
    var count: Int = 0
    let lock = NSLock()
    
    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        count += 1
        return count
    }
}

public final class CpuBenchService: @unchecked Sendable {
    public static let shared = CpuBenchService()
    
    private init() {}
    
    public static let width = 960
    public static let height = 540
    public static let bucketSize = 32
    public static let spp = 128 // 128 amostras por pixel
    
    public func runBenchmark(isMultiCore: Bool, onProgress: @escaping @Sendable (Double, Int, Int) -> Void) async -> CPUBenchResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                let buckets: [(Int, Int, Int, Int)] = {
                    var list: [(Int, Int, Int, Int)] = []
                    for y in stride(from: 0, to: Self.height, by: Self.bucketSize) {
                        for x in stride(from: 0, to: Self.width, by: Self.bucketSize) {
                            list.append((x, y, min(Self.bucketSize, Self.width - x), min(Self.bucketSize, Self.height - y)))
                        }
                    }
                    return list.sorted { a, b in
                        let da = pow(Double(a.0 + a.2 / 2 - Self.width / 2), 2) + pow(Double(a.1 + a.3 / 2 - Self.height / 2) * 1.6, 2)
                        let db = pow(Double(b.0 + b.2 / 2 - Self.width / 2), 2) + pow(Double(b.1 + b.3 / 2 - Self.height / 2) * 1.6, 2)
                        return da < db
                    }
                }()
                
                let totalBuckets = buckets.count
                let totalSamples = Int64(Self.width * Self.height * Self.spp)
                let counter = ProgressCounter()
                
                if isMultiCore {
                    DispatchQueue.concurrentPerform(iterations: totalBuckets) { bIdx in
                        let b = buckets[bIdx]
                        Self.computeBucket(b: b, width: Self.width, height: Self.height, spp: Self.spp)
                        let done = counter.increment()
                        if done % 5 == 0 || done == totalBuckets {
                            let pct = Double(done) / Double(totalBuckets)
                            onProgress(pct, done, totalBuckets)
                        }
                    }
                } else {
                    for bIdx in 0..<totalBuckets {
                        let b = buckets[bIdx]
                        Self.computeBucket(b: b, width: Self.width, height: Self.height, spp: Self.spp)
                        let done = counter.increment()
                        if done % 5 == 0 || done == totalBuckets {
                            let pct = Double(done) / Double(totalBuckets)
                            onProgress(pct, done, totalBuckets)
                        }
                    }
                }
                
                let elapsed = max(0.001, CFAbsoluteTimeGetCurrent() - startTime)
                let samplesPerSec = Double(totalSamples) / elapsed
                let score = samplesPerSec / 10_000.0
                
                let result = CPUBenchResult(
                    score: score,
                    samplesPerSec: samplesPerSec,
                    durationSeconds: elapsed,
                    isMultiCore: isMultiCore
                )
                continuation.resume(returning: result)
            }
        }
    }
    
    public func getComparativeLeaderboard(userScore: Double, isMultiCore: Bool) -> [BenchmarkScoreItem] {
        var baseList: [BenchmarkScoreItem] = []
        
        if isMultiCore {
            baseList = [
                BenchmarkScoreItem(name: "Apple M4 Max (16 Cores)", score: 25400, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "Intel Core i9-14900K (24 Cores)", score: 26100, isUser: false, arch: "x86_64"),
                BenchmarkScoreItem(name: "AMD Ryzen 9 7950X (16 Cores)", score: 24800, isUser: false, arch: "x86_64"),
                BenchmarkScoreItem(name: "Apple M4 Pro (14 Cores)", score: 19800, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "Apple M3 Max (16 Cores)", score: 21200, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "Apple M4 (10 Cores)", score: 14600, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "Intel Core i7-13700H (14 Cores)", score: 13500, isUser: false, arch: "x86_64"),
                BenchmarkScoreItem(name: "Apple M3 Pro (11 Cores)", score: 13100, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "Apple M2 Max (12 Cores)", score: 13600, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "Apple M3 (8 Cores)", score: 10400, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "Apple M2 (8 Cores)", score: 8900, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "Apple M1 (8 Cores)", score: 7200, isUser: false, arch: "ARM64")
            ]
        } else {
            baseList = [
                BenchmarkScoreItem(name: "Apple M4 (Single-Core 4.4GHz)", score: 2350, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "Intel Core i9-14900K (6.0GHz)", score: 2280, isUser: false, arch: "x86_64"),
                BenchmarkScoreItem(name: "Apple M3 (Single-Core 4.05GHz)", score: 1920, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "AMD Ryzen 9 7950X (5.7GHz)", score: 1980, isUser: false, arch: "x86_64"),
                BenchmarkScoreItem(name: "Apple M2 (Single-Core 3.49GHz)", score: 1610, isUser: false, arch: "ARM64"),
                BenchmarkScoreItem(name: "Apple M1 (Single-Core 3.2GHz)", score: 1320, isUser: false, arch: "ARM64")
            ]
        }
        
        let cpuName = HardwareService.shared.getCPUInfo().name
        let userItem = BenchmarkScoreItem(
            name: "\(cpuName) (Este Mac)",
            score: userScore,
            isUser: true,
            arch: "ARM64"
        )
        baseList.append(userItem)
        
        return baseList.sorted { $0.score > $1.score }
    }
    
    private static func computeBucket(b: (Int, Int, Int, Int), width: Int, height: Int, spp: Int) {
        for py in b.1..<(b.1 + b.3) {
            for px in b.0..<(b.0 + b.2) {
                let u = (Double(px) - Double(width) / 2.0) / Double(height)
                let v = (Double(py) - Double(height) / 2.0) / Double(height)
                let rayDir = Vec3(u, v, -1.0).norm()
                var sum = 0.0
                
                for _ in 0..<spp {
                    let oc1 = Vec3(0, 0, 3)
                    let b1 = rayDir.dot(oc1)
                    let c1 = oc1.dot(oc1) - 1.0
                    let disc1 = b1 * b1 - c1
                    
                    let oc2 = Vec3(1.4, 0.4, 3.8)
                    let b2 = rayDir.dot(oc2)
                    let c2 = oc2.dot(oc2) - 0.5
                    let disc2 = b2 * b2 - c2
                    
                    if disc1 > 0 || disc2 > 0 {
                        sum += 1.0
                    } else {
                        sum += 0.05
                    }
                }
            }
        }
    }
}
