import SwiftUI
import AppKit
import ServiceManagement

public struct OptimizerView: View {
    // RAM States
    @State private var ram = HardwareService.shared.getRAMInfo()
    @State private var isOptimizingRam = false
    @State private var freedRamMessage = ""
    @State private var apps = OptimizerService.shared.getRunningApps()
    
    // Cache States
    @State private var cleanable = CacheCleanerService.shared.scanCleanableItems()
    @State private var isCleaningCache = false
    @State private var freedCacheMessage = ""
    @State private var cleanCaches = true
    @State private var cleanLogs = true
    @State private var emptyTrash = true
    
    // Launch at login
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)
    
    // Organizer Service
    @StateObject private var organizer = WorkspaceOrganizerService.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RESET OTIMIZA")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Otimização de Memória, Caches e Inicialização")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                // 1. Otimização de RAM
                CardView {
                    HStack(spacing: 30) {
                        GaugeRingView(
                            percentage: ram.usagePercent,
                            title: "Uso da RAM",
                            subtitle: String(format: "%.1fG Livre", ram.freeGB),
                            color: ram.usagePercent > 80 ? .orange : .green
                        )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("LIBERAÇÃO DE MEMÓRIA INATIVA")
                                .font(.headline)
                            Text("Esvazia os buffers inativos da memória unificada sem fechar nenhum dos seus programas abertos.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !freedRamMessage.isEmpty {
                                Text(freedRamMessage)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: optimizeMemory) {
                            HStack {
                                if isOptimizingRam {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "memorychip")
                                }
                                Text(isOptimizingRam ? "Otimizando..." : "Otimizar RAM")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(isOptimizingRam)
                    }
                }
                
                // 2. Limpeza de Caches e Arquivos Temporários
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("LIMPEZA DE CACHES E LOGS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.2f GB de Arquivos Limpáveis Detectados", cleanable.totalGB))
                                    .font(.headline)
                            }
                            Spacer()
                            
                            Button(action: cleanSystemCaches) {
                                HStack {
                                    if isCleaningCache {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Image(systemName: "trash.fill")
                                    }
                                    Text(isCleaningCache ? "Limpando..." : "Limpar Caches Selecionados")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .disabled(isCleaningCache || cleanable.totalBytes == 0)
                        }
                        
                        Divider()
                        
                        HStack(spacing: 30) {
                            Toggle("Caches de Apps (\(formatMB(cleanable.userCachesBytes)))", isOn: $cleanCaches)
                            Toggle("Logs Antigos (\(formatMB(cleanable.systemLogsBytes)))", isOn: $cleanLogs)
                            Toggle("Esvaziar Lixeira (\(formatMB(cleanable.trashBytes)))", isOn: $emptyTrash)
                        }
                        .font(.subheadline)
                        
                        if !freedCacheMessage.isEmpty {
                            Text(freedCacheMessage)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // 3. Organizador de Mesa (Desktop) & Downloads
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "folder.badge.gearshape")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("ORGANIZADOR DE MESA & DOWNLOADS")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    Text("7 Categorias")
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                                Text("Classifica automaticamente arquivos soltos em Projetos, Contratos, Mídias, Design, Documentos e Backups.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: { organizer.organizeBoth() }) {
                                HStack(spacing: 4) {
                                    if organizer.isOrganizing {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Image(systemName: "sparkles")
                                    }
                                    Text(organizer.isOrganizing ? "Organizando..." : "Organizar Tudo (1 Clique)")
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(organizer.isOrganizing)
                        }
                        
                        Divider()
                        
                        HStack(spacing: 20) {
                            HStack(spacing: 8) {
                                Image(systemName: "menubar.dock.rectangle")
                                    .foregroundColor(.cyan)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Mesa (Desktop)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("\(organizer.unorganizedDesktopCount) itens soltos")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button("Organizar Mesa") {
                                    organizer.organizeDesktop()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(organizer.isOrganizing)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Downloads")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("\(organizer.unorganizedDownloadsCount) itens soltos")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Button("Organizar Downloads") {
                                    organizer.organizeDownloads()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(organizer.isOrganizing)
                            }
                        }
                        
                        if !organizer.lastResult.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(organizer.lastResult)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                
                // 4. Inicialização com o Mac
                CardView {
                    HStack {
                        Image(systemName: "power.circle.fill")
                            .font(.title)
                            .foregroundColor(.cyan)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("INICIALIZAR JUNTO COM O MAC")
                                .font(.headline)
                            Text("Inicia o ReStats automaticamente ao ligar o computador para monitorar sistema, rede e manter seu Mac sempre leve.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $launchAtLogin)
                            .toggleStyle(.switch)
                            .onChange(of: launchAtLogin) { newValue in
                                toggleLaunchAtLogin(enabled: newValue)
                            }
                    }
                }
                
                // 4. Aplicativos em Execução
                CardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("APLICATIVOS DO USUÁRIO EM EXECUÇÃO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("\(apps.count) Aplicativos Ativos")
                                .font(.headline)
                        }
                        Spacer()
                        Button(action: refreshApps) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    Divider()
                    
                    ForEach(apps) { app in
                        HStack(spacing: 12) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(systemName: "app")
                                    .frame(width: 24, height: 24)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("PID: \(app.pid) • \(app.bundleID)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("Ativo")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
    }
    
    private func optimizeMemory() {
        isOptimizingRam = true
        freedRamMessage = ""
        
        Task {
            let freed = await OptimizerService.shared.optimizeMemory()
            await MainActor.run {
                self.ram = HardwareService.shared.getRAMInfo()
                self.isOptimizingRam = false
                if freed > 0.05 {
                    self.freedRamMessage = String(format: "✨ Sucesso! %.2f GB de memória liberados.", freed)
                } else {
                    self.freedRamMessage = "✨ Memória já estava no estado ideal e otimizada."
                }
            }
        }
    }
    
    private func cleanSystemCaches() {
        isCleaningCache = true
        freedCacheMessage = ""
        
        Task {
            let freedMB = await CacheCleanerService.shared.cleanItems(
                cleanCaches: cleanCaches,
                cleanLogs: cleanLogs,
                emptyTrash: emptyTrash
            )
            await MainActor.run {
                self.cleanable = CacheCleanerService.shared.scanCleanableItems()
                self.isCleaningCache = false
                if freedMB >= 1024.0 {
                    self.freedCacheMessage = String(format: "🎉 Limpeza concluída! %.2f GB de espaço recuperados no disco.", freedMB / 1024.0)
                } else {
                    self.freedCacheMessage = String(format: "🎉 Limpeza concluída! %.1f MB de espaço recuperados no disco.", freedMB)
                }
            }
        }
    }
    
    private func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Erro ao alterar inicialização com o sistema:", error)
        }
    }
    
    private func refreshApps() {
        apps = OptimizerService.shared.getRunningApps()
        ram = HardwareService.shared.getRAMInfo()
        cleanable = CacheCleanerService.shared.scanCleanableItems()
    }
    
    private func formatMB(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024.0 * 1024.0)
        if mb >= 1024.0 {
            return String(format: "%.1f GB", mb / 1024.0)
        }
        return String(format: "%.0f MB", mb)
    }
}
