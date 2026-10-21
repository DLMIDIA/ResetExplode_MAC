import Foundation
import Darwin

public final class DiskVolumeService: @unchecked Sendable {
    public static let shared = DiskVolumeService()
    
    private init() {}
    
    public func listMountedVolumes() -> [DiskVolume] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeIsRemovableKey,
            .volumeIsInternalKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey
        ]
        
        var volumes: [DiskVolume] = []
        let fileManager = FileManager.default
        
        if let urls = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) {
            for url in urls {
                do {
                    let res = try url.resourceValues(forKeys: Set(keys))
                    let name = res.volumeName ?? url.lastPathComponent
                    let isInternal = res.volumeIsInternal ?? true
                    let isRemovable = res.volumeIsRemovable ?? false
                    let totalBytes = UInt64(res.volumeTotalCapacity ?? 0)
                    let freeBytes = UInt64(res.volumeAvailableCapacity ?? 0)
                    let usedBytes = totalBytes > freeBytes ? (totalBytes - freeBytes) : 0
                    
                    let totalGB = Double(totalBytes) / (1024.0 * 1024.0 * 1024.0)
                    let freeGB = Double(freeBytes) / (1024.0 * 1024.0 * 1024.0)
                    let usedGB = Double(usedBytes) / (1024.0 * 1024.0 * 1024.0)
                    
                    // Apenas volumes com mais de 100 MB para evitar volumes de recuperação do sistema
                    if totalGB > 0.1 {
                        volumes.append(
                            DiskVolume(
                                name: name,
                                path: url.path,
                                isInternal: isInternal,
                                isRemovable: isRemovable,
                                totalGB: totalGB,
                                freeGB: freeGB,
                                usedGB: usedGB
                            )
                        )
                    }
                } catch {
                    continue
                }
            }
        }
        
        // Garante que o disco principal "/" venha primeiro
        return volumes.sorted { a, _ in a.path == "/" }
    }
    
    public func runBenchmark(on volume: DiskVolume, sizeMB: Int = 128, onProgress: @escaping @Sendable (String, Double) -> Void) async -> DiskBenchResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let testFilePath: String
                if volume.path == "/" {
                    testFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("ResetExplode_disk_test.bin")
                } else {
                    testFilePath = (volume.path as NSString).appendingPathComponent(".ResetExplode_disk_test.bin")
                }
                
                let blockSize = 1024 * 1024 // 1 MB
                let totalBlocks = sizeMB
                let totalBytes = Int64(totalBlocks) * Int64(blockSize)
                var buffer = [UInt8](repeating: 0x55, count: blockSize)
                
                // 1. Escrita Sequencial (F_NOCACHE)
                onProgress("Testando Escrita Sequencial (1 MB)...", 0.05)
                let fdWrite = open(testFilePath, O_WRONLY | O_CREAT | O_TRUNC, 0o666)
                if fdWrite >= 0 {
                    _ = fcntl(fdWrite, F_NOCACHE, 1)
                }
                
                let writeStart = CFAbsoluteTimeGetCurrent()
                if fdWrite >= 0 {
                    for b in 0..<totalBlocks {
                        _ = write(fdWrite, &buffer, blockSize)
                        if b % 16 == 0 {
                            let pct = 0.05 + 0.35 * (Double(b) / Double(totalBlocks))
                            onProgress("Escrevendo blocos de 1 MB (\(b)/\(totalBlocks))...", pct)
                        }
                    }
                    close(fdWrite)
                }
                let writeElapsed = max(0.001, CFAbsoluteTimeGetCurrent() - writeStart)
                let seqWriteMBs = Double(totalBytes) / (1024.0 * 1024.0) / writeElapsed
                
                // 2. Leitura Sequencial (F_NOCACHE)
                onProgress("Testando Leitura Sequencial (1 MB)...", 0.45)
                let fdRead = open(testFilePath, O_RDONLY)
                if fdRead >= 0 {
                    _ = fcntl(fdRead, F_NOCACHE, 1)
                }
                
                let readStart = CFAbsoluteTimeGetCurrent()
                if fdRead >= 0 {
                    for b in 0..<totalBlocks {
                        _ = read(fdRead, &buffer, blockSize)
                        if b % 16 == 0 {
                            let pct = 0.45 + 0.30 * (Double(b) / Double(totalBlocks))
                            onProgress("Lendo blocos de 1 MB (\(b)/\(totalBlocks))...", pct)
                        }
                    }
                    close(fdRead)
                }
                let readElapsed = max(0.001, CFAbsoluteTimeGetCurrent() - readStart)
                let seqReadMBs = Double(totalBytes) / (1024.0 * 1024.0) / readElapsed
                
                // 3. Teste Random 4K IOPS Read
                onProgress("Testando Leitura Aleatória 4K (IOPS)...", 0.80)
                let fdRand = open(testFilePath, O_RDONLY)
                if fdRand >= 0 {
                    _ = fcntl(fdRand, F_NOCACHE, 1)
                }
                
                var buf4k = [UInt8](repeating: 0, count: 4096)
                let randCount = 2000
                let maxOffsets = max(1, (totalBytes - 4096) / 4096)
                let randStart = CFAbsoluteTimeGetCurrent()
                
                if fdRand >= 0 {
                    for _ in 0..<randCount {
                        let offset = off_t(Int64.random(in: 0..<maxOffsets) * 4096)
                        lseek(fdRand, offset, SEEK_SET)
                        _ = read(fdRand, &buf4k, 4096)
                    }
                    close(fdRand)
                }
                let randElapsed = max(0.0001, CFAbsoluteTimeGetCurrent() - randStart)
                let rand4kReadIOPS = Double(randCount) / randElapsed
                
                // 4. Teste Random 4K IOPS Write
                onProgress("Testando Escrita Aleatória 4K (IOPS)...", 0.90)
                let fdRandW = open(testFilePath, O_WRONLY)
                if fdRandW >= 0 {
                    _ = fcntl(fdRandW, F_NOCACHE, 1)
                }
                let randWStart = CFAbsoluteTimeGetCurrent()
                if fdRandW >= 0 {
                    for _ in 0..<randCount {
                        let offset = off_t(Int64.random(in: 0..<maxOffsets) * 4096)
                        lseek(fdRandW, offset, SEEK_SET)
                        _ = write(fdRandW, &buf4k, 4096)
                    }
                    close(fdRandW)
                }
                let randWElapsed = max(0.0001, CFAbsoluteTimeGetCurrent() - randWStart)
                let rand4kWriteIOPS = Double(randCount) / randWElapsed
                
                // Limpeza
                unlink(testFilePath)
                onProgress("Benchmark de Armazenamento Concluído!", 1.0)
                
                let result = DiskBenchResult(
                    volumeName: volume.name,
                    seqReadMBs: seqReadMBs,
                    seqWriteMBs: seqWriteMBs,
                    random4kReadIOPS: rand4kReadIOPS,
                    random4kWriteIOPS: rand4kWriteIOPS,
                    durationSeconds: writeElapsed + readElapsed + randElapsed + randWElapsed
                )
                continuation.resume(returning: result)
            }
        }
    }
}
