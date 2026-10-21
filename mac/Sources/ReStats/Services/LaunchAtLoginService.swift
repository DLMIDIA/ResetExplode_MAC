import Foundation
import ServiceManagement

public final class LaunchAtLoginService: @unchecked Sendable {
    public static let shared = LaunchAtLoginService()
    
    private let promptedKey = "br.com.dlmidia.resetexplode.launchAtLoginPrompted"
    
    private init() {}
    
    public var hasBeenPrompted: Bool {
        get { UserDefaults.standard.bool(forKey: promptedKey) }
        set { UserDefaults.standard.set(newValue, forKey: promptedKey) }
    }
    
    public var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    public func setEnabled(_ enable: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status == .enabled { return true }
                    try SMAppService.mainApp.register()
                } else {
                    if SMAppService.mainApp.status == .notRegistered { return true }
                    try SMAppService.mainApp.unregister()
                }
                return true
            } catch {
                print("SMAppService registration error: \(error)")
                return false
            }
        }
        return false
    }
}
