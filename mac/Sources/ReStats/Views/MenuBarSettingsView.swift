import SwiftUI

public struct MenuBarSettingsView: View {
    @State private var showIcon = MenuBarSettingsService.shared.showIcon
    @State private var showCpu = MenuBarSettingsService.shared.showCpu
    @State private var showRam = MenuBarSettingsService.shared.showRam
    @State private var showNet = MenuBarSettingsService.shared.showNet
    @State private var showTemp = MenuBarSettingsService.shared.showTemp
    @State private var showBattery = MenuBarSettingsService.shared.showBattery
    @State private var showDisk = MenuBarSettingsService.shared.showDisk
    
    @State private var monitoredPaths = MenuBarSettingsService.shared.monitoredDiskPaths
    @State private var volumes = DiskVolumeService.shared.listMountedVolumes()
    @State private var displays = DisplayBrightnessService.shared.getConnectedDisplays()
    @State private var launchAtLogin = LaunchAtLoginService.shared.isEnabled
    
    public init() {}
    
    private var previewText: String {
        MenuBarSettingsService.shared.formattedStatusText(
            cpu: 18.0,
            ram: 54.0,
            downloadKBps: 1450.0,
            batteryPct: 98,
            socTemp: 38.0,
            volumes: volumes
        )
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cabeçalho
                VStack(alignment: .leading, spacing: 4) {
                    Text("PERSONALIZAÇÃO DA BARRA DE MENUS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                    Text("Recursos, Ícones e Exibição Superior")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Escolha exatamente quais módulos e informações aparecem na barra superior do macOS (inspirado no Stats).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Prévia ao Vivo
                CardView {
                    Text("PRÉVIA EM TEMPO REAL NA BARRA DO MAC")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Spacer()
                        
                        HStack(spacing: 6) {
                            if showIcon {
                                Image(systemName: "bolt.shield.fill")
                                    .foregroundColor(.cyan)
                            }
                            Text(previewText.isEmpty ? " (Apenas ícone ou vazio)" : previewText)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Seleção de Módulos (Ícones & Recursos)
                CardView {
                    Text("MÓDULOS ATIVOS NA BARRA DE MENUS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    VStack(spacing: 12) {
                        // Ícone
                        Toggle(isOn: $showIcon) {
                            HStack {
                                Image(systemName: "bolt.shield.fill")
                                    .foregroundColor(.cyan)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ícone do ReStats")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Exibe o escudo com raio na barra de menus")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onChange(of: showIcon) { val in
                            MenuBarSettingsService.shared.showIcon = val
                            AppDelegate.shared?.refreshStatusBarNow()
                        }
                        
                        Divider()
                        
                        // CPU
                        Toggle(isOn: $showCpu) {
                            HStack {
                                Image(systemName: "cpu")
                                    .foregroundColor(.cyan)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Carga do Processador (CPU)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Exibe a porcentagem instantânea de uso da CPU (ex: CPU 14%)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onChange(of: showCpu) { val in
                            MenuBarSettingsService.shared.showCpu = val
                            AppDelegate.shared?.refreshStatusBarNow()
                        }
                        
                        Divider()
                        
                        // RAM
                        Toggle(isOn: $showRam) {
                            HStack {
                                Image(systemName: "memorychip")
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Uso da Memória RAM Unificada")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Exibe a porcentagem ocupada da memória (ex: RAM 52%)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onChange(of: showRam) { val in
                            MenuBarSettingsService.shared.showRam = val
                            AppDelegate.shared?.refreshStatusBarNow()
                        }
                        
                        Divider()
                        
                        // Rede
                        Toggle(isOn: $showNet) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Velocidade de Tráfego de Rede")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Exibe a vazão em tempo real de download (ex: ↓1.2M)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onChange(of: showNet) { val in
                            MenuBarSettingsService.shared.showNet = val
                            AppDelegate.shared?.refreshStatusBarNow()
                        }
                        
                        Divider()
                        
                        // Temperatura
                        Toggle(isOn: $showTemp) {
                            HStack {
                                Image(systemName: "thermometer.medium")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Temperatura do Processador / SoC")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Exibe a temperatura em graus Celsius (ex: 38°C)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onChange(of: showTemp) { val in
                            MenuBarSettingsService.shared.showTemp = val
                            AppDelegate.shared?.refreshStatusBarNow()
                        }
                        
                        Divider()
                        
                        // Bateria
                        Toggle(isOn: $showBattery) {
                            HStack {
                                Image(systemName: "battery.100.bolt")
                                    .foregroundColor(.yellow)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Nível da Bateria")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Exibe a porcentagem e ícone da bateria (ex: 🔋100%)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onChange(of: showBattery) { val in
                            MenuBarSettingsService.shared.showBattery = val
                            AppDelegate.shared?.refreshStatusBarNow()
                        }
                        
                        Divider()
                        
                        // Discos e Armazenamento
                        Toggle(isOn: $showDisk) {
                            HStack {
                                Image(systemName: "internaldrive.fill")
                                    .foregroundColor(.cyan)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Espaço Livre de Armazenamento")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Exibe a quantidade de GB livres dos discos selecionados abaixo")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onChange(of: showDisk) { val in
                            MenuBarSettingsService.shared.showDisk = val
                            AppDelegate.shared?.refreshStatusBarNow()
                        }
                    }
                }
                
                // SELEÇÃO DE DISCOS INDIVIDUAIS PARA MONITORAR
                if showDisk {
                    CardView {
                        Text("ESCOLHA QUAIS DISCOS EXIBIR NA BARRA DE MENUS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                        
                        Text("Você pode marcar 1, 2, 3 ou todos os discos conectados:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        VStack(spacing: 8) {
                            ForEach(volumes) { vol in
                                HStack {
                                    Image(systemName: vol.isInternal ? "internaldrive" : "externaldrive.fill")
                                        .foregroundColor(vol.isInternal ? .cyan : .green)
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(vol.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("\(String(format: "%.1f GB livres", vol.freeGB)) de \(String(format: "%.0f GB", vol.totalGB)) (\(vol.isInternal ? "Interno" : "Externo"))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { monitoredPaths.contains(vol.path) },
                                        set: { isChecked in
                                            MenuBarSettingsService.shared.toggleDiskMonitoring(path: vol.path)
                                            monitoredPaths = MenuBarSettingsService.shared.monitoredDiskPaths
                                            AppDelegate.shared?.refreshStatusBarNow()
                                        }
                                    ))
                                    .labelsHidden()
                                }
                                .padding(6)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                
                // CONTROLE DE BRILHO MULTI-MONITOR
                CardView {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AJUSTE DE BRILHO DOS MONITORES (\(displays.count))")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Controle Individual de Telas Integradas e Externas")
                                .font(.headline)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    VStack(spacing: 14) {
                        ForEach(displays) { disp in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(disp.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    if disp.isMain {
                                        Text("Principal")
                                            .font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.yellow.opacity(0.2))
                                            .foregroundColor(.yellow)
                                            .cornerRadius(3)
                                    }
                                    Spacer()
                                    Text("\(Int(disp.brightness * 100))%")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.yellow)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "sun.min")
                                        .foregroundColor(.secondary)
                                    
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
                                    
                                    Image(systemName: "sun.max.fill")
                                        .foregroundColor(.yellow)
                                    
                                    HStack(spacing: 4) {
                                        Button("25%") { setDisplayBrightness(disp.id, 0.25) }.buttonStyle(.bordered).controlSize(.mini)
                                        Button("50%") { setDisplayBrightness(disp.id, 0.50) }.buttonStyle(.bordered).controlSize(.mini)
                                        Button("75%") { setDisplayBrightness(disp.id, 0.75) }.buttonStyle(.bordered).controlSize(.mini)
                                        Button("100%") { setDisplayBrightness(disp.id, 1.00) }.buttonStyle(.bordered).controlSize(.mini)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(6)
                        }
                    }
                }
                
                // Comportamento do Sistema
                CardView {
                    Text("SISTEMA & INICIALIZAÇÃO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Toggle(isOn: $launchAtLogin) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Iniciar o ReStats automaticamente com o macOS")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Mantém o monitor de telemetria ativo na barra de menus ao ligar o computador.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: launchAtLogin) { val in
                        _ = LaunchAtLoginService.shared.setEnabled(val)
                    }
                }
            }
            .padding(24)
        }
    }
    
    private func setDisplayBrightness(_ id: CGDirectDisplayID, _ val: Float) {
        if let idx = displays.firstIndex(where: { $0.id == id }) {
            displays[idx].brightness = val
            _ = DisplayBrightnessService.shared.setBrightness(val, displayID: id)
        }
    }
}
