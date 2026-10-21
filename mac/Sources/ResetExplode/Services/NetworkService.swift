import Foundation
import Darwin

public final class NetworkService: @unchecked Sendable {
    public static let shared = NetworkService()
    
    private var lastBytesIn: UInt64 = 0
    private var lastBytesOut: UInt64 = 0
    private var lastCheckTime: CFAbsoluteTime = 0
    
    private init() {
        let (bytesIn, bytesOut) = queryTotalNetworkBytes()
        lastBytesIn = bytesIn
        lastBytesOut = bytesOut
        lastCheckTime = CFAbsoluteTimeGetCurrent()
    }
    
    public func getCurrentStats() -> NetworkStats {
        let now = CFAbsoluteTimeGetCurrent()
        let elapsed = max(0.2, now - lastCheckTime)
        
        let (bytesIn, bytesOut) = queryTotalNetworkBytes()
        
        let diffIn = bytesIn >= lastBytesIn ? (bytesIn - lastBytesIn) : 0
        let diffOut = bytesOut >= lastBytesOut ? (bytesOut - lastBytesOut) : 0
        
        lastBytesIn = bytesIn
        lastBytesOut = bytesOut
        lastCheckTime = now
        
        let downloadSpeedKBps = (Double(diffIn) / 1024.0) / elapsed
        let uploadSpeedKBps = (Double(diffOut) / 1024.0) / elapsed
        
        let localIP = getLocalIPAddress()
        
        return NetworkStats(
            downloadSpeedKBps: downloadSpeedKBps,
            uploadSpeedKBps: uploadSpeedKBps,
            localIP: localIP,
            activeInterface: "Wi-Fi / Ethernet"
        )
    }
    
    private func queryTotalNetworkBytes() -> (UInt64, UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let flags = Int32(ptr!.pointee.ifa_flags)
                let addr = ptr!.pointee.ifa_addr.pointee
                if (flags & (IFF_UP | IFF_RUNNING)) != 0 && (flags & IFF_LOOPBACK) == 0 {
                    if addr.sa_family == UInt8(AF_LINK) {
                        if let data = ptr!.pointee.ifa_data {
                            let networkData = data.assumingMemoryBound(to: if_data.self)
                            totalIn += UInt64(networkData.pointee.ifi_ibytes)
                            totalOut += UInt64(networkData.pointee.ifi_obytes)
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        
        return (totalIn, totalOut)
    }
    
    private func getLocalIPAddress() -> String {
        var address = "127.0.0.1"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let flags = Int32(ptr!.pointee.ifa_flags)
                let addr = ptr!.pointee.ifa_addr.pointee
                if (flags & (IFF_UP | IFF_RUNNING)) != 0 && (flags & IFF_LOOPBACK) == 0 {
                    if addr.sa_family == UInt8(AF_INET) {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(ptr!.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                            address = hostname.withUnsafeBufferPointer { p in
                                p.baseAddress != nil ? String(cString: p.baseAddress!) : "127.0.0.1"
                            }
                            break
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}
