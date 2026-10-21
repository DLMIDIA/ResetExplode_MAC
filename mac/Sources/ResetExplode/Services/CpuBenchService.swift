import Foundation

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
    
    public func runBenchmark(isMultiCore: Bool, onProgress: @escaping @Sendable (Double) -> Void) async -> CPUBenchResult {
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
                        if done % 10 == 0 || done == totalBuckets {
                            let pct = Double(done) / Double(totalBuckets)
                            onProgress(pct)
                        }
                    }
                } else {
                    for bIdx in 0..<totalBuckets {
                        let b = buckets[bIdx]
                        Self.computeBucket(b: b, width: Self.width, height: Self.height, spp: Self.spp)
                        let done = counter.increment()
                        if done % 10 == 0 || done == totalBuckets {
                            let pct = Double(done) / Double(totalBuckets)
                            onProgress(pct)
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
