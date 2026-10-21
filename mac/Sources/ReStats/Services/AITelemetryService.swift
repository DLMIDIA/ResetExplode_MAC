import Foundation
import SQLite3
import AppKit

public struct AISessionItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let stepCount: Int
    public let lastModified: String
    
    public init(id: String, title: String, stepCount: Int, lastModified: String) {
        self.id = id
        self.title = title.isEmpty ? "Sessão Sem Título" : title
        self.stepCount = stepCount
        self.lastModified = lastModified
    }
}

@MainActor
public final class AITelemetryService: ObservableObject {
    public static let shared = AITelemetryService()
    
    @Published public var totalSessions: Int = 0
    @Published public var totalSteps: Int = 0
    @Published public var estimatedTokens: Int64 = 0
    @Published public var recentSessions: [AISessionItem] = []
    
    @Published public var hasVibeToolkit: Bool = false
    @Published public var vibeToolkitPath: String = ""
    @Published public var isRunningAction: Bool = false
    @Published public var actionConsoleOutput: String = ""
    
    private let dbPath: String = ("~/.gemini/antigravity/conversation_summaries.db" as NSString).expandingTildeInPath
    private let defaultVibeCli: String = ("~/.local/bin/agy-vibe" as NSString).expandingTildeInPath
    
    private init() {
        checkVibeToolkit()
        refreshTelemetry()
    }
    
    public func checkVibeToolkit() {
        let fm = FileManager.default
        if fm.fileExists(atPath: defaultVibeCli) {
            hasVibeToolkit = true
            vibeToolkitPath = defaultVibeCli
        } else if fm.fileExists(atPath: "/usr/local/bin/agy-vibe") {
            hasVibeToolkit = true
            vibeToolkitPath = "/usr/local/bin/agy-vibe"
        } else {
            hasVibeToolkit = false
            vibeToolkitPath = ""
        }
    }
    
    public func refreshTelemetry() {
        Task.detached(priority: .userInitiated) {
            var db: OpaquePointer?
            let dbFile = self.dbPath
            
            guard sqlite3_open_v2(dbFile, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
                return
            }
            defer { sqlite3_close(db) }
            
            var sessions = 0
            var steps: Int64 = 0
            var items: [AISessionItem] = []
            
            // 1. Contagem Geral
            var statStatement: OpaquePointer?
            if sqlite3_prepare_v2(db, "SELECT count(*), sum(step_count) FROM conversation_summaries;", -1, &statStatement, nil) == SQLITE_OK {
                if sqlite3_step(statStatement) == SQLITE_ROW {
                    sessions = Int(sqlite3_column_int(statStatement, 0))
                    steps = sqlite3_column_int64(statStatement, 1)
                }
                sqlite3_finalize(statStatement)
            }
            
            // 2. Últimas Sessões
            var listStatement: OpaquePointer?
            let query = "SELECT conversation_id, title, step_count, last_modified_time FROM conversation_summaries ORDER BY last_modified_time DESC LIMIT 6;"
            if sqlite3_prepare_v2(db, query, -1, &listStatement, nil) == SQLITE_OK {
                while sqlite3_step(listStatement) == SQLITE_ROW {
                    let convId = String(cString: sqlite3_column_text(listStatement, 0))
                    let rawTitle = sqlite3_column_text(listStatement, 1)
                    let title = rawTitle != nil ? String(cString: rawTitle!) : ""
                    let count = Int(sqlite3_column_int(listStatement, 2))
                    let rawDate = sqlite3_column_text(listStatement, 3)
                    let dateStr = rawDate != nil ? String(cString: rawDate!) : ""
                    
                    let formattedDate = self.formatSQLiteDate(dateStr)
                    items.append(AISessionItem(id: convId, title: title, stepCount: count, lastModified: formattedDate))
                }
                sqlite3_finalize(listStatement)
            }
            
            let estTokens = steps * 2500 // Média estimada de contexto por step
            
            await MainActor.run {
                self.totalSessions = sessions
                self.totalSteps = Int(steps)
                self.estimatedTokens = estTokens
                self.recentSessions = items
            }
        }
    }
    
    private nonisolated func formatSQLiteDate(_ raw: String) -> String {
        // Exemplo de formato: "2026-10-21 02:41:07.627393+00:00"
        let parts = raw.split(separator: " ")
        if parts.count >= 2 {
            let timePart = parts[1].split(separator: ".")[0]
            return "\(parts[0]) \(timePart)"
        }
        return raw
    }
    
    public func runAutopilot() {
        guard hasVibeToolkit, !isRunningAction else { return }
        executeVibeCommand(arguments: ["autopilot", "."])
    }
    
    public func runVerify() {
        guard hasVibeToolkit, !isRunningAction else { return }
        executeVibeCommand(arguments: ["verify"])
    }
    
    private func executeVibeCommand(arguments: [String]) {
        isRunningAction = true
        actionConsoleOutput = "Executando: agy-vibe \(arguments.joined(separator: " "))...\n"
        
        let cliPath = vibeToolkitPath
        Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: cliPath)
            process.arguments = arguments
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? "Concluído sem saída."
                
                await MainActor.run {
                    self.isRunningAction = false
                    self.actionConsoleOutput = output
                }
            } catch {
                await MainActor.run {
                    self.isRunningAction = false
                    self.actionConsoleOutput = "Erro ao executar comando: \(error.localizedDescription)"
                }
            }
        }
    }
    
    public func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
    
    public func formatTokenCount(_ tokens: Int64) -> String {
        if tokens >= 1_000_000_000 {
            return String(format: "%.2f B", Double(tokens) / 1_000_000_000.0)
        } else if tokens >= 1_000_000 {
            return String(format: "%.1f M", Double(tokens) / 1_000_000.0)
        } else if tokens >= 1_000 {
            return String(format: "%.1f k", Double(tokens) / 1_000.0)
        } else {
            return "\(tokens)"
        }
    }
}
