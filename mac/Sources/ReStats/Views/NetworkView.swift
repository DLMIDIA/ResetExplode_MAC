import SwiftUI

public struct NetworkView: View {
    @State private var stats = NetworkService.shared.getCurrentStats()
    @State private var pingCloudflare: Double? = nil
    @State private var pingGoogle: Double? = nil
    @State private var isPinging = false
    @State private var isFlushingDNS = false
    @State private var dnsStatusMessage: String? = nil
    
    // Internet Speedtest States
    @State private var isRunningSpeedTest = false
    @State private var speedTestProgress = 0.0
    @State private var currentDownloadMbps = 0.0
    @State private var speedTestResult: SpeedTestResult? = nil
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cabeçalho
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RESET REDE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Monitoramento e Diagnóstico de Rede")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    
                    Button(action: runNetworkPingTest) {
                        HStack {
                            if isPinging {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "waveform.path.ecg")
                            }
                            Text(isPinging ? "Testando Latência..." : "Testar Latência (Ping)")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(isPinging)
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
                
                // Teste de Velocidade de Internet (Speedtest)
                CardView {
                    HStack {
                        Image(systemName: "gauge.with.needle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TESTE DE VELOCIDADE DE INTERNET (SPEEDTEST)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Vazão Real de Download, Latência e Estabilidade CDN")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Button(action: runInternetSpeedTest) {
                            HStack {
                                if isRunningSpeedTest {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                }
                                Text(isRunningSpeedTest ? "Testando..." : "Iniciar Speedtest")
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(isRunningSpeedTest)
                    }
                    
                    if isRunningSpeedTest {
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(String(format: "%.1f Mbps", currentDownloadMbps))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                                Spacer()
                                Text("\(Int(speedTestProgress * 100))%")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            ProgressView(value: speedTestProgress, total: 1.0)
                                .accentColor(.green)
                        }
                    }
                    
                    if let res = speedTestResult {
                        Divider()
                        HStack(spacing: 40) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("VELOCIDADE REAL")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f Mbps", res.downloadMbps))
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                                Text(String(format: "%.2f MB/s de vazão", res.downloadMBs))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("LATÊNCIA (PING)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.0f ms", res.pingMs))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(res.pingMs < 40 ? .green : .yellow)
                                Text("Cloudflare Edge")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DURAÇÃO DO TESTE")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f s", res.durationSeconds))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                
                // Latência e Conectividade
                CardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TESTE DE LATÊNCIA (PING)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Tempo de Resposta dos Servidores de Internet")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack(spacing: 40) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cloudflare DNS (1.1.1.1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let p = pingCloudflare {
                                HStack(spacing: 6) {
                                    Text(p > 0 ? String(format: "%.1f ms", p) : "Inacessível")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(p < 50 ? .green : (p < 120 ? .yellow : .red))
                                    Text(p < 50 ? "(Excelente)" : (p < 120 ? "(Bom)" : "(Alto)"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("-- ms")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Google DNS (8.8.8.8)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let p = pingGoogle {
                                HStack(spacing: 6) {
                                    Text(p > 0 ? String(format: "%.1f ms", p) : "Inacessível")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(p < 50 ? .green : (p < 120 ? .yellow : .red))
                                    Text(p < 50 ? "(Excelente)" : (p < 120 ? "(Bom)" : "(Alto)"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("-- ms")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Conexões e Interface
                CardView {
                    Text("CONFIGURAÇÃO DE REDE ATIVA")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Endereço IP Local (IPv4)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(stats.localIP)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gateway Padrão (Roteador)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(stats.gatewayIP)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Interface Ativa")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(stats.activeInterface)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Endereço MAC Físico")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(stats.macAddress)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Servidores DNS")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(stats.dnsServers.joined(separator: ", "))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status da Conexão")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            HStack(spacing: 6) {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text("Online & Ativo")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Ferramentas de Otimização de Rede
                CardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FERRAMENTAS DE CONEXÃO & OTIMIZAÇÃO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Acelere a resolução de nomes e limpe rotas travadas")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack(spacing: 16) {
                        Button(action: flushDNS) {
                            HStack {
                                if isFlushingDNS {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "trash.circle")
                                }
                                Text("Limpar Cache DNS (Flush)")
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isFlushingDNS)
                        
                        if let msg = dnsStatusMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .onReceive(timer) { _ in
            stats = NetworkService.shared.getCurrentStats()
        }
        .onAppear {
            runNetworkPingTest()
        }
    }
    
    private func runNetworkPingTest() {
        isPinging = true
        Task {
            let cf = await NetworkService.shared.measurePing(host: "1.1.1.1")
            let gg = await NetworkService.shared.measurePing(host: "8.8.8.8")
            await MainActor.run {
                self.pingCloudflare = cf
                self.pingGoogle = gg
                self.isPinging = false
            }
        }
    }
    
    private func runInternetSpeedTest() {
        isRunningSpeedTest = true
        speedTestProgress = 0.0
        currentDownloadMbps = 0.0
        
        Task {
            let res = await InternetSpeedTestService.shared.runSpeedTest { mbps, progress in
                DispatchQueue.main.async {
                    self.currentDownloadMbps = mbps
                    self.speedTestProgress = progress
                }
            }
            await MainActor.run {
                self.speedTestResult = res
                self.isRunningSpeedTest = false
            }
        }
    }
    
    private func flushDNS() {
        isFlushingDNS = true
        Task {
            _ = await NetworkService.shared.flushDNSCache()
            await MainActor.run {
                self.isFlushingDNS = false
                self.dnsStatusMessage = "Cache DNS limpo com sucesso!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.dnsStatusMessage = nil
                }
            }
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
