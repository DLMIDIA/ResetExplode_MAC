import Foundation

public final class MenuBarSettingsService: @unchecked Sendable {
    public static let shared = MenuBarSettingsService()
    
    private let keyShowIcon = "br.com.dlmidia.restats.menuBarShowIcon"
    private let keyShowCpu = "br.com.dlmidia.restats.menuBarShowCpu"
    private let keyShowRam = "br.com.dlmidia.restats.menuBarShowRam"
    private let keyShowNet = "br.com.dlmidia.restats.menuBarShowNet"
    private let keyShowBattery = "br.com.dlmidia.restats.menuBarShowBattery"
    private let keyShowDisk = "br.com.dlmidia.restats.menuBarShowDisk"
    private let keyShowTemp = "br.com.dlmidia.restats.menuBarShowTemp"
    private let keyMonitoredDiskPaths = "br.com.dlmidia.restats.monitoredDisks"
    
    private init() {
        if UserDefaults.standard.object(forKey: keyShowIcon) == nil {
            UserDefaults.standard.set(true, forKey: keyShowIcon)
            UserDefaults.standard.set(true, forKey: keyShowCpu)
            UserDefaults.standard.set(true, forKey: keyShowRam)
            UserDefaults.standard.set(true, forKey: keyShowNet)
            UserDefaults.standard.set(false, forKey: keyShowBattery)
            UserDefaults.standard.set(false, forKey: keyShowDisk)
            UserDefaults.standard.set(false, forKey: keyShowTemp)
            UserDefaults.standard.set(["/"], forKey: keyMonitoredDiskPaths)
        }
    }
    
    public var showIcon: Bool {
        get { UserDefaults.standard.bool(forKey: keyShowIcon) }
        set { UserDefaults.standard.set(newValue, forKey: keyShowIcon) }
    }
    
    public var showCpu: Bool {
        get { UserDefaults.standard.bool(forKey: keyShowCpu) }
        set { UserDefaults.standard.set(newValue, forKey: keyShowCpu) }
    }
    
    public var showRam: Bool {
        get { UserDefaults.standard.bool(forKey: keyShowRam) }
        set { UserDefaults.standard.set(newValue, forKey: keyShowRam) }
    }
    
    public var showNet: Bool {
        get { UserDefaults.standard.bool(forKey: keyShowNet) }
        set { UserDefaults.standard.set(newValue, forKey: keyShowNet) }
    }
    
    public var showBattery: Bool {
        get { UserDefaults.standard.bool(forKey: keyShowBattery) }
        set { UserDefaults.standard.set(newValue, forKey: keyShowBattery) }
    }
    
    public var showDisk: Bool {
        get { UserDefaults.standard.bool(forKey: keyShowDisk) }
        set { UserDefaults.standard.set(newValue, forKey: keyShowDisk) }
    }
    
    public var showTemp: Bool {
        get { UserDefaults.standard.bool(forKey: keyShowTemp) }
        set { UserDefaults.standard.set(newValue, forKey: keyShowTemp) }
    }
    
    public var monitoredDiskPaths: [String] {
        get { UserDefaults.standard.stringArray(forKey: keyMonitoredDiskPaths) ?? ["/"] }
        set { UserDefaults.standard.set(newValue, forKey: keyMonitoredDiskPaths) }
    }
    
    public func isDiskMonitored(path: String) -> Bool {
        return monitoredDiskPaths.contains(path)
    }
    
    public func toggleDiskMonitoring(path: String) {
        var current = monitoredDiskPaths
        if let idx = current.firstIndex(of: path) {
            current.remove(at: idx)
        } else {
            current.append(path)
        }
        monitoredDiskPaths = current
    }
    
    public func formattedStatusText(
        cpu: Double,
        ram: Double,
        downloadKBps: Double,
        batteryPct: Int,
        socTemp: Double = 0,
        volumes: [DiskVolume] = []
    ) -> String {
        var segments: [String] = []
        
        if showCpu {
            segments.append(String(format: "CPU %.0f%%", cpu))
        }
        if showRam {
            segments.append(String(format: "RAM %.0f%%", ram))
        }
        if showNet {
            let speedStr = downloadKBps >= 1024.0 ? String(format: "%.1fM", downloadKBps / 1024.0) : String(format: "%.0fK", downloadKBps)
            segments.append("↓\(speedStr)")
        }
        if showTemp && socTemp > 0 {
            segments.append(String(format: "%.0f°C", socTemp))
        }
        if showBattery {
            segments.append("🔋\(batteryPct)%")
        }
        if showDisk {
            let monitored = volumes.filter { monitoredDiskPaths.contains($0.path) }
            for vol in monitored {
                let namePrefix = vol.path == "/" ? "SSD" : vol.name.prefix(6)
                segments.append(String(format: "💾 %@: %.0fG", String(namePrefix), vol.freeGB))
            }
        }
        
        if segments.isEmpty {
            return ""
        }
        return " " + segments.joined(separator: " | ")
    }
}
