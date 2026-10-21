import Foundation
import Metal
import Darwin
import IOKit.ps
import IOKit
import AppKit

public final class HardwareService: @unchecked Sendable {
    public static let shared = HardwareService()
    
    // Armazenamento de estado anterior para delta do cálculo por núcleo (técnica do stats)
    private var prevCpuInfo: processor_info_array_t?
    private var numPrevCpuInfo: mach_msg_type_number_t = 0
    private let cpuLock = NSLock()
    
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
        
        // Cálculo de carga por núcleo via Mach Kernel (referência exelban/stats)
        let (overall, coreLoads) = readCpuCoreLoads(totalCores: Int(ncpu), pCores: Int(pCores))
        
        return CPUInfo(
            name: name.isEmpty ? "Apple Silicon" : name,
            totalCores: Int(ncpu),
            pCores: Int(pCores),
            eCores: Int(eCores),
            architecture: "ARM64 (Apple Silicon)",
            overallUsage: overall,
            coreLoads: coreLoads
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
        
        // Nível de pressão de memória (referência exelban/stats)
        var intSize: size_t = MemoryLayout<UInt32>.size
        var pressureLevel: UInt32 = 0
        sysctlbyname("kern.memorystatus_vm_pressure_level", &pressureLevel, &intSize, nil, 0)
        let pressureState: MemoryPressureState
        switch pressureLevel {
        case 2: pressureState = .warning
        case 4: pressureState = .critical
        default: pressureState = .normal
        }
        
        // Uso de Swap do macOS
        var stringSize: size_t = MemoryLayout<xsw_usage>.size
        var swap: xsw_usage = xsw_usage()
        sysctlbyname("vm.swapusage", &swap, &stringSize, nil, 0)
        let swapInfo = SwapMemoryInfo(
            totalMB: Double(swap.xsu_total) / 1048576.0,
            usedMB: Double(swap.xsu_used) / 1048576.0,
            freeMB: Double(swap.xsu_avail) / 1048576.0
        )
        
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
                freeGB: free,
                pressure: pressureState,
                swap: swapInfo
            )
        }
        
        return RAMInfo(
            totalGB: totalGB,
            activeGB: 0,
            wiredGB: 0,
            compressedGB: 0,
            freeGB: totalGB,
            pressure: pressureState,
            swap: swapInfo
        )
    }
    
    private var cachedTopProcesses: [ProcessMetric] = []
    private var lastProcessFetch: CFAbsoluteTime = 0
    private let procLock = NSLock()
    
    public func getTopProcesses(limit: Int = 5) -> [ProcessMetric] {
        procLock.lock()
        let now = CFAbsoluteTimeGetCurrent()
        let shouldRefresh = (now - lastProcessFetch) > 2.0
        let cached = cachedTopProcesses
        procLock.unlock()
        
        if shouldRefresh {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                self?.refreshTopProcessesInternal(limit: limit)
            }
        }
        
        return cached.isEmpty ? [] : Array(cached.prefix(limit))
    }
    
    private func refreshTopProcessesInternal(limit: Int) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-Aceo", "pid,pcpu,pmem,comm", "-r"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8) ?? ""
        
        var list: [ProcessMetric] = []
        for line in text.components(separatedBy: "\n").dropFirst() {
            let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: " ").filter { !$0.isEmpty }
            if parts.count >= 4 {
                let pid = Int32(parts[0]) ?? 0
                let cpu = Double(parts[1].replacingOccurrences(of: ",", with: ".")) ?? 0
                let mem = Double(parts[2].replacingOccurrences(of: ",", with: ".")) ?? 0
                
                var name = parts[3]
                if let app = NSRunningApplication(processIdentifier: pid), let appName = app.localizedName {
                    name = appName
                } else if let lastSlash = name.lastIndex(of: "/") {
                    name = String(name[name.index(after: lastSlash)...])
                }
                
                list.append(ProcessMetric(pid: pid, name: name, cpuPercent: cpu, memoryPercent: mem))
                if list.count >= max(10, limit) {
                    break
                }
            }
        }
        
        procLock.lock()
        self.cachedTopProcesses = list
        self.lastProcessFetch = CFAbsoluteTimeGetCurrent()
        procLock.unlock()
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
        let match = IOServiceMatching("AppleSmartBattery")
        let service = IOServiceGetMatchingService(kIOMainPortDefault, match)
        
        if service != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any] {
                IOObjectRelease(service)
                
                let cycleCount = dict["CycleCount"] as? Int ?? 0
                let designCycleCount = dict["DesignCycleCount9C"] as? Int ?? 1000
                let percentage = dict["CurrentCapacity"] as? Int ?? 100
                let isCharging = (dict["IsCharging"] as? Bool) ?? ((dict["IsCharging"] as? Int) == 1)
                let isFullyCharged = (dict["FullyCharged"] as? Bool) ?? ((dict["FullyCharged"] as? Int) == 1)
                let isPluggedIn = (dict["ExternalConnected"] as? Bool) ?? ((dict["ExternalConnected"] as? Int) == 1)
                let voltage = dict["Voltage"] as? Int ?? 0
                
                var designCap = 4629
                var fullCap = 4483
                if let batteryData = dict["BatteryData"] as? [String: Any] {
                    designCap = batteryData["DesignCapacity"] as? Int ?? designCap
                    fullCap = batteryData["FullChargeCapacity"] as? Int ?? fullCap
                }
                
                var health = 100.0
                if designCap > 0 {
                    health = min(100.0, max(0.0, (Double(fullCap) / Double(designCap)) * 100.0))
                }
                
                let statusDesc: String
                if isPluggedIn {
                    if isFullyCharged {
                        statusDesc = "Tomada (Carga Completa 100%)"
                    } else if isCharging {
                        statusDesc = "Tomada (Carregando...)"
                    } else {
                        statusDesc = "Tomada (Alimentação Direta)"
                    }
                } else {
                    statusDesc = "Bateria (Descarregando)"
                }
                
                let condition = health >= 80.0 ? "Normal (Excelente)" : "Serviço Recomendado"
                
                return BatteryInfo(
                    isPresent: true,
                    percentage: percentage,
                    cycleCount: cycleCount,
                    designCycleCount: designCycleCount,
                    healthPercentage: health,
                    isCharging: isCharging,
                    isFullyCharged: isFullyCharged,
                    isPluggedIn: isPluggedIn,
                    voltageMV: voltage,
                    designCapacityMAh: designCap,
                    fullChargeCapacityMAh: fullCap,
                    condition: condition,
                    statusDescription: statusDesc
                )
            }
            IOObjectRelease(service)
        }
        
        return BatteryInfo.desktopPlaceholder
    }
    
    // Leitura nativa de núcleos via Mach Kernel (referência exelban/stats)
    private func readCpuCoreLoads(totalCores: Int, pCores: Int) -> (Double, [CPUCoreLoad]) {
        cpuLock.lock()
        defer { cpuLock.unlock() }
        
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        
        let kerr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo)
        guard kerr == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return (0.0, [])
        }
        
        var loads: [CPUCoreLoad] = []
        var totalUsageSum = 0.0
        
        if let prevCpuInfo = self.prevCpuInfo {
            for i in 0..<Int(numCPUsU) {
                let user = UInt32(bitPattern: cpuInfo[Int(CPU_STATE_MAX * Int32(i) + CPU_STATE_USER)])
                    &- UInt32(bitPattern: prevCpuInfo[Int(CPU_STATE_MAX * Int32(i) + CPU_STATE_USER)])
                let system = UInt32(bitPattern: cpuInfo[Int(CPU_STATE_MAX * Int32(i) + CPU_STATE_SYSTEM)])
                    &- UInt32(bitPattern: prevCpuInfo[Int(CPU_STATE_MAX * Int32(i) + CPU_STATE_SYSTEM)])
                let nice = UInt32(bitPattern: cpuInfo[Int(CPU_STATE_MAX * Int32(i) + CPU_STATE_NICE)])
                    &- UInt32(bitPattern: prevCpuInfo[Int(CPU_STATE_MAX * Int32(i) + CPU_STATE_NICE)])
                let idle = UInt32(bitPattern: cpuInfo[Int(CPU_STATE_MAX * Int32(i) + CPU_STATE_IDLE)])
                    &- UInt32(bitPattern: prevCpuInfo[Int(CPU_STATE_MAX * Int32(i) + CPU_STATE_IDLE)])
                
                let inUse = UInt64(user) + UInt64(system) + UInt64(nice)
                let total = inUse + UInt64(idle)
                let usage = total > 0 ? min(100.0, max(0.0, (Double(inUse) / Double(total)) * 100.0)) : 0.0
                
                let isPerf = i < pCores
                let coreName = isPerf ? "P-Core \(i + 1)" : "E-Core \(i - pCores + 1)"
                
                loads.append(CPUCoreLoad(id: i, name: coreName, isPerformance: isPerf, usagePercent: usage))
                totalUsageSum += usage
            }
            
            let prevSize = vm_size_t(numPrevCpuInfo) * vm_size_t(MemoryLayout<integer_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: prevCpuInfo)), prevSize)
        } else {
            for i in 0..<Int(numCPUsU) {
                let isPerf = i < pCores
                let coreName = isPerf ? "P-Core \(i + 1)" : "E-Core \(i - pCores + 1)"
                loads.append(CPUCoreLoad(id: i, name: coreName, isPerformance: isPerf, usagePercent: 5.0))
            }
        }
        
        self.prevCpuInfo = cpuInfo
        self.numPrevCpuInfo = numCpuInfo
        
        let avgUsage = loads.isEmpty ? 0.0 : (totalUsageSum / Double(loads.count))
        return (avgUsage, loads)
    }
}
