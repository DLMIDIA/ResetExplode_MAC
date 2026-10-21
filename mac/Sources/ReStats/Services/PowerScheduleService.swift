import Foundation
import AppKit

public enum PowerAction: String, CaseIterable, Identifiable, Sendable {
    case shutdown = "Desligar Computador"
    case sleep = "Entrar em Repouso"
    case restart = "Reiniciar Sistema"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .shutdown: return "power"
        case .sleep: return "moon.fill"
        case .restart: return "arrow.clockwise"
        }
    }
}

@MainActor
public final class PowerScheduleService: ObservableObject {
    public static let shared = PowerScheduleService()
    
    @Published public var isScheduled: Bool = false
    @Published public var targetDate: Date? = nil
    @Published public var selectedAction: PowerAction = .shutdown
    @Published public var remainingSeconds: Int = 0
    
    private var timer: Timer?
    
    private init() {}
    
    public func scheduleIn(minutes: Int, action: PowerAction = .shutdown) {
        cancelSchedule()
        
        selectedAction = action
        let target = Date().addingTimeInterval(Double(minutes * 60))
        targetDate = target
        isScheduled = true
        remainingSeconds = minutes * 60
        
        startTimer()
    }
    
    public func scheduleAt(hour: Int, minute: Int, action: PowerAction = .shutdown) {
        cancelSchedule()
        
        selectedAction = action
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        guard var target = calendar.date(from: components) else { return }
        
        // Se o horário já passou hoje, agenda para o dia seguinte
        if target <= Date() {
            target = target.addingTimeInterval(86400)
        }
        
        targetDate = target
        isScheduled = true
        remainingSeconds = max(0, Int(target.timeIntervalSinceNow))
        
        startTimer()
    }
    
    public func cancelSchedule() {
        timer?.invalidate()
        timer = nil
        isScheduled = false
        targetDate = nil
        remainingSeconds = 0
    }
    
    public var formattedRemainingTime: String {
        guard isScheduled, remainingSeconds > 0 else { return "Nenhum agendamento ativo" }
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60
        
        if hours > 0 {
            return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
        } else {
            return String(format: "%02dm %02ds", minutes, seconds)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard let target = self.targetDate else {
                    self.cancelSchedule()
                    return
                }
                
                let remaining = Int(target.timeIntervalSinceNow)
                if remaining <= 0 {
                    self.executeScheduledPowerAction()
                    self.cancelSchedule()
                } else {
                    self.remainingSeconds = remaining
                }
            }
        }
    }
    
    private func executeScheduledPowerAction() {
        let script: String
        switch selectedAction {
        case .shutdown:
            script = "tell application \"System Events\" to shut down"
        case .sleep:
            script = "tell application \"System Events\" to sleep"
        case .restart:
            script = "tell application \"System Events\" to restart"
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let appleScript = NSAppleScript(source: script)
            var error: NSDictionary?
            appleScript?.executeAndReturnError(&error)
            if let err = error {
                print("Erro ao executar ação agendada: \(err)")
            }
        }
    }
}
