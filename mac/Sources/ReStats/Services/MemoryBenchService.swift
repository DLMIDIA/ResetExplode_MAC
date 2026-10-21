import Foundation

public final class MemoryBenchService: @unchecked Sendable {
    public static let shared = MemoryBenchService()
    
    private init() {}
    
    public func runMemoryBenchmark(onProgress: @escaping @Sendable (Double, String) -> Void) async -> MemoryBenchResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                onProgress(0.1, "Alocando buffers de teste (512 MB)...")
                let sizeInBytes = 512 * 1024 * 1024 // 512 MB
                let count = sizeInBytes / MemoryLayout<UInt64>.size
                
                let src = UnsafeMutablePointer<UInt64>.allocate(capacity: count)
                let dst = UnsafeMutablePointer<UInt64>.allocate(capacity: count)
                
                defer {
                    src.deallocate()
                    dst.deallocate()
                }
                
                // Inicialização com padrão
                for i in 0..<min(count, 1000000) {
                    src[i] = UInt64(i)
                }
                
                onProgress(0.3, "Testando Largura de Banda de Memória Unificada...")
                let iterations = 10
                let startBandwidth = CFAbsoluteTimeGetCurrent()
                
                for it in 0..<iterations {
                    memcpy(dst, src, sizeInBytes)
                    onProgress(0.3 + (Double(it) / Double(iterations)) * 0.4, "Transferência de blocos L1/L2/DRAM (\(it + 1)/\(iterations))...")
                }
                
                let bandwidthElapsed = max(0.0001, CFAbsoluteTimeGetCurrent() - startBandwidth)
                let totalBytesCopied = Double(sizeInBytes * iterations)
                let bandwidthGBs = (totalBytesCopied / (1024.0 * 1024.0 * 1024.0)) / bandwidthElapsed
                
                onProgress(0.8, "Medindo Latência de Acesso (Pointer Chasing)...")
                
                // Latency test: Pointer chasing em anel aleatório (64 MB buffer)
                let latencyElements = 8 * 1024 * 1024 // 64 MB
                let latencyPtr = UnsafeMutablePointer<Int>.allocate(capacity: latencyElements)
                defer { latencyPtr.deallocate() }
                
                // Anel de saltos aleatórios
                var indices = Array(0..<latencyElements)
                indices.shuffle()
                for i in 0..<(latencyElements - 1) {
                    latencyPtr[indices[i]] = indices[i + 1]
                }
                latencyPtr[indices[latencyElements - 1]] = indices[0]
                
                var curr = 0
                let chaseSteps = 5_000_000
                let startLatency = CFAbsoluteTimeGetCurrent()
                
                for _ in 0..<chaseSteps {
                    curr = latencyPtr[curr]
                }
                
                let latencyElapsed = max(0.000001, CFAbsoluteTimeGetCurrent() - startLatency)
                let latencyNs = (latencyElapsed / Double(chaseSteps)) * 1_000_000_000.0
                
                // Previne otimização de eliminação de código
                if curr == -999999 {
                    print("Impossible")
                }
                
                onProgress(1.0, "Benchmark de Memória Concluído!")
                
                let result = MemoryBenchResult(
                    bandwidthGBs: bandwidthGBs,
                    latencyNs: latencyNs,
                    durationSeconds: bandwidthElapsed + latencyElapsed
                )
                continuation.resume(returning: result)
            }
        }
    }
}
