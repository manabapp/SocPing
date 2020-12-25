//
//  SocAddress.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//

import Darwin

struct SocAddress {
    let family: Int32  // AF_INET
    var addr: String   // IPv4 format String
    var port: UInt16
    var hostName: String
    let isBroadcast: Bool  // user's set at initializer
    
    var isMulticast: Bool { return self.classIndex() == 3 }
    var isAny: Bool { return self.family == AF_INET && UInt32(inet_addr(self.addr)) == 0 }
    var isPrivate: Bool { return (UInt32(inet_addr(self.addr)).bigEndian & 0xffffff00) == 0xac140a00 }
    var hasHostName: Bool { return !self.hostName.isEmpty }
    var classLabel: String { return SocAddress.classLabels[self.classIndex()] }
    
    private static let classLabels = ["Class A", "Class B", "Class C", "Class D", "Class E"]
    private func classIndex() -> Int {
        if (UInt32(inet_addr(self.addr)).bigEndian & 0xf0000000) == 0xf0000000 { return 4 }  // Class E
        if (UInt32(inet_addr(self.addr)).bigEndian & 0xe0000000) == 0xe0000000 { return 3 }  // Class D
        if (UInt32(inet_addr(self.addr)).bigEndian & 0xc0000000) == 0xc0000000 { return 2 }  // Class C
        if (UInt32(inet_addr(self.addr)).bigEndian & 0x80000000) == 0x80000000 { return 1 }  // Class B
        return 0  // Class A
    }
    
    static func getAddressByName(name: String, port: UInt16 = 0) throws -> SocAddress {
        if name.isEmpty {
            throw SocError.InvalidParameter
        }
        guard let host = name.withCString({ gethostbyname($0) }) else {
            throw SocError.ResolveError(code: h_errno)
        }
        guard host.pointee.h_length > 0 else {
            assertionFailure("SocAddress.getAddressByName: gethostbyname('\(name)') h_length = \(host.pointee.h_length)")
            throw SocError.InternalError
        }
        var inAddr = in_addr()
        memcpy(&inAddr.s_addr, host.pointee.h_addr_list[0], Int(host.pointee.h_length))
        guard let addressCString = inet_ntoa(inAddr) else {
            assertionFailure("SocAddress.getAddressByName: inet_ntoa(\(inAddr)) failed")
            throw SocError.InternalError
        }
        return SocAddress(family: AF_INET, addr: String.init(cString: addressCString), port: port, hostName: name)
    }
    
    init(family: Int32, addr: String, port: UInt16 = 0, hostName: String = "", isBroadcast: Bool = false) {
        self.family = family
        self.addr = addr
        self.port = port
        self.hostName = hostName
        self.isBroadcast = isBroadcast
    }
    
    mutating func resolveHostName() throws {
        if self.family != AF_INET || self.addr.isEmpty {
            throw SocError.InvalidParameter
        }
        var inAddr = in_addr()
        guard inet_aton(addr, &inAddr) != 0 else {
            throw SocError.InvalidAddress(addr: addr)
        }
        if let he: UnsafeMutablePointer<hostent> = gethostbyaddr(&inAddr, UInt32(MemoryLayout.size(ofValue: inAddr)), AF_INET) {
            self.hostName = String.init(cString: he.pointee.h_name)
        }
        // else -> Unkown host
    }
}
