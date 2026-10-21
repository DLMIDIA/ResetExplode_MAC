import Foundation
import AppKit
import IOKit

public final class ConnectedDevicesService: @unchecked Sendable {
    public static let shared = ConnectedDevicesService()
    
    private var cachedBluetooth: [ConnectedBluetoothDevice] = []
    private let btLock = NSLock()
    private var lastBtFetch: CFAbsoluteTime = 0
    
    private init() {
        // Inicializa com busca em background para não travar a inicialização
        refreshBluetoothDevicesAsync()
    }
    
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
        btLock.lock()
        defer { btLock.unlock() }
        
        // Se já passou mais de 15 segundos desde a última busca, atualiza em background
        if CFAbsoluteTimeGetCurrent() - lastBtFetch > 15.0 {
            refreshBluetoothDevicesAsync()
        }
        
        return cachedBluetooth
    }
    
    public func refreshBluetoothDevicesAsync(completion: (@Sendable ([ConnectedBluetoothDevice]) -> Void)? = nil) {
        DispatchQueue.global(qos: .utility).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
            proc.arguments = ["SPBluetoothDataType", "-json"]
            let pipe = Pipe()
            proc.standardOutput = pipe
            try? proc.run()
            proc.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            var result: [ConnectedBluetoothDevice] = []
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let list = json["SPBluetoothDataType"] as? [[String: Any]] {
                for item in list {
                    // Dispositivos Conectados Ativamente
                    if let conn = item["device_connected"] as? [[String: Any]] {
                        for d in conn {
                            for (name, val) in d {
                                var addr = ""
                                if let info = val as? [String: Any] {
                                    addr = (info["device_address"] as? String) ?? ""
                                }
                                result.append(ConnectedBluetoothDevice(name: name, address: addr, isConnected: true))
                            }
                        }
                    }
                    // Dispositivos Pareados (Não Conectados no momento)
                    if let notConn = item["device_not_connected"] as? [[String: Any]] {
                        for d in notConn {
                            for (name, val) in d {
                                var addr = ""
                                if let info = val as? [String: Any] {
                                    addr = (info["device_address"] as? String) ?? ""
                                }
                                result.append(ConnectedBluetoothDevice(name: name, address: addr, isConnected: false))
                            }
                        }
                    }
                }
            }
            
            self.btLock.lock()
            if !result.isEmpty {
                self.cachedBluetooth = result
            }
            self.lastBtFetch = CFAbsoluteTimeGetCurrent()
            let copy = self.cachedBluetooth
            self.btLock.unlock()
            
            completion?(copy)
        }
    }
    
    public func getSummary() -> ConnectedDevicesSummary {
        return ConnectedDevicesSummary(
            displays: getConnectedDisplays(),
            usbDevices: getConnectedUSBDevices(),
            bluetoothDevices: getBluetoothDevices()
        )
    }
}
