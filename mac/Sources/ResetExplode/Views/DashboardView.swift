import SwiftUI

public struct DashboardView: View {
    @State private var cpu = HardwareService.shared.getCPUInfo()
    @State private var ram = HardwareService.shared.getRAMInfo()
    @State private var gpu = HardwareService.shared.getGPUInfo()
    @State private var disk = HardwareService.shared.getDiskInfo()
    @State private var battery = HardwareService.shared.getBatteryInfo()
    @State private var macModel = HardwareService.shared.getMacModelName()
    
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(20)
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
                            title: "Espaço em Disco",
                            subtitle: String(format: "%.0fG Livre", disk.freeGB),
                            color: disk.usagePercent > 90 ? .orange : .cyan
                        )
                        
                        if battery.isPresent {
                            GaugeRingView(
                                percentage: Double(battery.percentage),
                                title: "Bateria",
                                subtitle: battery.isCharging ? "Carregando" : "Bateria",
                                color: battery.percentage < 20 ? .red : .yellow
                            )
                        }
                        
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
                
                // Informações de Armazenamento
                CardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SSD PRINCIPAL (APFS)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f GB Usados de %.1f GB", disk.usedGB, disk.totalGB))
                                .font(.headline)
                        }
                        Spacer()
                        Text(String(format: "%.1f GB Livres", disk.freeGB))
                            .font(.subheadline)
                            .foregroundColor(.cyan)
                    }
                    
                    ProgressView(value: disk.usagePercent, total: 100.0)
                        .accentColor(.cyan)
                }
            }
            .padding(24)
        }
        .onReceive(timer) { _ in
            ram = HardwareService.shared.getRAMInfo()
            disk = HardwareService.shared.getDiskInfo()
            battery = HardwareService.shared.getBatteryInfo()
        }
    }
}
