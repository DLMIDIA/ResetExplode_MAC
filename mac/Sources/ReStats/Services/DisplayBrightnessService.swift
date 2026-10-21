import Foundation
import CoreGraphics
import AppKit

public struct MonitorDisplayItem: Identifiable, Sendable {
    public let id: CGDirectDisplayID
    public let name: String
    public let isMain: Bool
    public var brightness: Float
    
    public init(id: CGDirectDisplayID, name: String, isMain: Bool, brightness: Float) {
        self.id = id
        self.name = name
        self.isMain = isMain
        self.brightness = brightness
    }
}

public final class DisplayBrightnessService: @unchecked Sendable {
    public static let shared = DisplayBrightnessService()
    
    private typealias GetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32
    
    private var getBrightnessFunc: GetBrightnessFunc?
    private var setBrightnessFunc: SetBrightnessFunc?
    
    // Cache de brilho por display
    private var brightnessCache: [CGDirectDisplayID: Float] = [:]
    
    private init() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW) {
            if let getSym = dlsym(handle, "DisplayServicesGetBrightness") {
                getBrightnessFunc = unsafeBitCast(getSym, to: GetBrightnessFunc.self)
            }
            if let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
                setBrightnessFunc = unsafeBitCast(setSym, to: SetBrightnessFunc.self)
            }
        }
    }
    
    @MainActor
    public func getConnectedDisplays() -> [MonitorDisplayItem] {
        var displays: [MonitorDisplayItem] = []
        
        for screen in NSScreen.screens {
            let desc = screen.deviceDescription
            let id = (desc[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? CGMainDisplayID()
            let name = screen.localizedName
            let isMain = screen == NSScreen.main
            let current = getBrightness(displayID: id)
            
            displays.append(MonitorDisplayItem(id: id, name: name, isMain: isMain, brightness: current))
        }
        
        return displays
    }
    
    public func getBrightness(displayID: CGDirectDisplayID = CGMainDisplayID()) -> Float {
        if let cached = brightnessCache[displayID] {
            return cached
        }
        
        if let getFunc = self.getBrightnessFunc {
            var val: Float = 1.0
            let res = getFunc(displayID, &val)
            if res == 0 {
                let clamped = max(0.05, min(1.0, val))
                brightnessCache[displayID] = clamped
                return clamped
            }
        }
        
        return 1.0
    }
    
    public func setBrightness(_ value: Float, displayID: CGDirectDisplayID = CGMainDisplayID()) -> Bool {
        let clamped = max(0.05, min(1.0, value))
        brightnessCache[displayID] = clamped
        
        // 1. Tentar DisplayServices nativo da Apple (funciona em telas internas e Apple Studio/XDR)
        if let setFunc = self.setBrightnessFunc {
            let res = setFunc(displayID, clamped)
            if res == 0 {
                return true
            }
        }
        
        // 2. Fallback para Monitores Externos (LG UltraWide, Dell, etc.) via Tabela Gamma do Quartz
        var redTable = [CGGammaValue](repeating: 0, count: 256)
        var greenTable = [CGGammaValue](repeating: 0, count: 256)
        var blueTable = [CGGammaValue](repeating: 0, count: 256)
        
        for i in 0..<256 {
            let base = CGGammaValue(i) / 255.0
            let dimmed = base * CGGammaValue(clamped)
            redTable[i] = dimmed
            greenTable[i] = dimmed
            blueTable[i] = dimmed
        }
        
        let gammaRes = CGSetDisplayTransferByTable(displayID, 256, &redTable, &greenTable, &blueTable)
        return gammaRes == .success
    }
}
