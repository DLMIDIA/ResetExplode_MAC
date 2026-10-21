import Foundation
import AppKit

public struct OrganizeResult: Sendable {
    public let desktopMovedCount: Int
    public let downloadsMovedCount: Int
    public let totalMovedCount: Int
    public let message: String
}

@MainActor
public final class WorkspaceOrganizerService: ObservableObject {
    public static let shared = WorkspaceOrganizerService()
    
    @Published public var isOrganizing: Bool = false
    @Published public var lastResult: String = ""
    @Published public var lastOrganizedCount: Int = 0
    @Published public var lastRunDate: Date? = nil
    
    @Published public var unorganizedDesktopCount: Int = 0
    @Published public var unorganizedDownloadsCount: Int = 0
    
    private let fileManager = FileManager.default
    
    private let desktopPath = ("~/Desktop" as NSString).expandingTildeInPath
    private let downloadsPath = ("~/Downloads" as NSString).expandingTildeInPath
    
    private let mainFolders = [
        "01 - Projetos & Sistemas",
        "02 - Orçamentos & Contratos",
        "03 - Fotos, Vídeos & Drone",
        "04 - Design & Artes",
        "05 - Documentos & PDFs",
        "06 - Capturas e Gravações de Tela",
        "07 - Backups & Arquivos"
    ]
    
    private let subfoldersToEnsure = [
        "01 - Projetos & Sistemas",
        "01 - Projetos & Sistemas/Scripts Python (Tucunare)",
        "02 - Orçamentos & Contratos",
        "03 - Fotos, Vídeos & Drone",
        "03 - Fotos, Vídeos & Drone/Mídias Soltas",
        "04 - Design & Artes",
        "04 - Design & Artes/Editáveis (PSD, AI, SVG)",
        "04 - Design & Artes/Peças e Imagens",
        "05 - Documentos & PDFs",
        "06 - Capturas e Gravações de Tela",
        "06 - Capturas e Gravações de Tela/Capturas de Tela (Prints)",
        "06 - Capturas e Gravações de Tela/Gravações de Tela (Vídeos)",
        "07 - Backups & Arquivos"
    ]
    
    private init() {
        scanUnorganizedCounts()
    }
    
    public func scanUnorganizedCounts() {
        let dPath = self.desktopPath
        let dlPath = self.downloadsPath
        Task.detached(priority: .background) {
            let deskCount = self.countUnorganized(in: dPath)
            let downCount = self.countUnorganized(in: dlPath)
            
            await MainActor.run {
                self.unorganizedDesktopCount = deskCount
                self.unorganizedDownloadsCount = downCount
            }
        }
    }
    
    public func organizeDesktop() {
        runOrganization(targets: [.desktop])
    }
    
    public func organizeDownloads() {
        runOrganization(targets: [.downloads])
    }
    
    public func organizeBoth() {
        runOrganization(targets: [.desktop, .downloads])
    }
    
    public enum OrganizeTarget: Sendable {
        case desktop
        case downloads
    }
    
    private func runOrganization(targets: [OrganizeTarget]) {
        guard !isOrganizing else { return }
        isOrganizing = true
        lastResult = "Organizando arquivos em categorias inteligentes..."
        
        let shouldDesktop = targets.contains(.desktop)
        let shouldDownloads = targets.contains(.downloads)
        let dPath = self.desktopPath
        let dlPath = self.downloadsPath
        
        Task.detached(priority: .userInitiated) {
            var desktopCount = 0
            var downloadsCount = 0
            
            if shouldDesktop {
                desktopCount = self.executeOrganize(directory: dPath)
            }
            if shouldDownloads {
                downloadsCount = self.executeOrganize(directory: dlPath)
            }
            
            let total = desktopCount + downloadsCount
            let msg: String
            if total == 0 {
                msg = "Tudo em ordem! Nenhum arquivo precisava ser movido."
            } else if total == 1 {
                msg = "1 item foi organizado com sucesso!"
            } else {
                msg = "\(total) itens organizados com sucesso nas 7 categorias!"
            }
            
            await MainActor.run {
                self.isOrganizing = false
                self.lastOrganizedCount = total
                self.lastResult = msg
                self.lastRunDate = Date()
                self.scanUnorganizedCounts()
                
                NSSound.beep()
            }
        }
    }
    
    private nonisolated func countUnorganized(in directory: String) -> Int {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(atPath: directory) else { return 0 }
        
        var count = 0
        for item in items {
            if isIgnored(item, in: directory) { continue }
            count += 1
        }
        return count
    }
    
    private nonisolated func executeOrganize(directory: String) -> Int {
        let fm = FileManager.default
        
        // 1. Garantir que as pastas existem
        for sub in subfoldersToEnsure {
            let full = (directory as NSString).appendingPathComponent(sub)
            try? fm.createDirectory(atPath: full, withIntermediateDirectories: true)
        }
        
        guard let items = try? fm.contentsOfDirectory(atPath: directory) else { return 0 }
        var moved = 0
        
        for item in items {
            if isIgnored(item, in: directory) { continue }
            
            let srcPath = (directory as NSString).appendingPathComponent(item)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: srcPath, isDirectory: &isDir) else { continue }
            
            let destRel: String?
            if isDir.boolValue {
                destRel = classifyDirectory(dirPath: srcPath, name: item)
            } else {
                destRel = classifyFile(name: item)
            }
            
            if let destRel = destRel {
                let destDir = (directory as NSString).appendingPathComponent(destRel)
                if safeMove(src: srcPath, destDir: destDir, itemName: item) {
                    moved += 1
                }
            }
        }
        
        return moved
    }
    
    private nonisolated func isIgnored(_ item: String, in directory: String) -> Bool {
        if item.hasPrefix(".") { return true }
        if item == ".DS_Store" || item == ".localized" { return true }
        if item == "Organizar Mesa.app" || item == "ReStats.app" { return true }
        if mainFolders.contains(item) { return true }
        return false
    }
    
    private nonisolated func safeMove(src: String, destDir: String, itemName: String) -> Bool {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: destDir, withIntermediateDirectories: true)
        
        let target = (destDir as NSString).appendingPathComponent(itemName)
        if !fm.fileExists(atPath: target) {
            do {
                try fm.moveItem(atPath: src, toPath: target)
                return true
            } catch {
                return false
            }
        }
        
        // Colisão: adiciona contador "(1)", "(2)"
        let nsItem = itemName as NSString
        let ext = nsItem.pathExtension
        let base = nsItem.deletingPathExtension
        
        var counter = 1
        while true {
            let candidateName = ext.isEmpty ? "\(base) (\(counter))" : "\(base) (\(counter)).\(ext)"
            let candidatePath = (destDir as NSString).appendingPathComponent(candidateName)
            if !fm.fileExists(atPath: candidatePath) {
                do {
                    try fm.moveItem(atPath: src, toPath: candidatePath)
                    return true
                } catch {
                    return false
                }
            }
            counter += 1
        }
    }
    
    private nonisolated func classifyDirectory(dirPath: String, name: String) -> String? {
        let lower = name.lowercased()
        
        if lower.hasPrefix("google drive (not synced)") {
            return "07 - Backups & Arquivos"
        }
        
        if lower.contains("orcamento") || lower.contains("orçamento") || lower.contains("proposta") || lower.contains("contrato") || lower.contains("minuta") {
            return "02 - Orçamentos & Contratos"
        }
        
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: dirPath) else { return nil }
        let validEntries = entries.filter { !$0.hasPrefix(".") && $0 != ".DS_Store" }
        
        if validEntries.isEmpty {
            if lower.hasPrefix("pasta sem título") || lower.hasPrefix("untitled folder") {
                try? fm.removeItem(atPath: dirPath)
            }
            return nil
        }
        
        let lowerEntries = validEntries.map { $0.lowercased() }
        
        // 1. Projeto / Código
        if lowerEntries.contains(where: {
            $0 == "package.json" || $0 == "index.html" || $0 == "index.php" || $0 == "tsconfig.json" || $0 == "requirements.txt" || $0 == ".git"
            || $0.hasSuffix(".py") || $0.hasSuffix(".js") || $0.hasSuffix(".ts") || $0.hasSuffix(".php") || $0.hasSuffix(".apk")
        }) {
            return "01 - Projetos & Sistemas"
        }
        
        // 2. Design
        if lowerEntries.contains(where: { $0.hasSuffix(".psd") || $0.hasSuffix(".ai") || $0.hasSuffix(".svg") || $0.hasSuffix(".eps") || $0.hasSuffix(".fig") }) {
            return "04 - Design & Artes"
        }
        
        // 3. Mídia / Drone
        if lowerEntries.contains(where: {
            $0.hasSuffix(".mp4") || $0.hasSuffix(".mov") || $0.hasSuffix(".arw") || $0.hasSuffix(".cr2") || $0.hasSuffix(".cr3") || $0.hasSuffix(".dng")
            || $0.hasPrefix("dji_") || $0.hasPrefix("img_") || $0.hasPrefix("dsc")
        }) {
            return "03 - Fotos, Vídeos & Drone"
        }
        
        // 4. Documentos
        if lowerEntries.contains(where: { $0.hasSuffix(".pdf") || $0.hasSuffix(".docx") || $0.hasSuffix(".doc") || $0.hasSuffix(".xlsx") || $0.hasSuffix(".pptx") }) {
            return "05 - Documentos & PDFs"
        }
        
        return nil
    }
    
    private nonisolated func classifyFile(name: String) -> String? {
        let lower = name.lowercased()
        
        // Ignorar downloads temporários
        if lower.hasSuffix(".crdownload") || lower.hasSuffix(".download") || lower.hasSuffix(".part") || lower.hasSuffix(".tmp") {
            return nil
        }
        
        // 1. Capturas de Tela
        if lower.hasPrefix("captura de tela") || lower.hasPrefix("screen shot") || lower.hasPrefix("screenshot") || lower.hasPrefix("fundo de captura de tela") {
            return "06 - Capturas e Gravações de Tela/Capturas de Tela (Prints)"
        }
        
        // 2. Gravações de Tela
        if lower.hasPrefix("gravação de tela") || lower.hasPrefix("screen recording") {
            return "06 - Capturas e Gravações de Tela/Gravações de Tela (Vídeos)"
        }
        
        // 3. Orçamentos e Contratos
        if lower.contains("orcamento") || lower.contains("orçamento") || lower.contains("proposta") || lower.contains("contrato") || lower.contains("minuta") {
            return "02 - Orçamentos & Contratos"
        }
        
        // 4. Scripts e Código
        if lower.hasSuffix(".py") || lower.hasSuffix(".js") || lower.hasSuffix(".ts") || lower.hasSuffix(".sh") || lower.hasSuffix(".sql")
            || lower.hasSuffix(".php") || lower.hasSuffix(".html") || lower.hasSuffix(".css") || lower.hasSuffix(".json") {
            return "01 - Projetos & Sistemas/Scripts Python (Tucunare)"
        }
        
        // 5. Backups, compactados e instaladores
        if lower.hasSuffix(".tar.gz") || lower.hasSuffix(".tgz") || lower.hasSuffix(".zip") || lower.hasSuffix(".rar") || lower.hasSuffix(".7z")
            || lower.hasSuffix(".tar") || lower.hasSuffix(".gz") || lower.hasSuffix(".dmg") || lower.hasSuffix(".pkg") || lower.hasSuffix(".iso")
            || lower.hasSuffix(".ffs_gui") || lower.hasSuffix(".apk") {
            return "07 - Backups & Arquivos"
        }
        
        // 6. Editáveis de Design
        if lower.hasSuffix(".psd") || lower.hasSuffix(".psb") || lower.hasSuffix(".ai") || lower.hasSuffix(".svg") || lower.hasSuffix(".eps")
            || lower.hasSuffix(".cdr") || lower.hasSuffix(".indd") || lower.hasSuffix(".fig") {
            return "04 - Design & Artes/Editáveis (PSD, AI, SVG)"
        }
        
        // 7. Vídeos, Áudios e Fotos brutas de Câmera/Drone
        if lower.hasSuffix(".mov") || lower.hasSuffix(".mp4") || lower.hasSuffix(".m4v") || lower.hasSuffix(".avi") || lower.hasSuffix(".mkv")
            || lower.hasSuffix(".mp3") || lower.hasSuffix(".wav") || lower.hasSuffix(".m4a") || lower.hasSuffix(".arw") || lower.hasSuffix(".cr2")
            || lower.hasSuffix(".cr3") || lower.hasSuffix(".nef") || lower.hasSuffix(".dng") || lower.hasSuffix(".heic")
            || lower.hasPrefix("dji_") || lower.hasPrefix("img_") || lower.hasPrefix("dsc") {
            return "03 - Fotos, Vídeos & Drone/Mídias Soltas"
        }
        
        // 8. Documentos, Planilhas, Textos
        if lower.hasSuffix(".pdf") || lower.hasSuffix(".doc") || lower.hasSuffix(".docx") || lower.hasSuffix(".xls") || lower.hasSuffix(".xlsx")
            || lower.hasSuffix(".csv") || lower.hasSuffix(".ppt") || lower.hasSuffix(".pptx") || lower.hasSuffix(".txt") || lower.hasSuffix(".md")
            || lower.hasSuffix(".rtf") || lower.hasSuffix(".pages") || lower.hasSuffix(".numbers") || lower.hasSuffix(".key") {
            return "05 - Documentos & PDFs"
        }
        
        // 9. Peças Gráficas e Imagens
        if lower.hasSuffix(".png") || lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".webp") || lower.hasSuffix(".gif")
            || lower.hasSuffix(".bmp") || lower.hasSuffix(".tiff") || lower.hasSuffix(".ico") {
            return "04 - Design & Artes/Peças e Imagens"
        }
        
        // Demais arquivos avulsos
        return "05 - Documentos & PDFs"
    }
}
