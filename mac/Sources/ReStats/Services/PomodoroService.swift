import Foundation
import AppKit

public enum PomodoroMode: String, CaseIterable, Identifiable, Sendable {
    case focus = "Foco Profundo"
    case shortBreak = "Pausa Curta"
    case longBreak = "Pausa Longa"
    
    public var id: String { rawValue }
    
    public var durationSeconds: Int {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
    
    public var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "bed.double.fill"
        }
    }
}

public enum PomodoroState: Sendable {
    case idle
    case running
    case paused
}

@MainActor
public final class PomodoroService: ObservableObject {
    public static let shared = PomodoroService()
    
    @Published public var currentMode: PomodoroMode = .focus
    @Published public var state: PomodoroState = .idle
    @Published public var secondsRemaining: Int = 25 * 60
    @Published public var completedSessions: Int = 0
    
    private var timer: Timer?
    
    private init() {
        self.secondsRemaining = currentMode.durationSeconds
    }
    
    public func start() {
        if state == .idle {
            secondsRemaining = currentMode.durationSeconds
        }
        state = .running
        startTimer()
    }
    
    public func pause() {
        state = .paused
        timer?.invalidate()
        timer = nil
    }
    
    public func reset() {
        state = .idle
        timer?.invalidate()
        timer = nil
        secondsRemaining = currentMode.durationSeconds
    }
    
    public func switchMode(_ mode: PomodoroMode) {
        currentMode = mode
        reset()
    }
    
    public func skip() {
        completeCycle()
    }
    
    public var formattedTime: String {
        let mins = secondsRemaining / 60
        let secs = secondsRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    public var progress: Double {
        let total = Double(currentMode.durationSeconds)
        return total > 0 ? (1.0 - (Double(secondsRemaining) / total)) : 0.0
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.secondsRemaining > 1 {
                    self.secondsRemaining -= 1
                } else {
                    self.completeCycle()
                }
            }
        }
    }
    
    private func completeCycle() {
        timer?.invalidate()
        timer = nil
        
        NSSound.beep()
        
        if currentMode == .focus {
            completedSessions += 1
            if completedSessions % 4 == 0 {
                currentMode = .longBreak
            } else {
                currentMode = .shortBreak
            }
        } else {
            currentMode = .focus
        }
        
        state = .idle
        secondsRemaining = currentMode.durationSeconds
    }
}
