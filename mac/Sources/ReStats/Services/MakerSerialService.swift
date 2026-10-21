import Foundation

public final class MakerSerialService: @unchecked Sendable {
    public static let shared = MakerSerialService()
    
    private init() {}
    
    public func scanSerialPorts() -> [SerialPortInfo] {
        let fileManager = FileManager.default
        var results: [SerialPortInfo] = []
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: "/dev")
            // No Mac, cu.* (Call-Up) é a interface recomendada para comunicação serial sem bloqueio
            let ports = files.filter { $0.hasPrefix("cu.") }
            
            for p in ports {
                let fullPath = "/dev/\(p)"
                let typeGuess = guessDeviceType(name: p)
                results.append(SerialPortInfo(path: fullPath, name: p, deviceType: typeGuess))
            }
        } catch {
            print("Erro ao listar portas seriais:", error)
        }
        
        return results
    }
    
    private func guessDeviceType(name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("usbmodem") {
            return "Arduino / RPi Pico (USB CDC)"
        } else if lower.contains("wch") || lower.contains("ch340") || lower.contains("ch341") {
            return "Chip WCH CH340/CH341 (Arduino Clone / ESP8266)"
        } else if lower.contains("slab") || lower.contains("cp210") {
            return "Silicon Labs CP2102/CP2104 (ESP32 / NodeMCU)"
        } else if lower.contains("ftdi") || lower.contains("usbserial") {
            return "Conversor FTDI / ESP32 USB-Serial"
        } else if lower.contains("bluetooth") {
            return "Porta Serial Bluetooth"
        } else if lower.contains("debug") {
            return "Console Interno macOS"
        }
        return "Dispositivo Serial / USB"
    }
}
