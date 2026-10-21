import SwiftUI

public struct NetworkView: View {
    @State private var stats = NetworkService.shared.getCurrentStats()
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RESET REDE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Monitoramento e Tráfego de Rede em Tempo Real")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                // Tráfego Atual
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    CardView {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("VELOCIDADE DE DOWNLOAD")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatSpeed(kbps: stats.downloadSpeedKBps))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                                Text("Tráfego de entrada em tempo real")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green.opacity(0.8))
                        }
                    }
                    
                    CardView {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("VELOCIDADE DE UPLOAD")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatSpeed(kbps: stats.uploadSpeedKBps))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                Text("Tráfego de saída em tempo real")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue.opacity(0.8))
                        }
                    }
                }
                
                // Conexões e Interface
                CardView {
                    Text("CONFIGURAÇÃO DE REDE ATIVA")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 40) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Endereço IP Local (LAN)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(stats.localIP)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Interface Principal")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(stats.activeInterface)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status da Conexão")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            HStack(spacing: 6) {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text("Conectado à Internet")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(24)
        }
        .onReceive(timer) { _ in
            stats = NetworkService.shared.getCurrentStats()
        }
    }
    
    private func formatSpeed(kbps: Double) -> String {
        if kbps >= 1024.0 {
            return String(format: "%.2f MB/s", kbps / 1024.0)
        } else {
            return String(format: "%.1f KB/s", kbps)
        }
    }
}
