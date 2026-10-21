import SwiftUI

public struct AboutView: View {
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 16) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.cyan)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RESET EXPLODE")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                        Text("Edição Nativa macOS • Apple Silicon (v1.1.0)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                CardView {
                    Text("SOBRE O PROJETO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                    
                    Text("O **ResetExplode MAC** é uma suíte de software nativa em Swift para o ecossistema Apple Silicon (M1, M2, M3, M4, M5), trazendo ferramentas avançadas de diagnóstico de hardware em tempo real, telemetria contínua na barra de menus, benchmarks de CPU e discos, otimização de memória/caches e ferramentas para eletrônica e makers.")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                CardView {
                    Text("CRÉDITOS, ATRIBUIÇÃO & REFERÊNCIAS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("• **Conceito Original & Benchmarks (Windows):** Criado por **GustavoReset** ([github.com/GustavoReset/ResetExplode](https://github.com/GustavoReset/ResetExplode)) sob licença MIT.")
                        
                        Text("• **Referência de Telemetria macOS & Menu Bar:** Inspirado nas melhores práticas de chamadas ao Mach Kernel e arquitetura de monitoramento do consagrado projeto open-source **Stats** por **Serhiy Mytrovtsiy** ([github.com/exelban/stats](https://github.com/exelban/stats)) sob licença MIT.")
                        
                        Text("• **Adaptação, Arquitetura Apple Silicon & Suíte Mac:** Desenvolvido por **DL MIDIA** ([github.com/DLMIDIA/ResetExplode_MAC](https://github.com/DLMIDIA/ResetExplode_MAC)).")
                    }
                    .font(.callout)
                    .foregroundColor(.secondary)
                }
                
                CardView {
                    Text("LICENÇA DE CÓDIGO ABERTO (MIT)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text("Este software é distribuído gratuitamente sob os termos da licença MIT. Você tem a liberdade de usar, modificar e distribuir o código-fonte, preservando os devidos créditos de autoria.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
        }
    }
}
