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
                        Text("Edição Nativa macOS • Apple Silicon")
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
                    
                    Text("O **ResetExplode MAC** é uma adaptação 100% nativa desenvolvida em Swift para o ecossistema Apple Silicon (M1, M2, M3, M4, M5), trazendo as consagradas ferramentas de diagnóstico de hardware, benchmarks e utilitários para computadores Mac.")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                CardView {
                    Text("CRÉDITOS E ATRIBUIÇÃO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("• **Conceito Original & Benchmarks:** Desenvolvido originalmente por **GustavoReset** ([github.com/GustavoReset/ResetExplode](https://github.com/GustavoReset/ResetExplode)) sob licença MIT.\n• **Portabilidade & Edição macOS:** Desenvolvido por **DL MIDIA** ([github.com/DLMIDIA/ResetExplode_MAC](https://github.com/DLMIDIA/ResetExplode_MAC)).")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                CardView {
                    Text("LICENÇA DE CÓDIGO ABERTO (MIT)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text("Este software é distribuído gratuitamente sob os termos da licença MIT. Você tem a liberdade de usar, modificar e distribuir, mantendo os devidos créditos de autoria originais.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
        }
    }
}
