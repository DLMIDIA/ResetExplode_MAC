import Foundation
import CoreGraphics

public final class DisplayBrightnessService: @unchecked Sendable {
    public static let shared = DisplayBrightnessService()
    
    private typealias GetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32
    
    private var getBrightness: GetBrightnessFunc?
    private var setBrightness: SetBrightnessFunc?
    
    private init() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW) {
            if let getSym = dlsym(handle, "DisplayServicesGetBrightness") {
                getBrightness = unsafeBitCast(getSym, to: GetBrightnessFunc.self)
            }
            if let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
                setBrightness = unsafeBitCast(setSym, to: SetBrightnessFunc.self)
            }
        }
    }
    
    public func getBrightness(displayID: CGDirectDisplayID = CGMainDisplayID()) -> Float {
        guard let getBrightness = self.getBrightness else { return 1.0 }
        var val: Float = 1.0
        let res = getBrightness(displayID, &val)
        return res == 0 ? max(0.0, min(1.0, val)) : 1.0
    }
    
    public func setBrightness(_ value: Float, displayID: CGDirectDisplayID = CGMainDisplayID()) -> Bool {
        guard let setBrightness = self.setBrightness else { return false }
        let clamped = max(0.0, min(1.0, value))
        let res = setBrightness(displayID, clamped)
        return res == 0
    }
}
