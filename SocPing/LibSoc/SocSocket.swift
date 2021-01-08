//
//  SocSocket.swift
//  LibSoc - Swift POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//

import Darwin
import Foundation

let IP_HDRLEN: Int = 20
let IP_HDRMAXLEN: Int = 60
let MAX_IPOPTLEN: Int = 40
let MAX_IPOPTGWS: Int = 8
let ICMP_HDRLEN = Int(ICMP_MINLEN)
let ICMP_MAXLEN = Int(IP_MAXPACKET) - (IP_HDRMAXLEN + ICMP_HDRLEN)
let UDP_HDRLEN: Int = 8
let UDP_MAXLEN = Int(IP_MAXPACKET) - (IP_HDRMAXLEN + UDP_HDRLEN)

struct SocSocket {
    let fd: Int32
    let family: Int32
    let type: Int32
    let proto: Int32
    var isClosed: Bool = false
    
    static var isActive: Bool = false
    
    // Initializes LibSoc
    static func initSoc() {
        SocSocket.isActive = true  // If ture, can create socket.
        signal(SIGPIPE, SIG_IGN)  // Prevent app aborted with SIGPIPE when sending to connection closed on remote side
        SocLogger.startLog()
#if DEBUG
        SocLogger.push("Start (pid:\(getpid())) for DEBUG vers.")
#else
        SocLogger.push("Start (pid:\(getpid()))")
#endif
    }
    
    init(family: Int32, type: Int32, proto: Int32) throws {
        guard SocSocket.isActive else {
            throw SocError.NotInitialized
        }
        
        self.family = family
        self.type = type
        self.proto = proto
        var logFamily = String(family)
        var logType = String(type)
        var logProto = String(proto)
        
        for i in 0 ..< SocLogger.protocolFamilies.count {
            if SocLogger.protocolFamilies[i] == family {
                logFamily = SocLogger.protocolFamilyNames[i]
                break
            }
        }
        for i in 0 ..< SocLogger.socketTypes.count {
            if SocLogger.socketTypes[i] == type {
                logType = SocLogger.socketTypeNames[i]
                break
            }
        }
        for i in 0 ..< SocLogger.protocols.count {
            if SocLogger.protocols[i] == proto {
                logProto = SocLogger.protocolNames[i]
                break
            }
        }
        let startDate = Date()
        self.fd = Darwin.socket(family, type, proto)
        SocLogger.setResponse(startDate)
        SocLogger.trace(funcName: "socket", argsText: "\(logFamily), \(logType), \(logProto)", retval: self.fd)
        guard self.fd != -1 else {
            throw SocError.SocketError(code: errno, function: "socket")
        }
    }
    
    func poll(events: Int32, timeout: Int32) throws -> Int32 {
        var ret: Int32 = 0
        let logEvents = SocLogger.getEventsMask(events)
        let logRevents: String
        
        var fds = [ pollfd(fd: self.fd, events: Int16(events), revents: 0) ]
        let startDate = Date()
        ret = Darwin.poll(&fds, 1, timeout)
        SocLogger.setResponse(startDate)
        logRevents = SocLogger.getEventsMask(Int32(fds[0].revents))
        SocLogger.trace(funcName: "poll", argsText: "[{fd=\(fd), events=\(logEvents), revents=\(logRevents)}], 1, \(timeout)", retval: ret)
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "poll")
        }
        return Int32(fds[0].revents)
    }
    
    func setsockopt(level: Int32, option: Int32, value: SocOptval) throws {
        let ret: Int32
        var optType = SocOptval.typeBool
        var logLevel = String(level)
        var logOption = String(option)
        
        for i in 0 ..< SocOptval.levels.count {
            if SocOptval.levels[i] == level {
                logLevel = SocOptval.levelNames[i]
                break
            }
        }
        switch level {
        case SOL_SOCKET:
            for i in 0 ..< SocOptval.solOptions.count {
                if SocOptval.solOptions[i].0 == option {
                    optType = SocOptval.solOptions[i].1
                    logOption = SocOptval.solOptions[i].2
                    break
                }
            }
        case IPPROTO_IP:
            for i in 0 ..< SocOptval.ipOptions.count {
                if SocOptval.ipOptions[i].0 == option {
                    optType = SocOptval.ipOptions[i].1
                    logOption = SocOptval.ipOptions[i].2
                    break
                }
            }
        default:
            break
        }
        
        switch optType {
        case SocOptval.typeBool:
            var int32Value = value.boolValue ? 1 : 0
            let length = socklen_t(MemoryLayout<Int32>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &int32Value, length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(int32Value)], \(length)", retval: ret)
        
        case SocOptval.typeBool8:
            var uint8Value = value.boolValue ? 1 : 0
            let length = socklen_t(MemoryLayout<UInt8>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &uint8Value, length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(uint8Value)], \(length)", retval: ret)
        
        case SocOptval.typeInt:
            var int32Value = Int32(value.intValue)
            let length = socklen_t(MemoryLayout<Int32>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &int32Value, length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(int32Value)], \(length)", retval: ret)
        
        case SocOptval.typeInt8:
            var uint8Value = UInt8(value.intValue)
            let length = socklen_t(MemoryLayout<UInt8>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &uint8Value, length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(uint8Value)], \(length)", retval: ret)
        
        case SocOptval.typeInAddr:
            var inAddrValue = in_addr()
            guard inet_aton(value.addrValue, &inAddrValue) != 0 else {
                throw SocError.InvalidAddress(addr: value.addrValue)
            }
            let length = socklen_t(MemoryLayout<in_addr>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &inAddrValue, length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), \"\(value.addrValue)\", \(length)", retval: ret)
        
        case SocOptval.typeIpOption:
            let logBuffer: String
            let length: socklen_t
            if let data = value.dataValue {
                logBuffer = SocLogger.getHdrAscii(data: data, length: data.count)
                length = socklen_t(data.count)
                let startDate = Date()
                ret = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> Int32 in
                    let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                    return Darwin.setsockopt(fd, level, option, unsafeBufferPointer.baseAddress, length)
                }
                SocLogger.setResponse(startDate)
                SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), \(logBuffer), \(length)", retval: ret)
                SocLogger.dataDump(data: data, length: data.count)
            }
            else {
                length = socklen_t(0)
                let startDate = Date()
                ret = Darwin.setsockopt(fd, level, option, nil, length)
                SocLogger.setResponse(startDate)
                SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), nil, \(length)", retval: ret)
            }
            
        default:  // unreachable
            assertionFailure("SocSocket.setsockopt: level(\(level)) or option(\(option)) invalid")
            throw SocError.InternalError
        }
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "setsockopt")
        }
    }
        
    func sendto(data: Data, address: SocAddress) throws -> Int {
        var addr = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                               sin_family: UInt8(AF_INET),
                               sin_port: in_port_t(address.port).bigEndian,
                               sin_addr: in_addr(s_addr: inet_addr(address.addr)),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        let sinlen = socklen_t(addr.sin_len)
        let startDate = Date()
        let sent = withUnsafePointer(to: &addr) { sockaddr_in in
            sockaddr_in.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> size_t in
                    let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                    return Darwin.sendto(fd, unsafeBufferPointer.baseAddress, data.count, 0, sockaddr, sinlen)
                }
            }
        }
        SocLogger.setResponse(startDate)

        let logBuffer = SocLogger.getHdrAscii(data: data, length: sent)
        let logAddress = "{sin_family=AF_INET, sin_port=\(address.port), sin_addr=\"\(address.addr)\"}"
        SocLogger.trace(funcName: "sendto", argsText: "\(fd), \(logBuffer), \(data.count), 0, \(logAddress), \(sinlen)", retval: Int32(sent))
        SocLogger.dataDump(data: data, length: sent)
        guard sent != -1 else {
            throw SocError.SocketError(code: errno, function: "sendto")
        }
        return sent
    }
    
    func recvfrom(data: inout Data) throws -> (Int, SocAddress?) {
        var address: SocAddress? = nil
        let dataSize = data.count
        var addr = sockaddr_in()
        var sinlen = socklen_t(MemoryLayout<sockaddr_in>.size)
        var logBuffer = SocLogger.getHdrAscii(data: data, length: dataSize)
        var logAddress = "{sin_family=AF_INET, sin_port=[0], sin_addr=\"0.0.0.0\"}"
        
        let startDate = Date()
        let received = withUnsafeMutablePointer(to: &addr) { sockaddr_in in
            sockaddr_in.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                    let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                    return Darwin.recvfrom(fd, unsafeBufferPointer.baseAddress, dataSize, 0, sockaddr, &sinlen)
                }
            }
        }
        SocLogger.setResponse(startDate)
        guard received != -1 else {
            SocLogger.trace(funcName: "recvfrom", argsText: "\(fd), \(logBuffer), \(data.count), 0, \(logAddress), [\(sinlen)]", retval: Int32(received))
            // No dump
            throw SocError.SocketError(code: errno, function: "recvfrom")
        }
        if sinlen > 0 {
            address = SocAddress(family: AF_INET, addr: String.init(cString: inet_ntoa(addr.sin_addr)), port: UInt16(addr.sin_port), hostName: "")
            logAddress = "{sin_family=AF_INET, sin_port=[\(address!.port)], sin_addr=\"\(address!.addr)\"}"
        }
        else {
            logAddress = "{}"
        }
        logBuffer = SocLogger.getHdrAscii(data: data, length: received)
        SocLogger.trace(funcName: "recvfrom", argsText: "\(fd), \(logBuffer), \(data.count), 0, \(logAddress), [\(sinlen)]", retval: Int32(received))
        SocLogger.dataDump(data: data, length: received)
        return (received, address)
    }
    
    func recvmsg(datas: inout [Data], control: inout Data) throws -> (Int, SocAddress?, Int, Int32) {
        var address: SocAddress? = nil
        var addr = sockaddr_in()
        var sinlen = socklen_t(MemoryLayout<sockaddr_in>.size)
        let iovlen = Int32(datas.count)
        var controlLen = control.count
        var flags: Int32 = 0
        
        if iovlen == 0 {
            return (0, nil, 0, flags)
        }
        else if iovlen > 1 {
            throw SocError.InvalidParameter
        }
        var logBuffer = "[" + SocLogger.getHdrAscii(data: datas[0], length: datas[0].count) + "]"
        var logControl = SocLogger.getHdrAscii(data: control, length: controlLen)
        var logAddress = "{sin_family=AF_INET, sin_port=[0], sin_addr=\"0.0.0.0\"}"
        var logMsg = ""
        
        var vec = datas[0].withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> iovec in
            return iovec(iov_base: pointer.baseAddress, iov_len: pointer.count)
        }
        let startDate = Date()
        let received = withUnsafeMutablePointer(to: &vec) { vecPtr in
            withUnsafeMutablePointer(to: &addr) { sockaddr_in in
                sockaddr_in.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                    control.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                        let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                        var messageHeader = msghdr(msg_name: sockaddr,
                                                   msg_namelen: sinlen,
                                                   msg_iov: vecPtr,
                                                   msg_iovlen: iovlen,
                                                   msg_control: unsafeBufferPointer.baseAddress,
                                                   msg_controllen: socklen_t(controlLen),
                                                   msg_flags: flags)
                        defer {
                            sinlen = messageHeader.msg_namelen
                            controlLen = Int(messageHeader.msg_controllen)
                            flags = messageHeader.msg_flags
                        }
                        let ret = withUnsafeMutablePointer(to: &messageHeader) { messageHeader in
                            return Darwin.recvmsg(fd, messageHeader, 0)
                        }
                        return ret
                    }
                }
            }
        }
        SocLogger.setResponse(startDate)
        guard received != -1 else {
            logMsg = "{msg_name=\(logAddress), msg_namelen=[\(sinlen)], msg_iov=\(logBuffer), msg_iovlen=\(iovlen), msg_control=\(logControl), msg_controllen=[\(controlLen)], msg_flags=[\(flags)]}"
            SocLogger.trace(funcName: "recvmsg", argsText: "\(fd), \(logMsg), 0", retval: Int32(received))
            // No dump
            throw SocError.SocketError(code: errno, function: "recvmsg")
        }
        if sinlen > 0 {
            address = SocAddress(family: AF_INET, addr: String.init(cString: inet_ntoa(addr.sin_addr)), port: UInt16(addr.sin_port), hostName: "")
            logAddress = "{sin_family=AF_INET, sin_port=[\(address!.port)], sin_addr=\"\(address!.addr)\"}"
        }
        else {
            logAddress = "{}"
        }
        
        logBuffer = "[" + SocLogger.getHdrAscii(data: datas[0], length: received) + "]"
        logControl = SocLogger.getHdrAscii(data: control, length: Int(controlLen))
        logMsg = "{msg_name=\(logAddress), msg_namelen=[\(sinlen)], msg_iov=\(logBuffer), msg_iovlen=\(iovlen), msg_control=\(logControl), msg_controllen=[\(controlLen)], msg_flags=[\(flags)]}"
        SocLogger.trace(funcName: "recvmsg", argsText: "\(fd), \(logMsg), 0", retval: Int32(received))
        SocLogger.dataDump(data: datas[0], length: received, label: "msg_iov[0]:")
        SocLogger.dataDump(data: control, length: controlLen, label: "msg_control:")
        return (received, address, controlLen, flags)
    }
    
    mutating func close() throws {
        let startDate = Date()
        let ret = Darwin.close(fd)
        SocLogger.setResponse(startDate)
        SocLogger.trace(funcName: "close", argsText: "\(fd)", retval: Int32(ret))
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "close")
        }
        self.isClosed = true
    }
}
