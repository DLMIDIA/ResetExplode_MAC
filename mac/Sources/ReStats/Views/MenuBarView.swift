import SwiftUI
import AppKit

public struct MenuBarView: View {
    @State private var cpu = HardwareService.shared.getCPUInfo()
    @State private var ram = HardwareService.shared.getRAMInfo()
    @State private var net = NetworkService.shared.getCurrentStats()
    @State private var battery = HardwareService.shared.getBatteryInfo()
    @State private var topProcesses = HardwareService.shared.getTopProcesses(limit: 3)
    @State private var thermal = ThermalService.shared.getThermalInfo()
    @State private var volumes = DiskVolumeService.shared.listMountedVolumes()
    @State private var displays: [MonitorDisplayItem] = DisplayBrightnessService.shared.getConnectedDisplays()
    @State private var isDisksExpanded = true
    
    @State private var isCleaning = false
    @State private var cleanMessage: String?
    @State private var launchAtLogin = LaunchAtLoginService.shared.isEnabled
    
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                headerSection
                Divider()
                cpuRamSection
                networkSection
                displaysSection
                disksSection
                batterySection
                
                if let msg = cleanMessage {
                    Text(msg)
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
                
                Divider()
                actionsSection
                Divider()
                footerSection
            }
            .padding(12)
        }
        .frame(width: 320, height: 600)
        .onReceive(timer) { _ in
            cpu = HardwareService.shared.getCPUInfo()
            ram = HardwareService.shared.getRAMInfo()
            net = NetworkService.shared.getCurrentStats()
            battery = HardwareService.shared.getBatteryInfo()
            topProcesses = HardwareService.shared.getTopProcesses(limit: 3)
            thermal = ThermalService.shared.getThermalInfo()
            volumes = DiskVolumeService.shared.listMountedVolumes()
            displays = DisplayBrightnessService.shared.getConnectedDisplays()
        }
    }
    
    // MARK: - Subviews
    private var headerSection: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 22, height: 22)
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text("ReStats")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Apple Silicon")
                        .font(.system(size: 8, weight: .heavy))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.cyan.opacity(0.2))
                        .foregroundColor(.cyan)
                        .cornerRadius(3)
                }
            }
            Spacer()
            Circle().fill(Color.green).frame(width: 7, height: 7)
        }
    }
    
    private var cpuRamSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // CPU & Temp
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Image(systemName: "cpu").foregroundColor(.cyan)
                    Text("Processador:").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    
                    HStack(spacing: 3) {
                        Image(systemName: "thermometer.medium").font(.system(size: 10)).foregroundColor(.orange)
                        Text(String(format: "%.0f°C", thermal.socTemperatureC))
                            .font(.caption).fontWeight(.semibold).foregroundColor(.orange)
                    }
                    .padding(.trailing, 4)
                    
                    Text(String(format: "%.1f%%", cpu.overallUsage))
                        .font(.caption).fontWeight(.bold).foregroundColor(.cyan)
                }
                ProgressView(value: cpu.overallUsage, total: 100.0).accentColor(.cyan)
            }
            
            // RAM
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Image(systemName: "memorychip").foregroundColor(.green)
                    Text("Memória:").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(String(format: "%.1fG/%.0fG (%.0f%%)", ram.usedGB, ram.totalGB, ram.usagePercent))
                            .font(.caption).fontWeight(.bold)
                        Text(ram.pressure.rawValue)
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(pressureColor.opacity(0.2))
                            .foregroundColor(pressureColor)
                            .cornerRadius(3)
                    }
                }
                ProgressView(value: ram.usagePercent, total: 100.0).accentColor(pressureColor)
            }
        }
    }
    
    private var networkSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle.fill").foregroundColor(.green)
                Text(formatSpeed(kbps: net.downloadSpeedKBps)).font(.caption).fontWeight(.semibold)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill").foregroundColor(.blue)
                Text(formatSpeed(kbps: net.uploadSpeedKBps)).font(.caption).fontWeight(.semibold)
            }
        }
        .padding(6)
        .background(Color.white.opacity(0.04))
        .cornerRadius(6)
    }
    
    private var displaysSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sun.max.fill").foregroundColor(.yellow).font(.system(size: 11))
                Text("Brilho dos Monitores (\(displays.count))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            ForEach(displays) { disp in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(disp.name).font(.system(size: 10, weight: .medium)).lineLimit(1)
                        Spacer()
                        Text("\(Int(disp.brightness * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(disp.brightness) },
                        set: { val in
                            if let idx = displays.firstIndex(where: { $0.id == disp.id }) {
                                displays[idx].brightness = Float(val)
                                _ = DisplayBrightnessService.shared.setBrightness(Float(val), displayID: disp.id)
                            }
                        }
                    ), in: 0.05...1.0)
                    .accentColor(.yellow)
                }
                .padding(6)
                .background(Color.white.opacity(0.03))
                .cornerRadius(5)
            }
        }
    }
    
    private var disksSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isDisksExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "internaldrive.fill").foregroundColor(.cyan).font(.system(size: 11))
                    Text("Discos & Armazenamento (\(volumes.count))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: isDisksExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isDisksExpanded {
                VStack(spacing: 5) {
                    ForEach(volumes) { vol in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: vol.isInternal ? "internaldrive" : "externaldrive.fill")
                                    .foregroundColor(vol.isInternal ? .cyan : .green)
                                    .font(.system(size: 10))
                                Text(vol.name).font(.system(size: 10, weight: .bold)).lineLimit(1)
                                Spacer()
                                Text(String(format: "%.1f GB livres", vol.freeGB))
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            let usedPct = vol.totalGB > 0 ? (vol.usedGB / vol.totalGB) : 0
                            ProgressView(value: usedPct, total: 1.0)
                                .accentColor(usedPct > 0.9 ? .red : (usedPct > 0.8 ? .orange : .cyan))
                        }
                        .padding(5)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(5)
                    }
                }
            }
        }
    }
    
    private var batterySection: some View {
        Group {
            if battery.isPresent {
                HStack(spacing: 6) {
                    Image(systemName: battery.isPluggedIn ? "battery.100.bolt" : "battery.75")
                        .foregroundColor(battery.percentage < 20 ? .red : .yellow)
                    Text("Bateria \(battery.percentage)%").font(.caption).fontWeight(.semibold)
                    Spacer()
                    Text("\(battery.cycleCount) ciclos (Saúde: \(Int(battery.healthPercentage))%)")
                        .font(.system(size: 9)).foregroundColor(.secondary)
                }
                .padding(5)
                .background(Color.white.opacity(0.03))
                .cornerRadius(5)
            }
        }
    }
    
    private var actionsSection: some View {
        HStack(spacing: 8) {
            Button {
                cleanRAM()
            } label: {
                HStack(spacing: 4) {
                    if isCleaning { ProgressView().controlSize(.small) } else { Image(systemName: "sparkles") }
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
    }
    
    private var footerSection: some View {
        HStack {
            Button("Abrir ReStats") {
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
