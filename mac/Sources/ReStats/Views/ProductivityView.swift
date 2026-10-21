import SwiftUI

public struct ProductivityView: View {
    @StateObject private var pomodoro = PomodoroService.shared
    @StateObject private var powerScheduler = PowerScheduleService.shared
    @StateObject private var updateService = SoftwareUpdateService.shared
    
    @State private var selectedPowerMinutes: Int = 60
    @State private var customTargetTime: Date = Date().addingTimeInterval(3600)
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerBanner
                
                // Grid de 2 Colunas para Pomodoro e Desligamento
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    pomodoroCard
                    powerScheduleCard
                }
                
                // Seção de Atualizações do Sistema
                softwareUpdateCard
            }
            .padding(24)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle("Produtividade & Energia")
    }
    
    // MARK: - Header
    private var headerBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color.indigo, Color.purple, Color.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Produtividade & Energia")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    Text("Vorssaint + Stats Engine")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
                
                Text("Gerencie ciclos de foco Pomodoro, desligamento programado e atualizações do macOS.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
    
    // MARK: - Pomodoro Card
    private var pomodoroCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Pomodoro Focus Timer", systemImage: pomodoro.currentMode.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if pomodoro.completedSessions > 0 {
                    Text("\(pomodoro.completedSessions) ciclos")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            
            // Mode Selector
            Picker("Modo", selection: Binding(
                get: { pomodoro.currentMode },
                set: { pomodoro.switchMode($0) }
            )) {
                ForEach(PomodoroMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            // Visual Ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                    .frame(width: 130, height: 130)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(pomodoro.progress))
                    .stroke(
                        LinearGradient(
                            colors: pomodoro.currentMode == .focus ? [Color.orange, Color.red] : [Color.green, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 130, height: 130)
                    .animation(.linear(duration: 0.3), value: pomodoro.progress)
                
                VStack(spacing: 2) {
                    Text(pomodoro.formattedTime)
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text(pomodoro.state == .running ? "EM ANDAMENTO" : (pomodoro.state == .paused ? "PAUSADO" : "PRONTO"))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(pomodoro.state == .running ? .green : .secondary)
                }
            }
            .padding(.vertical, 6)
            
            // Controls
            HStack(spacing: 12) {
                if pomodoro.state == .running {
                    Button(action: { pomodoro.pause() }) {
                        Label("Pausar", systemImage: "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    Button(action: { pomodoro.start() }) {
                        Label(pomodoro.state == .paused ? "Continuar" : "Iniciar", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                
                Button(action: { pomodoro.skip() }) {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.bordered)
                .help("Pular para a próxima etapa")
                
                Button(action: { pomodoro.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .help("Reiniciar tempo")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
    
    // MARK: - Power Schedule Card
    private var powerScheduleCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Desligamento & Repouso", systemImage: powerScheduler.selectedAction.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if powerScheduler.isScheduled {
                    Text("ATIVO")
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            // Action Picker
            Picker("Ação", selection: $powerScheduler.selectedAction) {
                ForEach(PowerAction.allCases) { action in
                    Text(action.rawValue).tag(action)
                }
            }
            .pickerStyle(.segmented)
            
            if powerScheduler.isScheduled {
                // Active Countdown Display
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    
                    Text("Agendamento em Execução")
                        .font(.system(size: 13, weight: .semibold))
                    
                    Text(powerScheduler.formattedRemainingTime)
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text("O sistema irá executar '\(powerScheduler.selectedAction.rawValue)' ao término da contagem.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { powerScheduler.cancelSchedule() }) {
                        Label("Cancelar Agendamento", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding(.top, 6)
                }
                .padding(.vertical, 10)
            } else {
                // Presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Agendar após intervalo:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Button("30 min") {
                            powerScheduler.scheduleIn(minutes: 30, action: powerScheduler.selectedAction)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("1 hora") {
                            powerScheduler.scheduleIn(minutes: 60, action: powerScheduler.selectedAction)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("2 horas") {
                            powerScheduler.scheduleIn(minutes: 120, action: powerScheduler.selectedAction)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("4 horas") {
                            powerScheduler.scheduleIn(minutes: 240, action: powerScheduler.selectedAction)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Divider()
                
                // Horário Fixo
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ou desligar em horário específico:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        DatePicker("", selection: $customTargetTime, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.field)
                        
                        Button(action: {
                            let cal = Calendar.current
                            let h = cal.component(.hour, from: customTargetTime)
                            let m = cal.component(.minute, from: customTargetTime)
                            powerScheduler.scheduleAt(hour: h, minute: m, action: powerScheduler.selectedAction)
                        }) {
                            Label("Confirmar", systemImage: "checkmark")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
    
    // MARK: - Software Update Card
    private var softwareUpdateCard: some View {
        VStack(spacing: 14) {
            HStack {
                Label("Atualizações do macOS", systemImage: "gear.badge.checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(updateService.currentOSVersion)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(updateService.statusMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(updateService.hasUpdates ? .orange : .secondary)
                    
                    if let last = updateService.lastChecked {
                        let formatter = DateFormatter()
                        let _ = { formatter.dateStyle = .short; formatter.timeStyle = .short }()
                        Text("Última verificação: \(formatter.string(from: last))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
                
                Spacer()
                
                if updateService.isChecking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(action: { updateService.checkForUpdates() }) {
                        Label("Verificar Atualizações", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
                
                Button(action: { updateService.openSystemUpdateSettings() }) {
                    Label("Ajustes do Sistema...", systemImage: "arrow.up.forward.app")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}
