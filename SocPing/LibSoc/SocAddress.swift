//
//  SocAddress.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//  Changed by Hirose Manabu on 2021/02/12. (version 1.1)
//

import Foundation
import Darwin

struct SocAddress {
    let family: Int32  // AF_INET, or AF_UNIX
    var addr: String   // IPv4 format String, or UNIX domain path
    var port: UInt16
    var hostName: String
    let isBroadcast: Bool  // user's set at initializer
    
    private static let classLabels = ["Class A", "Class B", "Class C", "Class D", "Class E"]
    private func classIndex() -> Int {
        guard self.isInet else {
            return 0  // Dummy
        }
        if (UInt32(inet_addr(self.addr)).bigEndian & 0xf0000000) == 0xf0000000 { return 4 }  // Class E
        if (UInt32(inet_addr(self.addr)).bigEndian & 0xe0000000) == 0xe0000000 { return 3 }  // Class D
        if (UInt32(inet_addr(self.addr)).bigEndian & 0xc0000000) == 0xc0000000 { return 2 }  // Class C
        if (UInt32(inet_addr(self.addr)).bigEndian & 0x80000000) == 0x80000000 { return 1 }  // Class B
        return 0  // Class A
    }
    
    var isInet: Bool { self.family == AF_INET }
    var isUnix: Bool { self.family == AF_UNIX }
    var isMulticast: Bool { self.isInet && self.classIndex() == 3 }
    var isAny: Bool { self.isInet && UInt32(inet_addr(self.addr)) == 0 }
    var isPrivate: Bool { self.isInet && (UInt32(inet_addr(self.addr)).bigEndian & 0xffffff00) == 0xac140a00 }
    var hasHostName: Bool { !self.hostName.isEmpty }
    var classLabel: String { SocAddress.classLabels[self.classIndex()] }
    var isValid: Bool {
        if self.isInet {
            return !self.isAny || self.port > 0
        }
        if self.isUnix {
            return !addr.isEmpty
        }
        return false
    }
    
    static func getAddressByName(name: String, port: UInt16 = 0) throws -> SocAddress {
        guard !name.isEmpty else {
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
        guard self.isInet && !self.addr.isEmpty else {
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
    
    func delete() throws {
        guard self.isUnix else {
            return
        }
        let temporaryDirURL = FileManager.default.temporaryDirectory
        let socketPathURL = temporaryDirURL.appendingPathComponent(self.addr)
        if !FileManager.default.fileExists(atPath: socketPathURL.path) {
            //tmp's file may be remoed by system -> not error
            return
        }
        do {
            try FileManager.default.removeItem(atPath: socketPathURL.path)
        }
        catch {
            throw SocError.FileDeleteError
        }
    }
}
