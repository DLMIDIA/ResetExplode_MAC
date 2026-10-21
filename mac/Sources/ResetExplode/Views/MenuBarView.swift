import SwiftUI
import AppKit

public struct MenuBarView: View {
    @State private var ram = HardwareService.shared.getRAMInfo()
    @State private var net = NetworkService.shared.getCurrentStats()
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RESET EXPLODE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                Spacer()
                Text("Apple Silicon")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // RAM Status
            HStack {
                Image(systemName: "memorychip")
                    .foregroundColor(.green)
                Text("RAM:")
                    .font(.caption)
                Spacer()
                Text(String(format: "%.1f GB (%.0f%%)", ram.usedGB, ram.usagePercent))
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            // Rede Status
            HStack {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.green)
                Text(formatSpeed(kbps: net.downloadSpeedKBps))
                    .font(.caption)
                Spacer()
                Image(systemName: "arrow.up.circle")
                    .foregroundColor(.blue)
                Text(formatSpeed(kbps: net.uploadSpeedKBps))
                    .font(.caption)
            }
            
            Divider()
            
            Button("🧹 Limpeza Rápida de RAM") {
                Task {
                    _ = await OptimizerService.shared.optimizeMemory()
                    await MainActor.run {
                        self.ram = HardwareService.shared.getRAMInfo()
                    }
                }
            }
            
            Button("Abrir Painel Completo") {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where !(window is NSPanel) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            
            Divider()
            
            Button("Encerrar ResetExplode") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 230)
        .onReceive(timer) { _ in
            ram = HardwareService.shared.getRAMInfo()
            net = NetworkService.shared.getCurrentStats()
        }
    }
    
    private func formatSpeed(kbps: Double) -> String {
        if kbps >= 1024.0 {
            return String(format: "%.1f M/s", kbps / 1024.0)
        } else {
            return String(format: "%.0f K/s", kbps)
        }
    }
}
