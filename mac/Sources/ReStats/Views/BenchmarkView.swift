import SwiftUI

public enum BenchTab: String, CaseIterable, Identifiable {
    case cpu = "Processador (CPU)"
    case memory = "Memória (RAM)"
    case disk = "Discos & Armazenamento"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        }
    }
}

public struct BenchmarkView: View {
    @State private var selectedTab: BenchTab = .cpu
    
    // CPU Bench States
    @State private var isRunningCpu = false
    @State private var isMultiCore = true
    @State private var cpuProgress = 0.0
    @State private var currentBucket = 0
    @State private var totalBuckets = 540
    @State private var cpuResult: CPUBenchResult?
    @State private var cpuLeaderboard: [BenchmarkScoreItem] = []
    
    // Memory Bench States
    @State private var isRunningMemory = false
    @State private var memProgress = 0.0
    @State private var memStatusText = ""
    @State private var memResult: MemoryBenchResult?
    
    // Disk Bench States
    @State private var volumes = DiskVolumeService.shared.listMountedVolumes()
    @State private var selectedVolumePath: String = "/"
    @State private var isRunningDisk = false
    @State private var diskProgress = 0.0
    @State private var diskProgressText = ""
    @State private var diskResult: DiskBenchResult?
    
    let cpuInfo = HardwareService.shared.getCPUInfo()
    let ramInfo = HardwareService.shared.getRAMInfo()
    
    public init() {}
    
    private var selectedVolume: DiskVolume {
        volumes.first(where: { $0.path == selectedVolumePath }) ?? volumes.first ?? DiskVolume(name: "Macintosh HD", path: "/", isInternal: true, isRemovable: false, totalGB: 0, freeGB: 0, usedGB: 0)
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Cabeçalho e Abas Não-Sobrepostas
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("RESTATS BENCH SUITE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                        Text("Testes Profundos de Força Bruta & Desempenho")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    // Barra de Abas Customizada e Responsiva
                    HStack(spacing: 8) {
                        ForEach(BenchTab.allCases) { tab in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedTab = tab
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                    Text(tab.rawValue)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedTab == tab ? Color.cyan.opacity(0.2) : Color.white.opacity(0.05))
                                .foregroundColor(selectedTab == tab ? .cyan : .secondary)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }
                
                switch selectedTab {
                case .cpu:
                    cpuBenchmarkSection
                case .memory:
                    memoryBenchmarkSection
                case .disk:
                    diskBenchmarkSection
                }
            }
            .padding(24)
        }
        .onAppear {
            volumes = DiskVolumeService.shared.listMountedVolumes()
        }
    }
    
    // MARK: - CPU Benchmark Section
    private var cpuBenchmarkSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CPU PATH TRACING BENCHMARK")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text("Cálculo de Iluminação Global por Monte Carlo")
                            .font(.headline)
                        Text("Renderizador determinístico multithread com sombreamento Phong, reflexões e gravação física em buffer.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Picker("Modo de Teste", selection: $isMultiCore) {
                            Text("Multi-Core (\(cpuInfo.totalCores) Núcleos)").tag(true)
                            Text("Single-Core (1 Núcleo)").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 340)
                        .disabled(isRunningCpu)
                        
                        Spacer()
                        
                        Button(action: runCpuBenchmark) {
                            HStack {
                                if isRunningCpu {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text(isRunningCpu ? "Renderizando..." : "Iniciar Teste CPU")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .disabled(isRunningCpu)
                    }
                }
                
                // Visualizador de progresso e buckets
                if isRunningCpu {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(isMultiCore ? "Renderizando buckets em paralelo (\(cpuInfo.totalCores) threads ativas)..." : "Renderizando em thread única dedicada...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Bucket \(currentBucket) de \(totalBuckets) (\(Int(cpuProgress * 100))%)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.cyan)
                        }
                        
                        ProgressView(value: cpuProgress, total: 1.0)
                            .accentColor(.cyan)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<40) { i in
                                Rectangle()
                                    .fill(Double(i) / 40.0 <= cpuProgress ? Color.cyan : Color.white.opacity(0.1))
                                    .frame(height: 6)
                                    .cornerRadius(1)
                            }
                        }
                    }
                }
                
                // Resultado CPU
                if let res = cpuResult {
                    Divider()
                    HStack(spacing: 40) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PONTUAÇÃO OBTIDA")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(res.score) pts")
                                .font(.system(size: 38, weight: .heavy, design: .rounded))
                                .foregroundColor(.cyan)
                            Text("\(res.isMultiCore ? "Multi-Core" : "Single-Core") • \(String(format: "%.2f s", res.durationSeconds)) de teste")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DENSIDADE DE CÁLCULO")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f Mraios/s", res.samplesPerSec / 1_000_000.0))
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Taxa determinística de traçado de raios")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Tabela Comparativa de Mercado
            if !cpuLeaderboard.isEmpty {
                CardView {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundColor(.cyan)
                        Text("COMPARATIVO DE MERCADO • \(isMultiCore ? "MULTI-CORE" : "SINGLE-CORE")")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(cpuLeaderboard) { item in
                            HStack {
                                Text(item.name)
                                    .font(.subheadline)
                                    .fontWeight(item.isUser ? .bold : .regular)
                                    .foregroundColor(item.isUser ? .cyan : .primary)
                                    .frame(width: 220, alignment: .leading)
                                
                                GeometryReader { geo in
                                    let maxScore = Double(cpuLeaderboard.first?.score ?? 1)
                                    let width = geo.size.width * CGFloat(Double(item.score) / max(1.0, maxScore))
                                    
                                    HStack {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(item.isUser ? Color.cyan : Color.white.opacity(0.18))
                                            .frame(width: max(10, width), height: 14)
                                        Spacer()
                                    }
                                }
                                .frame(height: 14)
                                
                                Text("\(Int(item.score)) pts")
                                    .font(.subheadline)
                                    .fontWeight(item.isUser ? .bold : .medium)
                                    .foregroundColor(item.isUser ? .cyan : .secondary)
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Memory Benchmark Section
    private var memoryBenchmarkSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardView {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STREAM MEMORY BENCHMARK")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text("Largura de Banda e Latência da Memória Unificada")
                            .font(.headline)
                        Text("Mede a vazão sustentada da arquitetura Apple Silicon em GB/s e latência em nanossegundos.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button(action: runMemoryBenchmark) {
                        HStack {
                            if isRunningMemory {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "memorychip")
                            }
                            Text(isRunningMemory ? "Medindo..." : "Testar Memória")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(isRunningMemory)
                }
                
                if isRunningMemory {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ProgressView(value: memProgress, total: 1.0)
                            .accentColor(.purple)
                    }
                }
                
                if let res = memResult {
                    Divider()
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricBox(
                            title: "LARGURA DE BANDA SUSTENTADA",
                            value: String(format: "%.1f GB/s", res.bandwidthGBs),
                            subtitle: "Transferência contínua na memória unificada",
                            icon: "speedometer",
                            color: .purple
                        )
                        
                        MetricBox(
                            title: "LATÊNCIA DE ACESSO",
                            value: String(format: "%.1f ns", res.latencyNs),
                            subtitle: "Tempo de acesso direto (Pointer Chasing)",
                            icon: "clock.arrow.2.circlepath",
                            color: .cyan
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Disk Benchmark Section (Alinhado & Refinado)
    private var diskBenchmarkSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BENCHMARK DE ARMAZENAMENTO COMPLETO (CRYSTAL DISK STYLE)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Velocidade Sequencial & IOPS Aleatórios 4K")
                                .font(.headline)
                            Text("Mede a taxa de transferência física contornando o cache de memória do macOS (F_NOCACHE).")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        Button(action: runDiskBenchmark) {
                            HStack {
                                if isRunningDisk {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "bolt.fill")
                                }
                                Text(isRunningDisk ? "Testando..." : "Testar Volume Selecionado")
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(isRunningDisk)
                    }
                    
                    Divider()
                    
                    // Seletor de Discos Espaçoso e Alinhado
                    HStack(spacing: 16) {
                        Image(systemName: selectedVolume.isInternal ? "internaldrive.fill" : "externaldrive.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Disco Selecionado para Teste:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Picker("", selection: $selectedVolumePath) {
                                ForEach(volumes) { vol in
                                    Text("\(vol.name) (\(String(format: "%.0f GB", vol.totalGB))) [\(vol.isInternal ? "Interno" : "Externo")]")
                                        .tag(vol.path)
                                }
                            }
                            .pickerStyle(.menu)
                            .disabled(isRunningDisk)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Espaço Livre:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f GB livres", selectedVolume.freeGB))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                    
                    if isRunningDisk {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(diskProgressText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ProgressView(value: diskProgress, total: 1.0)
                                .accentColor(.green)
                        }
                    }
                    
                    if let res = diskResult {
                        Divider()
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            MetricBox(
                                title: "LEITURA SEQUENCIAL",
                                value: String(format: "%.0f MB/s", res.seqReadMBs),
                                subtitle: "Blocos de 1 MB físicos",
                                icon: "arrow.down.doc.fill",
                                color: .green
                            )
                            
                            MetricBox(
                                title: "ESCRITA SEQUENCIAL",
                                value: String(format: "%.0f MB/s", res.seqWriteMBs),
                                subtitle: "Blocos de 1 MB físicos",
                                icon: "arrow.up.doc.fill",
                                color: .cyan
                            )
                            
                            MetricBox(
                                title: "LEITURA ALEATÓRIA 4K",
                                value: String(format: "%.0f IOPS", res.random4kReadIOPS),
                                subtitle: "Acesso aleatório 4 KB",
                                icon: "square.grid.3x3.fill",
                                color: .yellow
                            )
                            
                            MetricBox(
                                title: "ESCRITA ALEATÓRIA 4K",
                                value: String(format: "%.0f IOPS", res.random4kWriteIOPS),
                                subtitle: "Acesso aleatório 4 KB",
                                icon: "square.grid.3x3.topleft.filled",
                                color: .orange
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func runCpuBenchmark() {
        isRunningCpu = true
        cpuProgress = 0.0
        
        Task {
            let res = await CpuBenchService.shared.runBenchmark(isMultiCore: isMultiCore) { pct, curr, total in
                DispatchQueue.main.async {
                    self.cpuProgress = pct
                    self.currentBucket = curr
                    self.totalBuckets = total
                }
            }
            let board = CpuBenchService.shared.getComparativeLeaderboard(userScore: res.score, isMultiCore: isMultiCore)
            await MainActor.run {
                self.cpuResult = res
                self.cpuLeaderboard = board
                self.isRunningCpu = false
            }
        }
    }
    
    private func runMemoryBenchmark() {
        isRunningMemory = true
        memProgress = 0.0
        memStatusText = "Iniciando teste de largura de banda..."
        
        Task {
            let res = await MemoryBenchService.shared.runMemoryBenchmark { progress, text in
                DispatchQueue.main.async {
                    self.memProgress = progress
                    self.memStatusText = text
                }
            }
            await MainActor.run {
                self.memResult = res
                self.isRunningMemory = false
            }
        }
    }
    
    private func runDiskBenchmark() {
        isRunningDisk = true
        diskProgress = 0.0
        diskProgressText = "Preparando teste no volume \(selectedVolume.name)..."
        
        Task {
            let res = await DiskVolumeService.shared.runBenchmark(on: selectedVolume) { phase, pct in
                DispatchQueue.main.async {
                    self.diskProgressText = phase
                    self.diskProgress = pct
                }
            }
            await MainActor.run {
                self.diskResult = res
                self.isRunningDisk = false
            }
        }
    }
}
