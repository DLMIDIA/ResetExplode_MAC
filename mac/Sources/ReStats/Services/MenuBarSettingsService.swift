import Foundation

public final class MenuBarSettingsService: @unchecked Sendable {
    public static let shared = MenuBarSettingsService()
    
    private let keyShowIcon = "br.com.dlmidia.resetexplode.menuBarShowIcon"
    private let keyShowCpu = "br.com.dlmidia.resetexplode.menuBarShowCpu"
    private let keyShowRam = "br.com.dlmidia.resetexplode.menuBarShowRam"
    private let keyShowNet = "br.com.dlmidia.resetexplode.menuBarShowNet"
    private let keyShowBattery = "br.com.dlmidia.resetexplode.menuBarShowBattery"
    
    private init() {
        if UserDefaults.standard.object(forKey: keyShowIcon) == nil {
            UserDefaults.standard.set(true, forKey: keyShowIcon)
            UserDefaults.standard.set(true, forKey: keyShowCpu)
            UserDefaults.standard.set(true, forKey: keyShowRam)
            UserDefaults.standard.set(true, forKey: keyShowNet)
            UserDefaults.standard.set(false, forKey: keyShowBattery)
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
    
    public func formattedStatusText(cpu: Double, ram: Double, downloadKBps: Double, batteryPct: Int) -> String {
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
        if showBattery {
            segments.append("🔋\(batteryPct)%")
        }
        
        if segments.isEmpty {
            return ""
        }
        return " " + segments.joined(separator: " | ")
    }
}
