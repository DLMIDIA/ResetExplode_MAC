import Foundation
import CoreGraphics
import AppKit
import IOKit

public struct MonitorDisplayItem: Identifiable, Sendable {
    public let id: CGDirectDisplayID
    public let name: String
    public let isMain: Bool
    public let isBuiltin: Bool
    public var brightness: Float
    
    public init(id: CGDirectDisplayID, name: String, isMain: Bool, isBuiltin: Bool, brightness: Float) {
        self.id = id
        self.name = name
        self.isMain = isMain
        self.isBuiltin = isBuiltin
        self.brightness = brightness
    }
}

// Assinaturas das APIs privadas do IOKit para Apple Silicon DDC/CI
@_silgen_name("IOAVServiceCreateWithService")
private func IOAVServiceCreateWithService(_ allocator: CFAllocator?, _ service: io_service_t) -> Unmanaged<CFTypeRef>?

@_silgen_name("IOAVServiceWriteI2C")
private func IOAVServiceWriteI2C(_ service: CFTypeRef, _ chipAddress: UInt32, _ dataAddress: UInt32, _ inputBuffer: UnsafeMutableRawPointer?, _ inputBufferSize: UInt32) -> IOReturn

// Controlador DDC/CI isolado, sem tocar em atores Swift ou estado compartilhado
private enum DdcCiController {
    static func sendBrightness(percent: UInt8) {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("DCPAVServiceProxy")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return }
        defer { IOObjectRelease(iterator) }
        
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            
            let prop = IORegistryEntryCreateCFProperty(service, "Location" as CFString, kCFAllocatorDefault, 0)
            guard let loc = prop?.takeRetainedValue() as? String, loc == "External" else { continue }
            
            guard let avUnmanaged = IOAVServiceCreateWithService(kCFAllocatorDefault, service) else { continue }
            let avService = avUnmanaged.takeRetainedValue()
            
            // Pacote MCCS DDC/CI para VCP 0x10 (Luminância): [0x84, 0x03, 0x10, 0x00, val, checksum]
            let val = min(100, max(0, percent))
            var packet: [UInt8] = [0x84, 0x03, 0x10, 0x00, val, 0]
            
            // Checksum VESA DDC/CI
            var chk: UInt8 = (0x37 << 1) ^ 0x51
            for i in 0..<5 {
                chk ^= packet[i]
            }
            packet[5] = chk
            
            _ = packet.withUnsafeMutableBytes { buf in
                IOAVServiceWriteI2C(avService, 0x37, 0x51, buf.baseAddress, UInt32(buf.count))
            }
        }
    }
}

@MainActor
public final class DisplayBrightnessService: ObservableObject {
    public static let shared = DisplayBrightnessService()
    
    private typealias GetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32
    
    private var getBrightnessFunc: GetBrightnessFunc?
    private var setBrightnessFunc: SetBrightnessFunc?
    
    private var brightnessCache: [CGDirectDisplayID: Float] = [:]
    private var ddcDebounceWorkItem: DispatchWorkItem?
    
    private init() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW) {
            if let getSym = dlsym(handle, "DisplayServicesGetBrightness") {
                getBrightnessFunc = unsafeBitCast(getSym, to: GetBrightnessFunc.self)
            }
            if let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
                setBrightnessFunc = unsafeBitCast(setSym, to: SetBrightnessFunc.self)
            }
        }
        
        // Restaurar brilhos salvos previamente
        for screen in NSScreen.screens {
            let desc = screen.deviceDescription
            let id = (desc[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
            if id != 0 {
                let saved = UserDefaults.standard.float(forKey: "br.com.dlmidia.restats.brightness.\(id)")
                if saved > 0.04 {
                    brightnessCache[id] = saved
                }
            }
        }
    }
    
    public func getConnectedDisplays() -> [MonitorDisplayItem] {
        var displays: [MonitorDisplayItem] = []
        
        for screen in NSScreen.screens {
            let desc = screen.deviceDescription
            let id = (desc[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? CGMainDisplayID()
            let name = screen.localizedName
            let isMain = screen == NSScreen.main
            let isBuiltin = CGDisplayIsBuiltin(id) != 0
            let current = getBrightness(displayID: id, isBuiltin: isBuiltin)
            
            displays.append(MonitorDisplayItem(id: id, name: name, isMain: isMain, isBuiltin: isBuiltin, brightness: current))
        }
        
        return displays
    }
    
    public func getBrightness(displayID: CGDirectDisplayID = CGMainDisplayID(), isBuiltin: Bool = true) -> Float {
        if let cached = brightnessCache[displayID] {
            return cached
        }
        
        // Se for tela integrada (MacBook), tenta a API da Apple
        if isBuiltin, let getFunc = self.getBrightnessFunc {
            var val: Float = 1.0
            let res = getFunc(displayID, &val)
            if res == 0 {
                let clamped = max(0.05, min(1.0, val))
                brightnessCache[displayID] = clamped
                return clamped
            }
        }
        
        // Tenta carregar do UserDefaults para telas externas
        let saved = UserDefaults.standard.float(forKey: "br.com.dlmidia.restats.brightness.\(displayID)")
        if saved > 0.04 {
            brightnessCache[displayID] = saved
            return saved
        }
        
        return 1.0
    }
    
    @discardableResult
    public func setBrightness(_ value: Float, displayID: CGDirectDisplayID = CGMainDisplayID()) -> Bool {
        let clamped = max(0.05, min(1.0, value))
        brightnessCache[displayID] = clamped
        UserDefaults.standard.set(clamped, forKey: "br.com.dlmidia.restats.brightness.\(displayID)")
        
        let isBuiltin = CGDisplayIsBuiltin(displayID) != 0
        
        if isBuiltin {
            // 1. Tela Integrada Apple: DisplayServices nativo
            if let setFunc = self.setBrightnessFunc {
                _ = setFunc(displayID, clamped)
            }
            return true
        } else {
            // 2. Monitor Externo (LG ULTRAWIDE, etc.): DDC/CI por hardware assíncrono e seguro
            let percent = UInt8(clamped * 100)
            debounceSendDDC(brightnessPercent: percent)
            return true
        }
    }
    
    private func debounceSendDDC(brightnessPercent: UInt8) {
        ddcDebounceWorkItem?.cancel()
        
        // Captura apenas o valor primitivo 'brightnessPercent', sem capturar 'self'
        let workItem = DispatchWorkItem {
            DdcCiController.sendBrightness(percent: brightnessPercent)
        }
        ddcDebounceWorkItem = workItem
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.04, execute: workItem)
    }
}
