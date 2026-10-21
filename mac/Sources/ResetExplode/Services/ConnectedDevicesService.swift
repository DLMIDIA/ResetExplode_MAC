import Foundation
import AppKit
import IOKit
import IOBluetooth

public final class ConnectedDevicesService: @unchecked Sendable {
    public static let shared = ConnectedDevicesService()
    
    private init() {}
    
    public func getConnectedDisplays() -> [ConnectedDisplay] {
        var displays: [ConnectedDisplay] = []
        
        for screen in NSScreen.screens {
            let name = screen.localizedName
            let width = Int(screen.frame.width * screen.backingScaleFactor)
            let height = Int(screen.frame.height * screen.backingScaleFactor)
            let res = "\(width) x \(height)"
            
            var rateStr = "60 Hz"
            if let mode = CGDisplayCopyDisplayMode(CGMainDisplayID()) {
                let refresh = mode.refreshRate
                if refresh > 0 {
                    rateStr = String(format: "%.0f Hz", refresh)
                }
            }
            
            let isMain = screen == NSScreen.main
            let isBuiltIn = name.lowercased().contains("built-in") || name.lowercased().contains("retina") || name.lowercased().contains("color lcd")
            
            displays.append(ConnectedDisplay(
                name: name,
                resolution: res,
                refreshRate: rateStr,
                isMain: isMain,
                isBuiltIn: isBuiltIn
            ))
        }
        
        return displays
    }
    
    public func getConnectedUSBDevices() -> [ConnectedUSBDevice] {
        var devices: [ConnectedUSBDevice] = []
        var seenNames = Set<String>()
        
        var iterator: io_iterator_t = 0
        let match = IOServiceMatching("IOUSBHostDevice")
        if IOServiceGetMatchingServices(kIOMainPortDefault, match, &iterator) == KERN_SUCCESS {
            var dev = IOIteratorNext(iterator)
            while dev != 0 {
                var props: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(dev, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let d = props?.takeRetainedValue() as? [String: Any] {
                    let name = (d["USB Product Name"] as? String) ?? (d["kUSBProductString"] as? String) ?? ""
                    let vendor = (d["USB Vendor Name"] as? String) ?? (d["kUSBVendorString"] as? String) ?? "Dispositivo USB"
                    
                    if !name.isEmpty && !seenNames.contains(name) {
                        seenNames.insert(name)
                        devices.append(ConnectedUSBDevice(
                            name: name,
                            vendor: vendor
                        ))
                    }
                }
                IOObjectRelease(dev)
                dev = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        
        return devices
    }
    
    public func getBluetoothDevices() -> [ConnectedBluetoothDevice] {
        var devices: [ConnectedBluetoothDevice] = []
        
        if let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            for dev in paired {
                let name = dev.nameOrAddress ?? "Dispositivo Bluetooth"
                let address = dev.addressString ?? ""
                let isConnected = dev.isConnected()
                
                devices.append(ConnectedBluetoothDevice(
                    name: name,
                    address: address,
                    isConnected: isConnected
                ))
            }
        }
        
        return devices
    }
    
    public func getSummary() -> ConnectedDevicesSummary {
        return ConnectedDevicesSummary(
            displays: getConnectedDisplays(),
            usbDevices: getConnectedUSBDevices(),
            bluetoothDevices: getBluetoothDevices()
        )
    }
}
