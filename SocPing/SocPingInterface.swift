//
//  SocPingInterface.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import Foundation

struct SocPingInterface {
    let deviceType: Int
    var flags: UInt32 = 0
    var ether: String = ""
    var inet = SocAddress(family: AF_INET, addr: "")
    var netmask = SocAddress(family: AF_INET, addr: "")
    var broadcast = SocAddress(family: AF_INET, addr: "", isBroadcast: true)
    var isExist: Bool = false
    
    var name: String { return SocPingInterface.deviceNames[self.deviceType] }
    var index: Int { return Int(if_nametoindex(self.name)) }
    var isActive: Bool { return !self.inet.addr.isEmpty }
    var hasEther: Bool { return !self.ether.isEmpty }
    var hasNetmask: Bool { return !self.netmask.addr.isEmpty }
    var hasBroadcast: Bool { return !self.broadcast.addr.isEmpty }
    
    static let deviceTypeWifi: Int = 0
    static let deviceTypeCellurar: Int = 1
    static let deviceTypeHotspot: Int = 2
    static let deviceTypeLoopback: Int = 3  // SocAddress for broadcast is not use
    static let deviceNames: [String] = ["en0", "pdp_ip0", "bridge100", "lo0"]  // Note: I'm not sure that the name is always bridge100.
    
    init(deviceType: Int) {
        self.deviceType = deviceType
    }
    
    mutating func ifconfig(isLaunching: Bool = false) {
        // reset parameters
        self.flags = 0
        self.ether = ""
        self.inet.addr = ""
        self.inet.hostName = ""
        self.netmask.addr = ""
        self.broadcast.addr = ""
        self.isExist = false
        
        var ifaList: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaList) == 0 else {
            return
        }
        defer {
            freeifaddrs(ifaList)
        }
        
        // Get Mac address
        var ifaPtr = ifaList
        while ifaPtr != nil {
            guard let ifa = ifaPtr?.pointee else {
                SocLogger.error("SocPingInterface.ifconfig: null pointer")
                return
            }
            guard let ifaName = String(validatingUTF8: ifa.ifa_name) else {
                SocLogger.error("SocPingInterface.ifconfig: no name")
                return
            }
            if ifaName == self.name && ifa.ifa_addr.pointee.sa_family == Int(AF_LINK) {
                self.isExist = true
                ifa.ifa_addr.withMemoryRebound(to: sockaddr_dl.self, capacity: 1) { sdl in
                    sdl.withMemoryRebound(to: Int8.self, capacity: 8 + Int(sdl.pointee.sdl_nlen + sdl.pointee.sdl_alen)) {
                        let etherAddr = UnsafeBufferPointer(start: $0 + 8 + Int(sdl.pointee.sdl_nlen), count: Int(sdl.pointee.sdl_alen))
                        self.ether = etherAddr.map { String(format:"%02hhx", $0)}.joined(separator: ":")
                    }
                }
                break
            }
            ifaPtr = ifa.ifa_next
        }
        if !self.isExist {
            return
        }
        
        // Get IP address
        ifaPtr = ifaList
        while ifaPtr != nil {
            guard let ifa = ifaPtr?.pointee else {
                SocLogger.error("SocPingInterface.ifconfig: null pointer")
                return
            }
            guard let ifaName = String(validatingUTF8: ifa.ifa_name) else {
                SocLogger.error("SocPingInterface.ifconfig: no name")
                return
            }
            if ifaName == self.name && ifa.ifa_addr.pointee.sa_family == Int(AF_INET) {
                self.flags = ifa.ifa_flags
                if let addr = ifa.ifa_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1, { sin -> String? in
                    return String.init(cString: inet_ntoa(sin.pointee.sin_addr))
                }) {
                    self.inet.addr = addr
                }
                if let netmask = ifa.ifa_netmask.withMemoryRebound(to: sockaddr_in.self, capacity: 1, { sin -> String? in
                    return String.init(cString: inet_ntoa(sin.pointee.sin_addr))
                }) {
                    self.netmask.addr = netmask
                }
                if ifa.ifa_flags & UInt32(IFF_BROADCAST) == UInt32(IFF_BROADCAST) {
                    if let broadcast = ifa.ifa_dstaddr.withMemoryRebound(to: sockaddr_in.self, capacity: 1, { sin -> String? in
                        return String.init(cString: inet_ntoa(sin.pointee.sin_addr))
                    }) {
                        self.broadcast.addr = broadcast
                    }
                }
                break
            }
            ifaPtr = ifa.ifa_next
        }
        
        if self.isActive {
            if self.deviceType == SocPingInterface.deviceTypeLoopback {
                self.inet.hostName = "localhost"
            }
            else if !isLaunching {
                try! self.inet.resolveHostName()
            }
        }
    }
}
