import SwiftUI

public struct DashboardView: View {
    @State private var cpu = HardwareService.shared.getCPUInfo()
    @State private var ram = HardwareService.shared.getRAMInfo()
    @State private var gpu = HardwareService.shared.getGPUInfo()
    @State private var disk = HardwareService.shared.getDiskInfo()
    @State private var battery = HardwareService.shared.getBatteryInfo()
    @State private var macModel = HardwareService.shared.getMacModelName()
    @State private var volumes = DiskVolumeService.shared.listMountedVolumes()
    @State private var connectedDevices = ConnectedDevicesService.shared.getSummary()
    
    @State private var showStartupPrompt = !LaunchAtLoginService.shared.hasBeenPrompted
    @State private var launchAtLoginEnabled = LaunchAtLoginService.shared.isEnabled
    
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Banner de solicitação de Inicialização no Login
                if showStartupPrompt {
                    HStack(spacing: 16) {
                        Image(systemName: "bolt.badge.automatic.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.cyan)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Deseja iniciar o ResetExplode com o macOS?")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("O aplicativo permanecerá em segundo plano na barra de menus, monitorando recursos, bateria e rede em tempo real com baixo consumo.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Sim, Iniciar com o Mac") {
                            _ = LaunchAtLoginService.shared.setEnabled(true)
                            LaunchAtLoginService.shared.hasBeenPrompted = true
                            showStartupPrompt = false
                            launchAtLoginEnabled = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        
                        Button("Agora Não") {
                            LaunchAtLoginService.shared.hasBeenPrompted = true
                            showStartupPrompt = false
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(14)
                    .background(Color.cyan.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(10)
                }
                
                // Cabeçalho
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RESET SISTEMA")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                        Text(macModel)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Toggle("Iniciar no Login", isOn: $launchAtLoginEnabled)
                            .font(.caption)
                            .onChange(of: launchAtLoginEnabled) { val in
                                _ = LaunchAtLoginService.shared.setEnabled(val)
                            }
                        
                        Divider().frame(height: 16)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Status Ativo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                
                // Métricas Rápidas
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    MetricBox(
                        title: "PROCESSADOR",
                        value: cpu.name,
                        subtitle: "\(cpu.totalCores) Cores (\(cpu.pCores)P + \(cpu.eCores)E)",
                        icon: "cpu",
                        color: .cyan
                    )
                    
                    MetricBox(
                        title: "MEMÓRIA UNIFICADA",
                        value: String(format: "%.1f GB", ram.totalGB),
                        subtitle: String(format: "%.1f GB em uso (%.0f%%)", ram.usedGB, ram.usagePercent),
                        icon: "memorychip",
                        color: .green
                    )
                    
                    MetricBox(
                        title: "GRÁFICOS METAL",
                        value: gpu.name,
                        subtitle: gpu.supportsRayTracing ? "Ray Tracing por Hardware: Ativo" : "Metal 3 Suportado",
                        icon: "sparkles.tv",
                        color: .purple
                    )
                }
                
                // Card de Saúde e Diagnóstico de Bateria
                if battery.isPresent {
                    CardView {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DIAGNÓSTICO DA BATERIA & ENERGIA")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Text(battery.statusDescription)
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Image(systemName: battery.isPluggedIn ? "powerplug.fill" : "battery.50")
                                    .foregroundColor(battery.isPluggedIn ? .green : .yellow)
                                Text(battery.isPluggedIn ? (battery.isCharging ? "Carregando" : "Alimentação AC") : "Bateria")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                        }
                        
                        Divider()
                        
                        HStack(spacing: 30) {
                            GaugeRingView(
                                percentage: Double(battery.percentage),
                                title: "Carga Atual",
                                subtitle: "\(battery.percentage)%",
                                color: battery.percentage < 20 ? .red : (battery.percentage > 80 ? .green : .yellow)
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Ciclos de Carga:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(battery.cycleCount) / \(battery.designCycleCount) ciclos")
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    Text("Saúde da Bateria:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f%% (%@)", battery.healthPercentage, battery.condition))
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                
                                HStack {
                                    Text("Capacidade Máxima:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(battery.fullChargeCapacityMAh) mAh (Original: \(battery.designCapacityMAh) mAh)")
                                        .fontWeight(.medium)
                                }
                                
                                HStack {
                                    Text("Tensão do Pack:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.2f V", Double(battery.voltageMV) / 1000.0))
                                        .fontWeight(.medium)
                                }
                            }
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                // Medidores Circulares (RAM e Disco)
                CardView {
                    Text("STATUS DE RECURSOS EM TEMPO REAL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 40) {
                        GaugeRingView(
                            percentage: ram.usagePercent,
                            title: "Uso da Memória",
                            subtitle: String(format: "%.1fG Livre", ram.freeGB),
                            color: ram.usagePercent > 85 ? .red : .green
                        )
                        
                        GaugeRingView(
                            percentage: disk.usagePercent,
                            title: "SSD Principal",
                            subtitle: String(format: "%.0fG Livre", disk.freeGB),
                            color: disk.usagePercent > 90 ? .orange : .cyan
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detalhamento da Memória")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Text("Ativa:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.2f GB", ram.activeGB))
                                    .fontWeight(.medium)
                            }
                            HStack {
                                Text("Comprimida:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.2f GB", ram.compressedGB))
                                    .fontWeight(.medium)
                            }
                            HStack {
                                Text("Presa (Wired):")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.2f GB", ram.wiredGB))
                                    .fontWeight(.medium)
                            }
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                }
                
                // Card de Dispositivos Conectados
                CardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DISPOSITIVOS CONECTADOS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Telas, Periféricos USB e Bluetooth Detectados")
                                .font(.headline)
                        }
                        Spacer()
                        Button(action: refreshDevices) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.cyan)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 14) {
                        // Telas
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Telas e Monitores (\(connectedDevices.displays.count))", systemImage: "display.2")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.cyan)
                            
                            ForEach(connectedDevices.displays) { d in
                                HStack {
                                    Image(systemName: d.isBuiltIn ? "laptopcomputer" : "tv")
                                        .foregroundColor(d.isMain ? .cyan : .secondary)
                                    Text(d.name)
                                        .font(.caption)
                                        .fontWeight(d.isMain ? .bold : .regular)
                                    if d.isMain {
                                        Text("(Principal)")
                                            .font(.caption2)
                                            .foregroundColor(.cyan)
                                    }
                                    Spacer()
                                    Text("\(d.resolution) @ \(d.refreshRate)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(6)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(6)
                            }
                        }
                        
                        // USB / Áudio
                        if !connectedDevices.usbDevices.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Dispositivos USB & Áudio Conectados (\(connectedDevices.usbDevices.count))", systemImage: "cable.connector")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                
                                ForEach(connectedDevices.usbDevices) { u in
                                    HStack {
                                        Image(systemName: iconForUSB(name: u.name))
                                            .foregroundColor(.green)
                                        Text(u.name)
                                            .font(.caption)
                                        Spacer()
                                        Text(u.vendor)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(6)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        
                        // Bluetooth
                        if !connectedDevices.bluetoothDevices.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Dispositivos Bluetooth Pareados & Ativos", systemImage: "antenna.radiowaves.left.and.right")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                
                                ForEach(connectedDevices.bluetoothDevices) { b in
                                    HStack {
                                        Image(systemName: iconForBT(name: b.name))
                                            .foregroundColor(b.isConnected ? .blue : .secondary)
                                        Text(b.name)
                                            .font(.caption)
                                        Spacer()
                                        Text(b.isConnected ? "Conectado" : "Pareado")
                                            .font(.caption2)
                                            .foregroundColor(b.isConnected ? .green : .secondary)
                                    }
                                    .padding(6)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }
                }
                
                // Card de Discos Rígidos e Partições
                CardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("VOLUMES E DISCOS RÍGIDOS MONTADOS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Armazenamento Interno, Externo e de Rede")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    ForEach(volumes) { v in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: v.isInternal ? "internaldrive.fill" : (v.isRemovable ? "externaldrive.fill" : "server.rack"))
                                    .foregroundColor(v.isInternal ? .cyan : .green)
                                Text(v.name)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                Text("(\(v.path))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f GB livres de %.1f GB", v.freeGB, v.totalGB))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            ProgressView(value: v.usagePercent, total: 100.0)
                                .accentColor(v.isInternal ? .cyan : .green)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(6)
                    }
                }
            }
            .padding(24)
        }
        .onReceive(timer) { _ in
            ram = HardwareService.shared.getRAMInfo()
            disk = HardwareService.shared.getDiskInfo()
            battery = HardwareService.shared.getBatteryInfo()
            volumes = DiskVolumeService.shared.listMountedVolumes()
        }
    }
    
    private func refreshDevices() {
        connectedDevices = ConnectedDevicesService.shared.getSummary()
    }
    
    private func iconForUSB(name: String) -> String {
        let l = name.lowercased()
        if l.contains("cast") || l.contains("mic") { return "mic.fill" }
        if l.contains("hub") { return "square.connected.to.line.below.edges" }
        if l.contains("hdd") || l.contains("disk") || l.contains("expansion") { return "externaldrive.fill" }
        if l.contains("lan") || l.contains("ethernet") { return "network" }
        return "cable.connector"
    }
    
    private func iconForBT(name: String) -> String {
        let l = name.lowercased()
        if l.contains("airpod") || l.contains("beats") || l.contains("head") { return "headphones" }
        if l.contains("key") { return "keyboard.fill" }
        if l.contains("mouse") { return "magicmouse.fill" }
        if l.contains("speaker") || l.contains("jbl") { return "hifispeaker.fill" }
        if l.contains("ipad") || l.contains("iphone") { return "ipad" }
        return "antenna.radiowaves.left.and.right"
    }
}
