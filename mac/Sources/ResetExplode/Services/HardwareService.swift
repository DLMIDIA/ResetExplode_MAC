import Foundation
import Metal
import Darwin
import IOKit.ps

public final class HardwareService: @unchecked Sendable {
    public static let shared = HardwareService()
    
    private init() {}
    
    public func getMacModelName() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return model.withUnsafeBufferPointer { ptr in
            ptr.baseAddress != nil ? String(cString: ptr.baseAddress!) : "Mac"
        }
    }
    
    public func getCPUInfo() -> CPUInfo {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        let name = machine.withUnsafeBufferPointer { ptr in
            ptr.baseAddress != nil ? String(cString: ptr.baseAddress!) : "Apple Silicon"
        }
        
        var ncpu: Int32 = 0
        size = MemoryLayout<Int32>.size
        sysctlbyname("hw.ncpu", &ncpu, &size, nil, 0)
        
        var pCores: Int32 = 0
        var eCores: Int32 = 0
        sysctlbyname("hw.perflevel0.logicalcpu", &pCores, &size, nil, 0)
        sysctlbyname("hw.perflevel1.logicalcpu", &eCores, &size, nil, 0)
        
        return CPUInfo(
            name: name.isEmpty ? "Apple Silicon" : name,
            totalCores: Int(ncpu),
            pCores: Int(pCores),
            eCores: Int(eCores),
            architecture: "ARM64 (Apple Silicon)"
        )
    }
    
    public func getRAMInfo() -> RAMInfo {
        var memsize: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &memsize, &size, nil, 0)
        let totalGB = Double(memsize) / (1024.0 * 1024.0 * 1024.0)
        
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let kerr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let pageSize = UInt64(sysconf(_SC_PAGESIZE))
            let active = Double(UInt64(stats.active_count) * pageSize) / (1024.0 * 1024.0 * 1024.0)
            let wired = Double(UInt64(stats.wire_count) * pageSize) / (1024.0 * 1024.0 * 1024.0)
            let compressed = Double(UInt64(stats.compressor_page_count) * pageSize) / (1024.0 * 1024.0 * 1024.0)
            let free = Double(UInt64(stats.free_count) * pageSize) / (1024.0 * 1024.0 * 1024.0)
            
            return RAMInfo(
                totalGB: totalGB,
                activeGB: active,
                wiredGB: wired,
                compressedGB: compressed,
                freeGB: free
            )
        }
        
        return RAMInfo(totalGB: totalGB, activeGB: 0, wiredGB: 0, compressedGB: 0, freeGB: totalGB)
    }
    
    public func getGPUInfo() -> GPUInfo {
        if let device = MTLCreateSystemDefaultDevice() {
            return GPUInfo(
                name: device.name,
                supportsRayTracing: device.supportsRaytracing,
                isUnifiedMemory: true
            )
        }
        return GPUInfo(name: "Apple GPU", supportsRayTracing: false, isUnifiedMemory: true)
    }
    
    public func getDiskInfo() -> DiskInfo {
        var stat = statvfs()
        if statvfs("/", &stat) == 0 {
            let totalBytes = UInt64(stat.f_blocks) * UInt64(stat.f_frsize)
            let freeBytes = UInt64(stat.f_bavail) * UInt64(stat.f_frsize)
            let usedBytes = totalBytes > freeBytes ? (totalBytes - freeBytes) : 0
            
            let totalGB = Double(totalBytes) / (1024.0 * 1024.0 * 1024.0)
            let freeGB = Double(freeBytes) / (1024.0 * 1024.0 * 1024.0)
            let usedGB = Double(usedBytes) / (1024.0 * 1024.0 * 1024.0)
            
            return DiskVolume(name: "Macintosh HD", path: "/", isInternal: true, isRemovable: false, totalGB: totalGB, freeGB: freeGB, usedGB: usedGB)
        }
        return DiskVolume(name: "Macintosh HD", path: "/", isInternal: true, isRemovable: false, totalGB: 0, freeGB: 0, usedGB: 0)
    }
    
    public func getBatteryInfo() -> BatteryInfo {
        if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
           !sources.isEmpty {
            for source in sources {
                if let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                    let cap = desc[kIOPSCurrentCapacityKey] as? Int ?? 100
                    let isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
                    let state = desc[kIOPSPowerSourceStateKey] as? String ?? "AC Power"
                    return BatteryInfo(isPresent: true, percentage: cap, isCharging: isCharging, sourceState: state)
                }
            }
        }
        return BatteryInfo(isPresent: false, percentage: 100, isCharging: false, sourceState: "Desktop / Tomada")
    }
}
