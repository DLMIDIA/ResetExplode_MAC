import SwiftUI

public enum SidebarTab: String, CaseIterable, Identifiable {
    case dashboard = "Sistema & Sensores"
    case benchmark = "ReStats Bench"
    case network = "ReStats Rede"
    case optimizer = "ReStats Otimiza"
    case productivity = "Produtividade & Automação"
    case menubar = "Barra de Menus"
    case about = "Sobre & Créditos"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .dashboard: return "gauge.with.needle.fill"
        case .benchmark: return "speedometer"
        case .network: return "network"
        case .optimizer: return "sparkles"
        case .productivity: return "timer"
        case .menubar: return "menubar.rectangle"
        case .about: return "info.circle.fill"
        }
    }
}

public struct MainView: View {
    @State private var selectedTab: SidebarTab = .dashboard
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header Branded ReStats
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.cyan.opacity(0.85), Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.cyan.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("ReStats")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("M-SERIES")
                                .font(.system(size: 8, weight: .heavy))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.2))
                                .foregroundColor(.cyan)
                                .cornerRadius(4)
                        }
                        
                        Text("Reset + Stats Suite")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 12)
                
                Divider()
                    .padding(.bottom, 6)
                
                List(SidebarTab.allCases, selection: $selectedTab) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .font(.system(size: 13, weight: .medium))
                    }
                }
                .listStyle(.sidebar)
                
                Divider()
                
                // Footer
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    
                    Text("ReStats v1.2.0")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("DL MIDIA")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 270)
        } detail: {
            switch selectedTab {
            case .dashboard:
                DashboardView()
            case .benchmark:
                BenchmarkView()
            case .network:
                NetworkView()
            case .optimizer:
                OptimizerView()
            case .productivity:
                ProductivityView()
            case .menubar:
                MenuBarSettingsView()
            case .about:
                AboutView()
            }
        }
        .frame(minWidth: 920, minHeight: 640)
    }
}
