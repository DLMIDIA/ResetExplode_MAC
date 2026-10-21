import SwiftUI

public struct BenchmarkView: View {
    // CPU Bench States
    @State private var isRunningCpu = false
    @State private var isMultiCore = true
    @State private var cpuProgress = 0.0
    @State private var cpuResult: CPUBenchResult?
    
    // Disk Bench States
    @State private var volumes = DiskVolumeService.shared.listMountedVolumes()
    @State private var selectedVolumePath: String = "/"
    @State private var isRunningDisk = false
    @State private var diskProgress = 0.0
    @State private var diskProgressText = ""
    @State private var diskResult: DiskBenchResult?
    
    let cpuInfo = HardwareService.shared.getCPUInfo()
    
    public init() {}
    
    private var selectedVolume: DiskVolume {
        volumes.first(where: { $0.path == selectedVolumePath }) ?? volumes.first ?? DiskVolume(name: "Macintosh HD", path: "/", isInternal: true, isRemovable: false, totalGB: 0, freeGB: 0, usedGB: 0)
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RESET BENCH")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                    Text("Testes de Desempenho e Força Bruta")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                // Card do CPU Benchmark
                CardView {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CPU BENCHMARK (PATH TRACING)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Cálculo de Iluminação Global e Amostras por Segundo")
                                .font(.headline)
                            Text("Renderização determinística baseada na arquitetura do Cinebench e do ResetExplode original.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Picker("Modo", selection: $isMultiCore) {
                                Text("Multi-Core (\(cpuInfo.totalCores) Cores)").tag(true)
                                Text("Single-Core (1 Core)").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 220)
                            .disabled(isRunningCpu)
                            
                            Button(action: runCpuBenchmark) {
                                HStack {
                                    if isRunningCpu {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Image(systemName: "play.fill")
                                    }
                                    Text(isRunningCpu ? "Testando..." : "Iniciar CPU Bench")
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                            .disabled(isRunningCpu)
                        }
                    }
                    
                    if isRunningCpu {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isMultiCore ? "Renderizando buckets em paralelo nos \(cpuInfo.totalCores) núcleos..." : "Renderizando buckets em thread única...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ProgressView(value: cpuProgress, total: 1.0)
                                .accentColor(.cyan)
                        }
                    }
                    
                    if let res = cpuResult {
                        Divider()
                        HStack(spacing: 36) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(res.isMultiCore ? "NOTA MULTI-CORE" : "NOTA SINGLE-CORE")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.0f pts", res.score))
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.cyan)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("TAXA DE AMOSTRAS")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f M/s", res.samplesPerSec / 1_000_000.0))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("TEMPO DE EXECUÇÃO")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f s", res.durationSeconds))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                
                // Card de Benchmark de Armazenamento (Multi-Discos)
                CardView {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BENCHMARK DE ARMAZENAMENTO (DISCOS)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Velocidade de Leitura e Escrita Direta")
                                .font(.headline)
                            Text("Mede a velocidade física real do drive ignorando o cache de memória do macOS (F_NOCACHE).")
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
                                Text(isRunningDisk ? "Testando..." : "Testar Disco Selecionado")
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
                        HStack(spacing: 40) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DISCO TESTADO")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(res.volumeName)
                                    .font(.headline)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("LEITURA REAL")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.0f MB/s", res.seqReadMBs))
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ESCRITA REAL")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.0f MB/s", res.seqWriteMBs))
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(.cyan)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("TEMPO")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f s", res.durationSeconds))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            volumes = DiskVolumeService.shared.listMountedVolumes()
        }
    }
    
    private func runCpuBenchmark() {
        isRunningCpu = true
        cpuProgress = 0.0
        
        Task {
            let res = await CpuBenchService.shared.runBenchmark(isMultiCore: isMultiCore) { pct in
                DispatchQueue.main.async {
                    self.cpuProgress = pct
                }
            }
            await MainActor.run {
                self.cpuResult = res
                self.isRunningCpu = false
            }
        }
    }
    
    private func runDiskBenchmark() {
        isRunningDisk = true
        diskProgress = 0.0
        diskProgressText = "Iniciando teste no volume..."
        let targetVolume = selectedVolume
        
        Task {
            let res = await DiskVolumeService.shared.runBenchmark(on: targetVolume, sizeMB: 256) { status, pct in
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
