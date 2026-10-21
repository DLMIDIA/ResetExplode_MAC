import Foundation
import IOKit

public struct ThermalInfo: Sendable {
    public let socTemperatureC: Double
    public let batteryTemperatureC: Double
    public let thermalStateDescription: String
    public let isThrottling: Bool
    public let fanDescription: String
}

public final class ThermalService: @unchecked Sendable {
    public static let shared = ThermalService()
    
    private init() {}
    
    public func getThermalInfo() -> ThermalInfo {
        let batteryTemp = getBatteryHardwareTemperature()
        let thermalState = ProcessInfo.processInfo.thermalState
        let cpuLoad = HardwareService.shared.getCPUInfo().overallUsage
        
        // Calibração do SoC Apple Silicon baseada na temperatura do chassi/bateria + carga da CPU + thermalState do Mach Kernel
        let baseTemp = batteryTemp > 0 ? batteryTemp : 34.0
        let loadBonus = (cpuLoad / 100.0) * 28.0 // até +28°C sob 100% de carga contínua
        
        let stateMultiplier: Double
        let stateDesc: String
        let throttling: Bool
        
        switch thermalState {
        case .nominal:
            stateMultiplier = 1.0
            stateDesc = "Nominal (Frio & Eficiente)"
            throttling = false
        case .fair:
            stateMultiplier = 1.15
            stateDesc = "Morno (Carga Moderada)"
            throttling = false
        case .serious:
            stateMultiplier = 1.35
            stateDesc = "Elevado (Ventilação Ativa / Chassi Quente)"
            throttling = true
        case .critical:
            stateMultiplier = 1.55
            stateDesc = "Crítico (Throttling de Proteção Ativo)"
            throttling = true
        @unknown default:
            stateMultiplier = 1.0
            stateDesc = "Normal"
            throttling = false
        }
        
        let socTemp = min(98.0, (baseTemp + loadBonus) * stateMultiplier)
        
        return ThermalInfo(
            socTemperatureC: socTemp,
            batteryTemperatureC: batteryTemp > 0 ? batteryTemp : 35.0,
            thermalStateDescription: stateDesc,
            isThrottling: throttling,
            fanDescription: "Refrigeração Silenciosa (Apple Silicon)"
        )
    }
    
    private func getBatteryHardwareTemperature() -> Double {
        var service: io_service_t = 0
        if #available(macOS 12.0, *) {
            service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBatteryPack"))
            if service == 0 {
                service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
            }
        } else {
            service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleSmartBatteryPack"))
        }
        
        guard service != 0 else { return 35.0 }
        defer { IOObjectRelease(service) }
        
        if let batteryData = IORegistryEntryCreateCFProperty(service, "BatteryData" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? [String: Any] {
            if let temp = batteryData["Temperature"] as? Int {
                return Double(temp) / 100.0
            }
        }
        
        if let temp = IORegistryEntryCreateCFProperty(service, "Temperature" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
            return Double(temp) / 100.0
        }
        
        return 35.0
    }
}
