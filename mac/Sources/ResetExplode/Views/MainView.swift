import SwiftUI

public enum SidebarTab: String, CaseIterable, Identifiable {
    case dashboard = "Sistema"
    case benchmark = "Reset Bench"
    case network = "Reset Rede"
    case optimizer = "Reset Otimiza"
    case menubar = "Barra de Menus"
    case maker = "Reset Maker"
    case about = "Sobre & Créditos"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .dashboard: return "gauge.with.needle.fill"
        case .benchmark: return "speedometer"
        case .network: return "network"
        case .optimizer: return "sparkles"
        case .menubar: return "menubar.rectangle"
        case .maker: return "cpu"
        case .about: return "info.circle"
        }
    }
}

public struct MainView: View {
    @State private var selectedTab: SidebarTab = .dashboard
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(SidebarTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 260)
            
            VStack {
                Spacer()
                Text("RESET EXPLODE MAC")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)
            }
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
            case .menubar:
                MenuBarSettingsView()
            case .maker:
                MakerView()
            case .about:
                AboutView()
            }
        }
        .frame(minWidth: 880, minHeight: 600)
    }
}
