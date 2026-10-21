import Foundation
import Darwin

public final class NetworkService: @unchecked Sendable {
    public static let shared = NetworkService()
    
    private var lastBytesIn: UInt64 = 0
    private var lastBytesOut: UInt64 = 0
    private var lastCheckTime: CFAbsoluteTime = 0
    
    private var cachedGateway: String = ""
    private var cachedDNS: [String] = []
    private var cachedMAC: String = ""
    private var cachedInterface: String = "en0"
    
    private init() {
        let (bytesIn, bytesOut) = queryTotalNetworkBytes()
        lastBytesIn = bytesIn
        lastBytesOut = bytesOut
        lastCheckTime = CFAbsoluteTimeGetCurrent()
        refreshNetworkConfig()
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
        
        let (localIP, ifName) = getLocalIPAddressAndInterface()
        if !ifName.isEmpty {
            cachedInterface = ifName
        }
        
        return NetworkStats(
            downloadSpeedKBps: downloadSpeedKBps,
            uploadSpeedKBps: uploadSpeedKBps,
            localIP: localIP,
            activeInterface: cachedInterface,
            gatewayIP: cachedGateway.isEmpty ? "192.168.1.1" : cachedGateway,
            dnsServers: cachedDNS.isEmpty ? ["192.168.1.1"] : cachedDNS,
            macAddress: cachedMAC.isEmpty ? "Detectando..." : cachedMAC
        )
    }
    
    public func refreshNetworkConfig() {
        DispatchQueue.global(qos: .utility).async {
            // Gateway
            let pRoute = Process()
            pRoute.executableURL = URL(fileURLWithPath: "/sbin/route")
            pRoute.arguments = ["-n", "get", "default"]
            let pipeRoute = Pipe()
            pRoute.standardOutput = pipeRoute
            try? pRoute.run()
            pRoute.waitUntilExit()
            let routeOut = String(data: pipeRoute.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            for line in routeOut.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("gateway:") {
                    self.cachedGateway = trimmed.replacingOccurrences(of: "gateway:", with: "").trimmingCharacters(in: .whitespaces)
                } else if trimmed.hasPrefix("interface:") {
                    self.cachedInterface = trimmed.replacingOccurrences(of: "interface:", with: "").trimmingCharacters(in: .whitespaces)
                }
            }
            
            // DNS
            let pDNS = Process()
            pDNS.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
            pDNS.arguments = ["--dns"]
            let pipeDNS = Pipe()
            pDNS.standardOutput = pipeDNS
            try? pDNS.run()
            pDNS.waitUntilExit()
            let dnsOut = String(data: pipeDNS.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            var servers: [String] = []
            for line in dnsOut.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("nameserver[") {
                    if let colonIdx = trimmed.firstIndex(of: ":") {
                        let ip = trimmed[trimmed.index(after: colonIdx)...].trimmingCharacters(in: .whitespaces)
                        if !servers.contains(ip) && !ip.contains("fe80") {
                            servers.append(ip)
                        }
                    }
                }
            }
            if !servers.isEmpty {
                self.cachedDNS = servers
            }
            
            // MAC
            let pIf = Process()
            pIf.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
            pIf.arguments = [self.cachedInterface]
            let pipeIf = Pipe()
            pIf.standardOutput = pipeIf
            try? pIf.run()
            pIf.waitUntilExit()
            let ifOut = String(data: pipeIf.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            for line in ifOut.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("ether ") {
                    self.cachedMAC = trimmed.replacingOccurrences(of: "ether ", with: "").trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }
    }
    
    public func measurePing(host: String = "1.1.1.1") async -> Double {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/sbin/ping")
                proc.arguments = ["-c", "2", "-W", "1000", host]
                let pipe = Pipe()
                proc.standardOutput = pipe
                try? proc.run()
                proc.waitUntilExit()
                
                let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                // Parse round-trip min/avg/max/stddev = 28.057/32.495/36.933/4.438 ms
                if let range = output.range(of: "round-trip min/avg/max/stddev = ") {
                    let sub = output[range.upperBound...]
                    let parts = sub.components(separatedBy: "/")
                    if parts.count >= 2, let avg = Double(parts[1]) {
                        continuation.resume(returning: avg)
                        return
                    }
                }
                continuation.resume(returning: -1.0)
            }
        }
    }
    
    public func flushDNSCache() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let p1 = Process()
                p1.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
                p1.arguments = ["-flushcache"]
                try? p1.run()
                p1.waitUntilExit()
                
                let p2 = Process()
                p2.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
                p2.arguments = ["-HUP", "mDNSResponder"]
                try? p2.run()
                p2.waitUntilExit()
                
                continuation.resume(returning: true)
            }
        }
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
    
    private func getLocalIPAddressAndInterface() -> (String, String) {
        var address = "127.0.0.1"
        var interface = "en0"
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
                            let foundIP = hostname.withUnsafeBufferPointer { p in
                                p.baseAddress != nil ? String(cString: p.baseAddress!) : "127.0.0.1"
                            }
                            if foundIP != "127.0.0.1" {
                                address = foundIP
                                interface = String(cString: ptr!.pointee.ifa_name)
                                break
                            }
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return (address, interface)
    }
}
