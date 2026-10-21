import SwiftUI

public struct MenuBarSettingsView: View {
    @State private var showIcon = MenuBarSettingsService.shared.showIcon
    @State private var showCpu = MenuBarSettingsService.shared.showCpu
    @State private var showRam = MenuBarSettingsService.shared.showRam
    @State private var showNet = MenuBarSettingsService.shared.showNet
    @State private var showBattery = MenuBarSettingsService.shared.showBattery
    
    @State private var brightness: Float = DisplayBrightnessService.shared.getBrightness()
    @State private var launchAtLogin = LaunchAtLoginService.shared.isEnabled
    
    public init() {}
    
    private var previewText: String {
        MenuBarSettingsService.shared.formattedStatusText(
            cpu: 18.0,
            ram: 54.0,
            downloadKBps: 1450.0,
            batteryPct: 100
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
                        
                        Toggle(isOn: $showBattery) {
                            HStack {
                                Image(systemName: "battery.100.bolt")
                                    .foregroundColor(.yellow)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Nível da Bateria")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Exibe a porcentagem da bateria (ex: 🔋100%)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onChange(of: showBattery) { val in
                            MenuBarSettingsService.shared.showBattery = val
                            AppDelegate.shared?.refreshStatusBarNow()
                        }
                    }
                }
                
                // Controle de Brilho dos Monitores
                CardView {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AJUSTE DE BRILHO DOS MONITORES")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Controle Físico da Luz de Fundo da Tela")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(brightness * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    
                    Divider()
                    
                    HStack(spacing: 16) {
                        Image(systemName: "sun.min")
                            .foregroundColor(.secondary)
                        
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
                        
                        HStack(spacing: 6) {
                            Button("25%") { setBrightness(0.25) }.buttonStyle(.bordered).controlSize(.small)
                            Button("50%") { setBrightness(0.50) }.buttonStyle(.bordered).controlSize(.small)
                            Button("75%") { setBrightness(0.75) }.buttonStyle(.bordered).controlSize(.small)
                            Button("100%") { setBrightness(1.00) }.buttonStyle(.bordered).controlSize(.small)
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
    
    private func setBrightness(_ val: Float) {
        self.brightness = val
        _ = DisplayBrightnessService.shared.setBrightness(val)
    }
}
