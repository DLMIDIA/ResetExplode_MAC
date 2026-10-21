import Foundation

public struct CPUCoreLoad: Identifiable, Equatable, Sendable {
    public var id: Int
    public let name: String
    public let isPerformance: Bool
    public let usagePercent: Double
}

public struct CPUInfo: Equatable, Sendable {
    public let name: String
    public let totalCores: Int
    public let pCores: Int
    public let eCores: Int
    public let architecture: String
    public let overallUsage: Double
    public let coreLoads: [CPUCoreLoad]
}

public struct SwapMemoryInfo: Equatable, Sendable {
    public let totalMB: Double
    public let usedMB: Double
    public let freeMB: Double
}

public enum MemoryPressureState: String, Equatable, Sendable {
    case normal = "Normal"
    case warning = "Atenção"
    case critical = "Crítica"
}

public struct RAMInfo: Equatable, Sendable {
    public let totalGB: Double
    public let activeGB: Double
    public let wiredGB: Double
    public let compressedGB: Double
    public let freeGB: Double
    public let pressure: MemoryPressureState
    public let swap: SwapMemoryInfo
    
    public var usedGB: Double {
        return activeGB + wiredGB + compressedGB
    }
    
    public var usagePercent: Double {
        return totalGB > 0 ? min(100.0, max(0.0, (usedGB / totalGB) * 100.0)) : 0
    }
}

public struct ProcessMetric: Identifiable, Equatable, Sendable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let name: String
    public let cpuPercent: Double
    public let memoryPercent: Double
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
    public let cycleCount: Int
    public let designCycleCount: Int
    public let healthPercentage: Double
    public let isCharging: Bool
    public let isFullyCharged: Bool
    public let isPluggedIn: Bool
    public let voltageMV: Int
    public let designCapacityMAh: Int
    public let fullChargeCapacityMAh: Int
    public let condition: String
    public let statusDescription: String
    
    public static var desktopPlaceholder: BatteryInfo {
        BatteryInfo(
            isPresent: false,
            percentage: 100,
            cycleCount: 0,
            designCycleCount: 1000,
            healthPercentage: 100.0,
            isCharging: false,
            isFullyCharged: true,
            isPluggedIn: true,
            voltageMV: 0,
            designCapacityMAh: 0,
            fullChargeCapacityMAh: 0,
            condition: "Alimentação AC",
            statusDescription: "Desktop Mac (Alimentação Direta)"
        )
    }
}

public struct CPUBenchResult: Equatable, Sendable {
    public let score: Double
    public let samplesPerSec: Double
    public let durationSeconds: Double
    public let isMultiCore: Bool
}

public struct MemoryBenchResult: Equatable, Sendable {
    public let bandwidthGBs: Double
    public let latencyNs: Double
    public let durationSeconds: Double
}

public struct DiskBenchResult: Equatable, Sendable {
    public let volumeName: String
    public let seqReadMBs: Double
    public let seqWriteMBs: Double
    public let random4kReadIOPS: Double
    public let random4kWriteIOPS: Double
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
    public let gatewayIP: String
    public let dnsServers: [String]
    public let macAddress: String
}

public struct ConnectedDisplay: Identifiable, Equatable, Sendable {
    public var id: String { name + resolution }
    public let name: String
    public let resolution: String
    public let refreshRate: String
    public let isMain: Bool
    public let isBuiltIn: Bool
}

public struct ConnectedUSBDevice: Identifiable, Equatable, Sendable {
    public var id: String { name + vendor }
    public let name: String
    public let vendor: String
}

public struct ConnectedBluetoothDevice: Identifiable, Equatable, Sendable {
    public var id: String { address }
    public let name: String
    public let address: String
    public let isConnected: Bool
}

public struct ConnectedDevicesSummary: Equatable, Sendable {
    public let displays: [ConnectedDisplay]
    public let usbDevices: [ConnectedUSBDevice]
    public let bluetoothDevices: [ConnectedBluetoothDevice]
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
