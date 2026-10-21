import SwiftUI

public struct MakerView: View {
    @State private var ports = MakerSerialService.shared.scanSerialPorts()
    @State private var isScanning = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RESET MAKER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("Diagnóstico de Placas e Portas USB/Serial")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                CardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DISPOSITIVOS SERIAIS CONECTADOS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            Text("Mapeamento de portas para Arduino, ESP32 e Conversores")
                                .font(.headline)
                            Text("Identifica portas /dev/cu.* ativas para programação e depuração no Mac.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: scanPorts) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text(isScanning ? "Escaneando..." : "Atualizar Portas")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(isScanning)
                    }
                    
                    Divider()
                    
                    if ports.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "cable.connector.slash")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary)
                            Text("Nenhuma placa ou porta serial detectada no momento.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Conecte seu Arduino, ESP32 ou conversor USB via cabo e clique em Atualizar.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(ports) { port in
                                HStack(spacing: 14) {
                                    Image(systemName: "cpu")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                        .padding(8)
                                        .background(Color.purple.opacity(0.15))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(port.path)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        Text(port.deviceType)
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("Pronta")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.green.opacity(0.1))
                                        .foregroundColor(.green)
                                        .cornerRadius(6)
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
    
    private func scanPorts() {
        isScanning = true
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            let res = MakerSerialService.shared.scanSerialPorts()
            DispatchQueue.main.async {
                self.ports = res
                self.isScanning = false
            }
        }
    }
}
