import Foundation

public struct CPUInfo: Equatable, Sendable {
    public let name: String
    public let totalCores: Int
    public let pCores: Int
    public let eCores: Int
    public let architecture: String
}

public struct RAMInfo: Equatable, Sendable {
    public let totalGB: Double
    public let activeGB: Double
    public let wiredGB: Double
    public let compressedGB: Double
    public let freeGB: Double
    
    public var usedGB: Double {
        return activeGB + wiredGB + compressedGB
    }
    
    public var usagePercent: Double {
        return totalGB > 0 ? min(100.0, max(0.0, (usedGB / totalGB) * 100.0)) : 0
    }
}

public struct GPUInfo: Equatable, Sendable {
    public let name: String
    public let supportsRayTracing: Bool
    public let isUnifiedMemory: Bool
}

public struct DiskVolume: Identifiable, Hashable, Equatable, Sendable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let isInternal: Bool
    public let isRemovable: Bool
    public let totalGB: Double
    public let freeGB: Double
    public let usedGB: Double
    
    public var usagePercent: Double {
        return totalGB > 0 ? min(100.0, max(0.0, (usedGB / totalGB) * 100.0)) : 0
    }
}

public typealias DiskInfo = DiskVolume


public struct BatteryInfo: Equatable, Sendable {
    public let isPresent: Bool
    public let percentage: Int
    public let isCharging: Bool
    public let sourceState: String
}

public struct CPUBenchResult: Equatable, Sendable {
    public let score: Double
    public let samplesPerSec: Double
    public let durationSeconds: Double
    public let isMultiCore: Bool
}

public struct DiskBenchResult: Equatable, Sendable {
    public let volumeName: String
    public let seqReadMBs: Double
    public let seqWriteMBs: Double
    public let durationSeconds: Double
}

public struct SerialPortInfo: Identifiable, Equatable, Sendable {
    public var id: String { path }
    public let path: String
    public let name: String
    public let deviceType: String
}

public struct NetworkStats: Equatable, Sendable {
    public let downloadSpeedKBps: Double
    public let uploadSpeedKBps: Double
    public let localIP: String
    public let activeInterface: String
}

public struct CleanableCaches: Equatable, Sendable {
    public let userCachesBytes: UInt64
    public let systemLogsBytes: UInt64
    public let trashBytes: UInt64
    
    public var totalBytes: UInt64 {
        return userCachesBytes + systemLogsBytes + trashBytes
    }
    
    public var totalMB: Double {
        return Double(totalBytes) / (1024.0 * 1024.0)
    }
    
    public var totalGB: Double {
        return Double(totalBytes) / (1024.0 * 1024.0 * 1024.0)
    }
}
