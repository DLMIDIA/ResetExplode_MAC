import SwiftUI
import AppKit

public struct AboutView: View {
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Hero
                HStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.cyan, Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 72, height: 72)
                            .shadow(color: Color.cyan.opacity(0.35), radius: 10, x: 0, y: 4)
                        
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("ReStats")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("v1.2.0")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.cyan.opacity(0.18))
                                .foregroundColor(.cyan)
                                .cornerRadius(6)
                        }
                        
                        Text("macOS System Telemetry & Benchmark Suite")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("Arquitetura Nativa Apple Silicon (ARM64) • Swift 6")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 4)
                
                // Card de Fusão dos Projetos
                CardView {
                    HStack(spacing: 8) {
                        Image(systemName: "atom")
                            .foregroundColor(.cyan)
                        Text("A ORIGEM DO RESTATS (RESET + STATS)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                    }
                    
                    Text("O **ReStats** nasce da união harmônica entre duas das ferramentas utilitárias mais celebradas do ecossistema open-source:")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("⚡")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("**Re**set (ResetExplode por GustavoReset):")
                                    .font(.subheadline)
                                    .foregroundColor(.cyan)
                                Text("Do projeto original para Windows, herdamos a atitude destemida de levar o processador ao limite com renderizador determinístico Raytracing Monte Carlo, testes reais de largura de banda STREAM em GB/s, medições diretas de SSD sem cache falso e ferramentas completas para quem cria circuitos eletrônicos (Maker/Serial).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 2)
                        
                        HStack(alignment: .top, spacing: 10) {
                            Text("📊")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("**Stats** (Stats por Serhiy Mytrovtsiy):")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Text("Do mais consagrado monitor de sistema para macOS, incorporamos a sofisticação da telemetria de baixíssimo nível: leitura de carga núcleo a núcleo direto no Mach Kernel (P-Cores e E-Cores), presença contínua e modular na Barra de Menus com consumo nulo de CPU, diagnóstico IOKit de bateria e controle do hardware.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(8)
                }
                
                // Cards de Créditos Individuais
                VStack(alignment: .leading, spacing: 12) {
                    Text("CRÉDITOS, ATRIBUIÇÕES & AUTORIA")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        // GustavoReset
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("GustavoReset")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            Text("Criador do **ResetExplode** original para Windows. Concebeu os algoritmos de benchmark, a lógica de testes de estresse e o ecossistema Maker.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            Link(destination: URL(string: "https://github.com/GustavoReset/ResetExplode")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                    Text("GitHub / ResetExplode")
                                }
                                .font(.caption)
                                .foregroundColor(.cyan)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                        
                        // Serhiy Mytrovtsiy (Stats)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(.green)
                                Text("Serhiy Mytrovtsiy")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            Text("Autor do renomado projeto **Stats** para macOS. Arquiteto do sistema de telemetria Mach Kernel e referência máxima de design na Barra de Menus.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            Link(destination: URL(string: "https://github.com/exelban/stats")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                    Text("GitHub / Stats")
                                }
                                .font(.caption)
                                .foregroundColor(.green)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                        
                        // DL MIDIA
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .foregroundColor(.cyan)
                                Text("DL MIDIA")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            Text("Fusão dos conceitos no **ReStats**, desenvolvimento nativo em Swift 6, engenharia para Apple Silicon M-Series e distribuição do instalador macOS.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                            
                            Link(destination: URL(string: "https://github.com/DLMIDIA/ResetExplode_MAC")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                    Text("Repositório ReStats")
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                    }
                }
                
                // Especificações Técnicas
                CardView {
                    Text("ESPECIFICAÇÕES TÉCNICAS DA EDIÇÃO MACOS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        TechPill(icon: "swift", title: "Linguagem", value: "Swift 6.0 Puro")
                        TechPill(icon: "cpu", title: "Arquitetura", value: "Apple Silicon ARM64")
                        TechPill(icon: "memorychip", title: "Mach Kernel", value: "host_processor_info")
                        TechPill(icon: "sun.max.fill", title: "Monitores", value: "DisplayServices API")
                        TechPill(icon: "speedometer", title: "Speedtest", value: "Cloudflare Edge CDN")
                        TechPill(icon: "leaf.fill", title: "Pegada", value: "< 1 MB (Ultra-leve)")
                    }
                }
                
                // Licença MIT
                CardView {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("LICENÇA DE CÓDIGO ABERTO (MIT)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("O ReStats é um software livre distribuído sob a **Licença MIT**. Você pode utilizá-lo, estudá-lo, bifurcá-lo e adaptá-lo livremente, mantendo os avisos de direitos autorais originais.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
        }
    }
}

private struct TechPill: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(8)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(6)
    }
}
