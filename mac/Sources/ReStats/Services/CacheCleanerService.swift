import Foundation

public final class CacheCleanerService: @unchecked Sendable {
    public static let shared = CacheCleanerService()
    
    private init() {}
    
    public func scanCleanableItems() -> CleanableCaches {
        let home = NSHomeDirectory()
        let caches = calculateFolderSize(path: "\(home)/Library/Caches")
        let logs = calculateFolderSize(path: "\(home)/Library/Logs")
        let trash = calculateFolderSize(path: "\(home)/.Trash")
        
        return CleanableCaches(
            userCachesBytes: caches,
            systemLogsBytes: logs,
            trashBytes: trash
        )
    }
    
    public func cleanItems(cleanCaches: Bool, cleanLogs: Bool, emptyTrash: Bool) async -> Double {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let home = NSHomeDirectory()
                var freedBytes: UInt64 = 0
                let fm = FileManager.default
                
                if cleanCaches {
                    let cachePath = "\(home)/Library/Caches"
                    let sizeBefore = self.calculateFolderSize(path: cachePath)
                    self.clearContents(of: cachePath, fileManager: fm)
                    let sizeAfter = self.calculateFolderSize(path: cachePath)
                    if sizeBefore > sizeAfter {
                        freedBytes += (sizeBefore - sizeAfter)
                    }
                }
                
                if cleanLogs {
                    let logPath = "\(home)/Library/Logs"
                    let sizeBefore = self.calculateFolderSize(path: logPath)
                    self.clearContents(of: logPath, fileManager: fm)
                    let sizeAfter = self.calculateFolderSize(path: logPath)
                    if sizeBefore > sizeAfter {
                        freedBytes += (sizeBefore - sizeAfter)
                    }
                }
                
                if emptyTrash {
                    let trashPath = "\(home)/.Trash"
                    let sizeBefore = self.calculateFolderSize(path: trashPath)
                    self.clearContents(of: trashPath, fileManager: fm)
                    let sizeAfter = self.calculateFolderSize(path: trashPath)
                    if sizeBefore > sizeAfter {
                        freedBytes += (sizeBefore - sizeAfter)
                    }
                }
                
                let freedMB = Double(freedBytes) / (1024.0 * 1024.0)
                continuation.resume(returning: freedMB)
            }
        }
    }
    
    private func clearContents(of path: String, fileManager: FileManager) {
        if let items = try? fileManager.contentsOfDirectory(atPath: path) {
            for item in items {
                let fullPath = (path as NSString).appendingPathComponent(item)
                try? fileManager.removeItem(atPath: fullPath)
            }
        }
    }
    
    private func calculateFolderSize(path: String) -> UInt64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            if let res = try? fileURL.resourceValues(forKeys: [.fileSizeKey]), let size = res.fileSize {
                total += UInt64(size)
            }
        }
        return total
    }
}
