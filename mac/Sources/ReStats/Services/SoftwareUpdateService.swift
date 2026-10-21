import Foundation
import AppKit

public struct OSUpdateInfo: Sendable {
    public let osVersion: String
    public let isChecking: Bool
    public let hasUpdates: Bool
    public let statusMessage: String
    public let lastCheckedDate: Date?
}

@MainActor
public final class SoftwareUpdateService: ObservableObject {
    public static let shared = SoftwareUpdateService()
    
    @Published public var isChecking: Bool = false
    @Published public var hasUpdates: Bool = false
    @Published public var statusMessage: String = "Pronto para verificar atualizações"
    @Published public var lastChecked: Date? = nil
    
    public var currentOSVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }
    
    private init() {}
    
    public func checkForUpdates() {
        guard !isChecking else { return }
        isChecking = true
        statusMessage = "Buscando atualizações de software no catálogo da Apple..."
        
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/softwareupdate")
            process.arguments = ["--list"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                await MainActor.run {
                    self.isChecking = false
                    self.lastChecked = Date()
                    
                    if output.contains("No new software available") {
                        self.hasUpdates = false
                        self.statusMessage = "O seu Mac está atualizado! Nenhuma nova atualização pendente."
                    } else if output.contains("*") || output.contains("Software Update found") {
                        self.hasUpdates = true
                        self.statusMessage = "Novas atualizações encontradas para o macOS!"
                    } else {
                        self.hasUpdates = false
                        self.statusMessage = "Sistema verificado com sucesso."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isChecking = false
                    self.statusMessage = "Não foi possível conectar ao servidor de atualizações."
                }
            }
        }
    }
    
    public func openSystemUpdateSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.softwareupdate") {
            NSWorkspace.shared.open(url)
        }
    }
}
