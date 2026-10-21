import SwiftUI
import AppKit

public struct MenuBarView: View {
    @State private var cpu = HardwareService.shared.getCPUInfo()
    @State private var ram = HardwareService.shared.getRAMInfo()
    @State private var net = NetworkService.shared.getCurrentStats()
    @State private var battery = HardwareService.shared.getBatteryInfo()
    @State private var topProcesses = HardwareService.shared.getTopProcesses(limit: 3)
    
    @State private var isCleaning = false
    @State private var cleanMessage: String?
    @State private var launchAtLogin = LaunchAtLoginService.shared.isEnabled
    @State private var brightness: Float = DisplayBrightnessService.shared.getBrightness()
    
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(.cyan)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 1) {
                    Text("RESET EXPLODE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Status & Telemetria Apple Silicon")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
            
            Divider()
            
            // CPU Load (Inspirado em Stats)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "cpu")
                        .foregroundColor(.cyan)
                    Text("Processador:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f%%", cpu.overallUsage))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                }
                ProgressView(value: cpu.overallUsage, total: 100.0)
                    .accentColor(.cyan)
            }
            
            // RAM Bar & Pressão (Inspirado em Stats)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "memorychip")
                        .foregroundColor(.green)
                    Text("Memória Unificada:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(String(format: "%.1fG / %.0fG (%.0f%%)", ram.usedGB, ram.totalGB, ram.usagePercent))
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        Text(ram.pressure.rawValue)
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(pressureColor.opacity(0.2))
                            .foregroundColor(pressureColor)
                            .cornerRadius(3)
                    }
                }
                ProgressView(value: ram.usagePercent, total: 100.0)
                    .accentColor(pressureColor)
            }
            
            // Rede (Download / Upload)
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                    Text(formatSpeed(kbps: net.downloadSpeedKBps))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                    Text(formatSpeed(kbps: net.uploadSpeedKBps))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.04))
            .cornerRadius(6)
            
            // Top Processos (Referência exelban/stats)
            if !topProcesses.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MAIORES CONSUMIDORES (CPU)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    ForEach(topProcesses) { p in
                        HStack {
                            Text(p.name)
                                .font(.system(size: 11))
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "%.1f%%", p.cpuPercent))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(p.cpuPercent > 20 ? .orange : .secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.03))
                .cornerRadius(6)
            }
            
            // Bateria e Ciclos
            if battery.isPresent {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: battery.isPluggedIn ? "battery.100.bolt" : "battery.75")
                            .foregroundColor(battery.percentage < 20 ? .red : .yellow)
                        Text("Bateria (\(battery.percentage)%):")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(battery.cycleCount) / \(battery.designCycleCount) ciclos")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    Text(battery.statusDescription)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
            }
            
            if let msg = cleanMessage {
                Text(msg)
                    .font(.caption2)
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 4)
            }
            
            // Brilho dos Monitores
            HStack(spacing: 8) {
                Image(systemName: "sun.min")
                    .foregroundColor(.secondary)
                    .font(.caption2)
                Slider(value: Binding(
                    get: { Double(brightness) },
                    set: { val in
                        brightness = Float(val)
                        _ = DisplayBrightnessService.shared.setBrightness(brightness)
                    }
                ), in: 0.05...1.0)
                .accentColor(.yellow)
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                    .font(.caption2)
                Text("\(Int(brightness * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .frame(width: 32)
            }
            .padding(6)
            .background(Color.white.opacity(0.03))
            .cornerRadius(6)
            
            Divider()
            
            // Ações Rápidas
            HStack(spacing: 8) {
                Button {
                    cleanRAM()
                } label: {
                    HStack(spacing: 4) {
                        if isCleaning {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Limpar RAM")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isCleaning)
                
                Button {
                    flushDNS()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "network")
                        Text("Flush DNS")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Toggle("Iniciar com o macOS", isOn: $launchAtLogin)
                .font(.caption)
                .onChange(of: launchAtLogin) { val in
                    _ = LaunchAtLoginService.shared.setEnabled(val)
                }
            
            Divider()
            
            // Botões de Rodapé
            HStack {
                Button("Abrir Painel Completo") {
                    AppDelegate.shared?.popover?.performClose(nil)
                    AppDelegate.shared?.openMainWindow()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.small)
                
                Spacer()
                
                Button("Encerrar") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(width: 300)
        .onReceive(timer) { _ in
            cpu = HardwareService.shared.getCPUInfo()
            ram = HardwareService.shared.getRAMInfo()
            net = NetworkService.shared.getCurrentStats()
            battery = HardwareService.shared.getBatteryInfo()
            topProcesses = HardwareService.shared.getTopProcesses(limit: 3)
            launchAtLogin = LaunchAtLoginService.shared.isEnabled
        }
    }
    
    private var pressureColor: Color {
        switch ram.pressure {
        case .normal: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }
    
    private func cleanRAM() {
        isCleaning = true
        cleanMessage = "Liberando páginas inativas..."
        Task {
            _ = await OptimizerService.shared.optimizeMemory()
            await MainActor.run {
                self.ram = HardwareService.shared.getRAMInfo()
                self.isCleaning = false
                self.cleanMessage = "Memória otimizada com sucesso!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.cleanMessage = nil
                }
            }
        }
    }
    
    private func flushDNS() {
        Task {
            _ = await NetworkService.shared.flushDNSCache()
            await MainActor.run {
                self.cleanMessage = "Cache DNS renovado!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.cleanMessage = nil
                }
            }
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
