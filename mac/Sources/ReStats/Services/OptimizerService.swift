import Foundation
import AppKit

public struct AppMemoryItem: Identifiable, Sendable {
    public var id: pid_t { pid }
    public let pid: pid_t
    public let name: String
    public let bundleID: String
    public let icon: NSImage?
}

public final class OptimizerService: @unchecked Sendable {
    public static let shared = OptimizerService()
    
    private init() {}
    
    public func getRunningApps() -> [AppMemoryItem] {
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isTerminated
        }
        
        return apps.map { app in
            AppMemoryItem(
                pid: app.processIdentifier,
                name: app.localizedName ?? "App",
                bundleID: app.bundleIdentifier ?? "",
                icon: app.icon
            )
        }
    }
    
    public func optimizeMemory() async -> Double {
        let ramBefore = HardwareService.shared.getRAMInfo().freeGB
        
        // Solicita ao sistema liberação de caches inativos em background
        let task = Process()
        task.launchPath = "/usr/bin/purge"
        try? task.run()
        task.waitUntilExit()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let ramAfter = HardwareService.shared.getRAMInfo().freeGB
        
        return max(0.0, ramAfter - ramBefore)
    }
}
