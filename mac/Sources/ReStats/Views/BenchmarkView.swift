import SwiftUI

public enum BenchTab: String, CaseIterable, Identifiable {
    case cpu = "Processador (CPU)"
    case memory = "Memória (RAM)"
    case disk = "Discos (Armazenamento)"
    
    public var id: String { rawValue }
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
            VStack(alignment: .leading, spacing: 20) {
                // Cabeçalho
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RESET BENCH SUITE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                        Text("Testes Profundos de Força Bruta & Desempenho")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    
                    Picker("Categoria", selection: $selectedTab) {
                        ForEach(BenchTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 440)
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
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CPU PATH TRACING BENCHMARK")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text("Cálculo de Iluminação Global por Monte Carlo")
                            .font(.headline)
                        Text("Renderizador determinístico multi-thread (Cinebench style) com cálculo de raios e esferas reflexivas.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Picker("Modo", selection: $isMultiCore) {
                            Text("Multi-Core (\(cpuInfo.totalCores) Núcleos)").tag(true)
                            Text("Single-Core (1 Núcleo)").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                        .disabled(isRunningCpu)
                        
                        Button(action: runCpuBenchmark) {
                            HStack {
                                if isRunningCpu {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text(isRunningCpu ? "Renderizando..." : "Iniciar Teste CPU")
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .disabled(isRunningCpu)
                    }
                }
                
                // Visualizador de progresso e buckets
                if isRunningCpu {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(isMultiCore ? "Renderizando buckets em paralelo (\(cpuInfo.totalCores) threads ativas)..." : "Renderizando em thread única...")
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
                        
                        // Grade de visualização dos buckets Cinebench
                        HStack(spacing: 2) {
                            ForEach(0..<40) { i in
                                Rectangle()
                                    .fill(Double(i) / 40.0 <= cpuProgress ? Color.orange : Color.white.opacity(0.1))
                                    .frame(height: 8)
                                    .cornerRadius(1)
                            }
                        }
                    }
                }
                
                if let res = cpuResult {
                    Divider()
                    HStack(spacing: 36) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(res.isMultiCore ? "PONTUAÇÃO MULTI-CORE" : "PONTUAÇÃO SINGLE-CORE")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.0f pts", res.score))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TAXA DE AMOSTRAS")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f M amostras/s", res.samplesPerSec / 1_000_000.0))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TEMPO TOTAL")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f s", res.durationSeconds))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            
            // Tabela Comparativa de Processadores
            if !cpuLeaderboard.isEmpty {
                CardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ESCALA COMPARATIVA DE PERFORMANCE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Como o seu processador se compara no mercado global")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    let maxScore = cpuLeaderboard.first?.score ?? 30000
                    
                    VStack(spacing: 8) {
                        ForEach(cpuLeaderboard) { item in
                            HStack(spacing: 12) {
                                Text(item.name)
                                    .font(.caption)
                                    .fontWeight(item.isUser ? .bold : .regular)
                                    .foregroundColor(item.isUser ? .cyan : .primary)
                                    .frame(width: 240, alignment: .leading)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.white.opacity(0.06))
                                            .frame(height: 12)
                                        
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(item.isUser ? Color.cyan : (item.arch == "ARM64" ? Color.blue.opacity(0.7) : Color.gray.opacity(0.7)))
                                            .frame(width: max(10, geo.size.width * CGFloat(item.score / maxScore)), height: 12)
                                    }
                                }
                                .frame(height: 12)
                                
                                Text(String(format: "%.0f pts", item.score))
                                    .font(.caption)
                                    .fontWeight(item.isUser ? .bold : .medium)
                                    .foregroundColor(item.isUser ? .cyan : .secondary)
                                    .frame(width: 70, alignment: .trailing)
                            }
                            .padding(.vertical, 2)
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
                        Text("Largura de Banda & Latência da Memória Unificada")
                            .font(.headline)
                        Text("Mede a velocidade real de vazão de dados entre os núcleos do Apple Silicon e a RAM unificada de \(String(format: "%.0f GB", ramInfo.totalGB)).")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button(action: runMemoryBenchmark) {
                        HStack {
                            if isRunningMemory {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "bolt.horizontal.fill")
                            }
                            Text(isRunningMemory ? "Testando..." : "Testar Memória")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(isRunningMemory)
                }
                
                if isRunningMemory {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ProgressView(value: memProgress, total: 1.0)
                            .accentColor(.green)
                    }
                }
                
                if let res = memResult {
                    Divider()
                    HStack(spacing: 40) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LARGURA DE BANDA REAL")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f GB/s", res.bandwidthGBs))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LATÊNCIA MÉDIA DE ACESSO")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f ns", res.latencyNs))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DURAÇÃO DO TESTE")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f s", res.durationSeconds))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            
            // Comparativo de Memória
            CardView {
                Text("REFERÊNCIA DE LARGURA DE BANDA DE MEMÓRIA")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 10) {
                    MemoryBarRow(name: "PC DDR4-3200 Dual-Channel", speedGBs: 45.0, maxSpeed: 200.0, color: .gray)
                    MemoryBarRow(name: "PC DDR5-6000 Dual-Channel", speedGBs: 75.0, maxSpeed: 200.0, color: .gray)
                    MemoryBarRow(name: "Apple M1 / M2 / M3 Base", speedGBs: 100.0, maxSpeed: 200.0, color: .blue)
                    if let res = memResult {
                        MemoryBarRow(name: "Seu Mac (Apple Silicon Testado)", speedGBs: res.bandwidthGBs, maxSpeed: 200.0, color: .green, isUser: true)
                    } else {
                        MemoryBarRow(name: "Seu Mac (Taxa Estimada)", speedGBs: 120.0, maxSpeed: 200.0, color: .cyan, isUser: true)
                    }
                    MemoryBarRow(name: "Apple M4 Pro", speedGBs: 150.0, maxSpeed: 200.0, color: .blue)
                }
            }
        }
    }
    
    // MARK: - Disk Benchmark Section
    private var diskBenchmarkSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardView {
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
                
                // Seletor de Discos
                HStack(spacing: 16) {
                    Image(systemName: selectedVolume.isInternal ? "internaldrive.fill" : "externaldrive.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Selecione o Disco para Testar:")
                            .font(.caption)
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
                        Text("Capacidade Livre:")
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
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricBox(
                            title: "LEITURA SEQUENCIAL",
                            value: String(format: "%.0f MB/s", res.seqReadMBs),
                            subtitle: "Blocos de 1 MB",
                            icon: "arrow.down.doc.fill",
                            color: .green
                        )
                        
                        MetricBox(
                            title: "ESCRITA SEQUENCIAL",
                            value: String(format: "%.0f MB/s", res.seqWriteMBs),
                            subtitle: "Blocos de 1 MB",
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
            let res = await MemoryBenchService.shared.runMemoryBenchmark { pct, status in
                DispatchQueue.main.async {
                    self.memProgress = pct
                    self.memStatusText = status
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
        diskProgressText = "Iniciando teste no volume..."
        let targetVolume = selectedVolume
        
        Task {
            let res = await DiskVolumeService.shared.runBenchmark(on: targetVolume, sizeMB: 128) { status, pct in
                DispatchQueue.main.async {
                    self.diskProgressText = status
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

private struct MemoryBarRow: View {
    let name: String
    let speedGBs: Double
    let maxSpeed: Double
    let color: Color
    var isUser: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.caption)
                .fontWeight(isUser ? .bold : .regular)
                .foregroundColor(isUser ? .cyan : .primary)
                .frame(width: 220, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(10, geo.size.width * CGFloat(min(1.0, speedGBs / maxSpeed))), height: 12)
                }
            }
            .frame(height: 12)
            
            Text(String(format: "%.1f GB/s", speedGBs))
                .font(.caption)
                .fontWeight(isUser ? .bold : .medium)
                .foregroundColor(isUser ? .green : .secondary)
                .frame(width: 80, alignment: .trailing)
        }
    }
}
