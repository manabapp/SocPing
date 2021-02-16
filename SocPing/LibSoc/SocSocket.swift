//
//  SocSocket.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//  Changed by Hirose Manabu on 2021/02/12. (version 1.1)
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
    let openDate: Date
    var localAddress: SocAddress? = nil
    var remoteAddress: SocAddress? = nil
    var connErrno: Int32 = 0  // error in non-blocking connect
    var connInfo: tcp_connection_info = tcp_connection_info()
    var revents: Int32 = 0
    
#if DEBUG
    var isActive: Bool = false
#endif
    var isClosed: Bool = false
    var isServer: Bool = false  // listening socket and accepted socket
    var isListening: Bool = false
    var isNonBlocking: Bool = false
    var isConnecting: Bool = false
    var isConnected: Bool = false
    var isRdShutdown: Bool = false
    var isWrShutdown: Bool = false
    var isInet: Bool { return self.family == PF_INET }
    var isUnix: Bool { return self.family == PF_UNIX }
    var isStream: Bool { return self.type == SOCK_STREAM }
    var isDgram: Bool { return self.type == SOCK_DGRAM }
    var isTcp: Bool { return self.isInet && self.isStream && (self.proto == 0 || self.proto == IPPROTO_TCP) }
    var isUdp: Bool { return self.isInet && self.isDgram && (self.proto == 0 || self.proto == IPPROTO_UDP) }
    var isIcmp: Bool { return self.isInet && self.isDgram && self.proto == IPPROTO_ICMP }
    static var isInitialized: Bool = false  // Initializes LibSoc
    
    static func initSoc() {
        Self.isInitialized = true  // If ture, can create socket.
        signal(SIGPIPE, SIG_IGN)   // Prevent app aborted with SIGPIPE when sending to connection closed on remote side
        SocLogger.startLog()
#if DEBUG
        SocLogger.push("Start (pid:\(getpid())) for DEBUG vers.")
#else
        SocLogger.push("Start (pid:\(getpid()))")
#endif
    }
    
    init(fd: Int32, family: Int32, type: Int32, proto: Int32) {
        self.fd = fd
        self.family = family
        self.type = type
        self.proto = proto
        self.openDate = Date()
    }
    
    init(family: Int32, type: Int32, proto: Int32) throws {
        guard Self.isInitialized else {
            throw SocError.NotInitialized
        }
        var logFamily = String(family)
        for i in 0 ..< SocLogger.protocolFamilies.count {
            if SocLogger.protocolFamilies[i] == family {
                logFamily = SocLogger.protocolFamilyNames[i]
                break
            }
        }
        var logType = String(type)
        for i in 0 ..< SocLogger.socketTypes.count {
            if SocLogger.socketTypes[i] == type {
                logType = SocLogger.socketTypeNames[i]
                break
            }
        }
        var logProto = String(proto)
        for i in 0 ..< SocLogger.protocols.count {
            if SocLogger.protocols[i] == proto {
                logProto = SocLogger.protocolNames[i]
                break
            }
        }
        
        let startDate = Date()
        let fd = Darwin.socket(family, type, proto)
        SocLogger.setResponse(startDate)
        SocLogger.trace(funcName: "socket", argsText: "\(logFamily), \(logType), \(logProto)", retval: fd)
        guard fd != -1 else {
            throw SocError.SocketError(code: errno, function: "socket")
        }
        self.init(fd: fd, family: family, type: type, proto: proto)
    }
    
    func getsockopt(level: Int32, option: Int32) throws -> SocOptval {
        let logLevel = SocOptval.getLevelName(level: level)
        let logOption = SocOptval.getOptionName(level: level, option: option)
        
        guard let optType = SocOptval.getOptionType(level: level, option: option) else {
            throw SocError.InvalidParameter
        }
        
        let ret: Int32
        var value = SocOptval()
        switch optType {
        case SocOptval.typeBool:
            var int32Value: Int32 = 0
            var length = socklen_t(MemoryLayout<Int32>.size)
            let startDate = Date()
            ret = Darwin.getsockopt(fd, level, option, &int32Value, &length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "getsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(int32Value)], [\(length)]", retval: ret)
            value.bool = Bool(int32Value != 0)
        
        case SocOptval.typeBool8:
            var uint8Value: UInt8 = 0
            var length = socklen_t(MemoryLayout<UInt8>.size)
            let startDate = Date()
            ret = Darwin.getsockopt(fd, level, option, &uint8Value, &length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "getsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(uint8Value)], [\(length)]", retval: ret)
            value.bool = Bool(uint8Value != 0)
        
        case SocOptval.typeNWService:
            fallthrough
        case SocOptval.typePortRange:
            fallthrough
        case SocOptval.typeInt:
            var int32Value: Int32 = 0
            var length = socklen_t(MemoryLayout<Int32>.size)
            let startDate = Date()
            ret = Darwin.getsockopt(fd, level, option, &int32Value, &length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "getsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(int32Value)], [\(length)]", retval: ret)
            value.int = Int(int32Value)
            value.text = String(value.int)
        
        case SocOptval.typeInt8:
            var uint8Value: UInt8 = 0
            var length = socklen_t(MemoryLayout<UInt8>.size)
            let startDate = Date()
            ret = Darwin.getsockopt(fd, level, option, &uint8Value, &length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "getsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(uint8Value)], [\(length)]", retval: ret)
            value.int = Int(uint8Value)
            value.text = String(value.int)
        
        case SocOptval.typeUsec:
            var tvValue = timeval()
            var length = socklen_t(MemoryLayout<timeval>.size)
            let startDate = Date()
            ret = Darwin.getsockopt(fd, level, option, &tvValue, &length)
            SocLogger.setResponse(startDate)
            let logTv = "{tv_sec=\(tvValue.tv_sec), tv_usec=\(tvValue.tv_usec)}"
            SocLogger.trace(funcName: "getsockopt", argsText: "\(fd), \(logLevel), \(logOption), \(logTv), [\(length)]", retval: ret)
            value.double = Double(tvValue.tv_sec) + Double(tvValue.tv_usec) * 0.000001
            value.text = String(value.double)
            
        case SocOptval.typeLinger:
            var lingerValue = linger()
            var length = socklen_t(MemoryLayout<linger>.size)
            let startDate = Date()
            ret = Darwin.getsockopt(fd, level, option, &lingerValue, &length)
            SocLogger.setResponse(startDate)
            let logLinger = "{l_onoff=\(lingerValue.l_onoff), l_linger=\(lingerValue.l_linger)}"
            SocLogger.trace(funcName: "getsockopt", argsText: "\(fd), \(logLevel), \(logOption), \(logLinger), [\(length)]", retval: ret)
            value.bool = Bool(lingerValue.l_onoff != 0)
            value.int = Int(lingerValue.l_linger)
            value.text = String(value.int)
        
        case SocOptval.typeInAddr:
            var inAddrValue = in_addr()
            var length = socklen_t(MemoryLayout<in_addr>.size)
            let startDate = Date()
            ret = Darwin.getsockopt(fd, level, option, &inAddrValue, &length)
            SocLogger.setResponse(startDate)
            let addr = String.init(cString: inet_ntoa(inAddrValue))
            SocLogger.trace(funcName: "getsockopt", argsText: "\(fd), \(logLevel), \(logOption), \"\(addr)\", [\(length)]", retval: ret)
            value.addr = addr
        
        case SocOptval.typeTcpConnInfo:
            var connInfoValue = tcp_connection_info()
            var length = socklen_t(MemoryLayout<tcp_connection_info>.size)
            let startDate = Date()
            ret = Darwin.getsockopt(fd, level, option, &connInfoValue, &length)
            SocLogger.setResponse(startDate)
            var logConnInfo = "{tcpi_state=\(connInfoValue.tcpi_state), ...}"
            if connInfoValue.tcpi_state < SocLogger.tcpStateNames.count {
                logConnInfo = "{tcpi_state=\(SocLogger.tcpStateNames[Int(connInfoValue.tcpi_state)]), ...}"
            }
            SocLogger.trace(funcName: "getsockopt", argsText: "\(fd), \(logLevel), \(logOption), \(logConnInfo), [\(length)]", retval: ret)
            value.connInfo = connInfoValue
            
        case SocOptval.typeIpOptions:
            var dataValue = Data([UInt8](repeating: 0, count: 64))
            var length = socklen_t(dataValue.count)
            let startDate = Date()
            ret = dataValue.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> Int32 in
                let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                return Darwin.getsockopt(fd, level, option, unsafeBufferPointer.baseAddress, &length)
            }
            SocLogger.setResponse(startDate)
            let logBuffer = SocLogger.getHdrAscii(data: dataValue, length: Int(length))
            SocLogger.trace(funcName: "getsockopt", argsText: "\(fd), \(logLevel), \(logOption), \(logBuffer), [\(length)]", retval: ret)
            SocLogger.dataDump(data: dataValue, length: Int(length))
            if length > 0 {
                value.data = Data(dataValue[0 ..< length])
                value.text = value.data!.dump
            }
            
        default:
            throw SocError.InvalidParameter
        }
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "getsockopt")
        }
        return value
    }
    
    func setsockopt(level: Int32, option: Int32, value: SocOptval) throws {
        let logLevel = SocOptval.getLevelName(level: level)
        let logOption = SocOptval.getOptionName(level: level, option: option)
        
        guard let optType = SocOptval.getOptionType(level: level, option: option) else {
            throw SocError.InvalidParameter
        }
        let ret: Int32
        switch optType {
        case SocOptval.typeBool:
            var int32Value: Int32 = value.bool ? 1 : 0
            let length = socklen_t(MemoryLayout<Int32>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &int32Value, length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(int32Value)], \(length)", retval: ret)
        
        case SocOptval.typeBool8:
            var uint8Value: UInt8 = value.bool ? 1 : 0
            let length = socklen_t(MemoryLayout<UInt8>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &uint8Value, length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(uint8Value)], \(length)", retval: ret)
        
        case SocOptval.typeNWService:
            fallthrough
        case SocOptval.typePortRange:
            fallthrough
        case SocOptval.typeInt:
            var int32Value = Int32(value.int)
            let length = socklen_t(MemoryLayout<Int32>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &int32Value, length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(int32Value)], \(length)", retval: ret)
        
        case SocOptval.typeInt8:
            var uint8Value = UInt8(value.int)
            let length = socklen_t(MemoryLayout<UInt8>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &uint8Value, length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), [\(uint8Value)], \(length)", retval: ret)
        
        case SocOptval.typeUsec:
            var tvValue = timeval()
            tvValue.tv_sec = time_t(value.double)
            tvValue.tv_usec = suseconds_t(value.double * 1000000.0) % 1000000
            let length = socklen_t(MemoryLayout<timeval>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &tvValue, length)
            SocLogger.setResponse(startDate)
            let logTv = "{tv_sec=\(tvValue.tv_sec), tv_usec=\(tvValue.tv_usec)}"
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), \(logTv), \(length)", retval: ret)
        
        case SocOptval.typeLinger:
            var lingerValue = linger()
            lingerValue.l_onoff = value.bool ? 1 : 0
            lingerValue.l_linger = Int32(value.int)
            let length = socklen_t(MemoryLayout<linger>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &lingerValue, length)
            SocLogger.setResponse(startDate)
            let logLinger = "{l_onoff=\(lingerValue.l_onoff), l_linger=\(lingerValue.l_linger)}"
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), \(logLinger), \(length)", retval: ret)
            
        case SocOptval.typeInAddr:
            var inAddrValue = in_addr()
            guard inet_aton(value.addr, &inAddrValue) != 0 else {
                throw SocError.InvalidAddress(addr: value.addr)
            }
            let length = socklen_t(MemoryLayout<in_addr>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &inAddrValue, length)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), \"\(value.addr)\", \(length)", retval: ret)
        
        case SocOptval.typeIpMreq:
            var ipMreqValue = ip_mreq()
            var inAddrValue = in_addr()
            guard inet_aton(value.addr, &inAddrValue) != 0 else {
                throw SocError.InvalidAddress(addr: value.addr)
            }
            ipMreqValue.imr_multiaddr = inAddrValue
            guard inet_aton(value.addr2, &inAddrValue) != 0 else {
                throw SocError.InvalidAddress(addr: value.addr2)
            }
            ipMreqValue.imr_interface = inAddrValue
            let length = socklen_t(MemoryLayout<ip_mreq>.size)
            let startDate = Date()
            ret = Darwin.setsockopt(fd, level, option, &ipMreqValue, length)
            SocLogger.setResponse(startDate)
            let logMreq = "{imr_multiaddr=\"\(String.init(cString: inet_ntoa(ipMreqValue.imr_interface)))\", imr_interface=\"\(String.init(cString: inet_ntoa(ipMreqValue.imr_interface)))\"}"
            SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), \(logMreq), \(length)", retval: ret)
        
        case SocOptval.typeIpOptions:
            let logBuffer: String
            let length: socklen_t
            if let data = value.data {
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
                SocLogger.trace(funcName: "setsockopt", argsText: "\(fd), \(logLevel), \(logOption), NULL, \(length)", retval: ret)
            }
            
        default:
            throw SocError.InvalidParameter
        }
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "setsockopt")
        }
    }
    
    func bind(address: SocAddress) throws {
        let ret: Int32
        switch address.family {
        case AF_INET:
            var sin = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                                  sin_family: UInt8(address.family),
                                  sin_port: in_port_t(address.port).bigEndian,
                                  sin_addr: in_addr(s_addr: inet_addr(address.addr)),
                                  sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
            let sinlen = socklen_t(sin.sin_len)
            let startDate = Date()
            ret = withUnsafePointer(to: &sin) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.bind(fd, $0, sinlen)
                }
            }
            SocLogger.setResponse(startDate)
            let logAddress = "{sin_family=AF_INET, sin_port=\(address.port), sin_addr=\"\(address.addr)\"}"
            SocLogger.trace(funcName: "bind", argsText: "\(fd), \(logAddress), \(sinlen)", retval: ret)
        
        case AF_UNIX:
            var sun = sockaddr_un()
            sun.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
            sun.sun_family = UInt8(address.family)
            _ = address.addr.withCString { path in
                Darwin.memcpy(&(sun.sun_path), path, Int(strlen(path)))
            }
            let sunlen = socklen_t(sun.sun_len)
            let startDate = Date()
            ret = withUnsafePointer(to: &sun) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.bind(fd, $0, sunlen)
                }
            }
            SocLogger.setResponse(startDate)
            let logAddress = "{sun_family=AF_UNIX, sun_path=\"\(address.addr)\"}"
            SocLogger.trace(funcName: "bind", argsText: "\(fd), \(logAddress), \(sunlen)", retval: ret)
        
        default:
            throw SocError.InvalidParameter
        }
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "bind")
        }
    }
    
    func connect(address: SocAddress) throws {
        let ret: Int32
        switch address.family {
        case AF_INET:
            var sin = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                                  sin_family: UInt8(address.family),
                                  sin_port: in_port_t(address.port).bigEndian,
                                  sin_addr: in_addr(s_addr: inet_addr(address.addr)),
                                  sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
            let sinlen = socklen_t(sin.sin_len)
            let startDate = Date()
            ret = withUnsafePointer(to: &sin) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.connect(fd, $0, sinlen)
                }
            }
            SocLogger.setResponse(startDate)
            let logAddress = "{sin_family=AF_INET, sin_port=\(address.port), sin_addr=\"\(address.addr)\"}"
            SocLogger.trace(funcName: "connect", argsText: "\(fd), \(logAddress), \(sinlen)", retval: ret)
        
        case AF_UNIX:
            var sun = sockaddr_un()
            sun.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
            sun.sun_family = UInt8(address.family)
            _ = address.addr.withCString { path in
                Darwin.memcpy(&(sun.sun_path), path, Int(strlen(path)))
            }
            let sunlen = socklen_t(sun.sun_len)
            let startDate = Date()
            ret = withUnsafePointer(to: &sun) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.connect(fd, $0, sunlen)
                }
            }
            SocLogger.setResponse(startDate)
            let logAddress = "{sun_family=AF_UNIX, sun_path=\"\(address.addr)\"}"
            SocLogger.trace(funcName: "connect", argsText: "\(fd), \(logAddress), \(sunlen)", retval: ret)
            
        default:
            throw SocError.InvalidParameter
        }
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "connect")
        }
    }
    
    func listen(backlog: Int32) throws {
        let startDate = Date()
        let ret = Darwin.listen(fd, backlog)
        SocLogger.setResponse(startDate)
        SocLogger.trace(funcName: "listen", argsText: "\(fd), \(backlog)", retval: ret)
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "listen")
        }
    }
    
    func accept(needAddress: Bool) throws -> (SocSocket, SocAddress?) {
        let conn: Int32
        var address: SocAddress? = nil
        
        if needAddress {
            switch self.family {
            case PF_INET:
                var sin = sockaddr_in()
                var sinlen = socklen_t(MemoryLayout<sockaddr_in>.size)
                let startDate = Date()
                conn = withUnsafeMutablePointer(to: &sin) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        Darwin.accept(fd, $0, &sinlen)
                    }
                }
                SocLogger.setResponse(startDate)
                let addr = String.init(cString: inet_ntoa(sin.sin_addr))
                let logAddress = "{sin_family=AF_INET, sin_port=\(sin.sin_port), sin_addr=\"\(addr)\"}"
                SocLogger.trace(funcName: "accept", argsText: "\(fd), \(logAddress), [\(sinlen)]", retval: conn)
                address = SocAddress(family: AF_INET, addr: String.init(cString: inet_ntoa(sin.sin_addr)), port: UInt16(sin.sin_port))
            
            case PF_UNIX:
                var sun = sockaddr_un()
                var sunlen = socklen_t(MemoryLayout<sockaddr_un>.size)
                let startDate = Date()
                conn = withUnsafeMutablePointer(to: &sun) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        Darwin.accept(fd, $0, &sunlen)
                    }
                }
                SocLogger.setResponse(startDate)
                let capacity = MemoryLayout.size(ofValue: sun.sun_path)
                let path = withUnsafePointer(to: &sun.sun_path) {
                    $0.withMemoryRebound(to: UInt8.self, capacity: capacity) {
                        String(cString: $0)
                    }
                }
                let logAddress = "{sun_family=AF_UNIX, sun_path=\"\(path)\"}"
                SocLogger.trace(funcName: "accept", argsText: "\(fd), \(logAddress), [\(sunlen)]", retval: conn)
                address = SocAddress(family: AF_UNIX, addr: path)
            
            default:
                throw SocError.InvalidParameter
            }
        }
        else {
            let startDate = Date()
            conn = Darwin.accept(fd, nil, nil)
            SocLogger.setResponse(startDate)
            SocLogger.trace(funcName: "accept", argsText: "\(fd), NULL, NULL", retval: conn)
        }
        guard conn != -1 else {
            throw SocError.SocketError(code: errno, function: "accept")
        }
        let socket = SocSocket(fd: conn, family: self.family, type: self.type, proto: self.proto)
        return (socket, address)
    }
    
    func send(data: Data, flags: Int32) throws -> Int {
        let startDate = Date()
        let sent = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> size_t in
            let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
            return Darwin.send(fd, unsafeBufferPointer.baseAddress, data.count, flags)
        }
        SocLogger.setResponse(startDate)
        let logBuffer = SocLogger.getHdrAscii(data: data, length: sent)
        let logFlags = SocLogger.getMsgFlagsMask(flags)
        SocLogger.trace(funcName: "send", argsText: "\(fd), \(logBuffer), \(data.count), \(logFlags)", retval: Int32(sent))
        SocLogger.dataDump(data: data, length: sent)
        guard sent != -1 else {
            throw SocError.SocketError(code: errno, function: "send")
        }
        return sent
    }
    
    func sendto(data: Data, flags: Int32, address: SocAddress?) throws -> Int {
        let logFlags = SocLogger.getMsgFlagsMask(flags)
        let sent: size_t
        
        if let toAddress = address {
            switch toAddress.family {
            case AF_INET:
                var sin = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                                      sin_family: UInt8(toAddress.family),
                                      sin_port: in_port_t(toAddress.port).bigEndian,
                                      sin_addr: in_addr(s_addr: inet_addr(toAddress.addr)),
                                      sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
                let sinlen = socklen_t(sin.sin_len)
                let startDate = Date()
                sent = withUnsafePointer(to: &sin) { sockaddr_in in
                    sockaddr_in.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                        data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> size_t in
                            let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                            return Darwin.sendto(fd, unsafeBufferPointer.baseAddress, data.count, flags, sockaddr, sinlen)
                        }
                    }
                }
                SocLogger.setResponse(startDate)
                let logBuffer = SocLogger.getHdrAscii(data: data, length: sent)
                let logAddress = "{sin_family=AF_INET, sin_port=\(toAddress.port), sin_addr=\"\(toAddress.addr)\"}"
                SocLogger.trace(funcName: "sendto", argsText: "\(fd), \(logBuffer), \(data.count), \(logFlags), \(logAddress), \(sinlen)", retval: Int32(sent))
            
            case AF_UNIX:
                var sun = sockaddr_un()
                sun.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
                sun.sun_family = UInt8(toAddress.family)
                _ = toAddress.addr.withCString { path in
                    Darwin.memcpy(&(sun.sun_path), path, Int(strlen(path)))
                }
                let sunlen = socklen_t(sun.sun_len)
                let startDate = Date()
                sent = withUnsafePointer(to: &sun) { sockaddr_in in
                    sockaddr_in.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                        data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> size_t in
                            let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                            return Darwin.sendto(fd, unsafeBufferPointer.baseAddress, data.count, flags, sockaddr, sunlen)
                        }
                    }
                }
                SocLogger.setResponse(startDate)
                let logBuffer = SocLogger.getHdrAscii(data: data, length: sent)
                let logAddress = "{sun_family=AF_UNIX, sun_path=\"\(toAddress.addr)\"}"
                SocLogger.trace(funcName: "sendto", argsText: "\(fd), \(logBuffer), \(data.count), \(logFlags), \(logAddress), \(sunlen)", retval: Int32(sent))
                
            default:
                throw SocError.InvalidParameter
            }
        }
        else {
            let startDate = Date()
            sent = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> size_t in
                let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                return Darwin.sendto(fd, unsafeBufferPointer.baseAddress, data.count, flags, nil, 0)
            }
            SocLogger.setResponse(startDate)
            let logBuffer = SocLogger.getHdrAscii(data: data, length: sent)
            SocLogger.trace(funcName: "sendto", argsText: "\(fd), \(logBuffer), \(data.count), \(logFlags), NULL, 0", retval: Int32(sent))
        }
        guard sent != -1 else {
            throw SocError.SocketError(code: errno, function: "sendto")
        }
        SocLogger.dataDump(data: data, length: sent)
        return sent
    }
    
    func sendmsg(datas: [Data], control: [SocCmsg], flags: Int32, address: SocAddress?) throws -> Int {
        let iovlen = Int32(datas.count)
        guard iovlen > 0 else {
            return 0
        }
        guard iovlen == 1 else {
            throw SocError.InvalidParameter
        }
        var data = datas[0]
        
        var bytes: [UInt8] = []
        for i in 0 ..< control.count {
            bytes += control[i].uint8array
        }
        var msgControl = Data(_: bytes)
        let msgControlLen = bytes.count
        let logControl = SocLogger.getHdrAscii(data: msgControl, length: msgControlLen)
        let logFlags = SocLogger.getMsgFlagsMask(flags)
        
        let sent: size_t
        var vec = data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> iovec in
            return iovec(iov_base: pointer.baseAddress, iov_len: pointer.count)
        }
        if let toAddress = address {
            switch toAddress.family {
            case AF_INET:
                var sin = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                                      sin_family: UInt8(toAddress.family),
                                      sin_port: in_port_t(toAddress.port).bigEndian,
                                      sin_addr: in_addr(s_addr: inet_addr(toAddress.addr)),
                                      sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
                let sinlen = socklen_t(sin.sin_len)
                let startDate = Date()
                sent = withUnsafeMutablePointer(to: &vec) { vecPtr in
                    withUnsafeMutablePointer(to: &sin) { sockaddr_in in
                        sockaddr_in.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                            msgControl.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                                let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                                var messageHeader = msghdr(msg_name: sockaddr,
                                                           msg_namelen: sinlen,
                                                           msg_iov: vecPtr,
                                                           msg_iovlen: iovlen,
                                                           msg_control: unsafeBufferPointer.baseAddress,
                                                           msg_controllen: socklen_t(msgControlLen),
                                                           msg_flags: 0)
                                let ret = withUnsafeMutablePointer(to: &messageHeader) { messageHeader in
                                    return Darwin.sendmsg(fd, messageHeader, flags)
                                }
                                return ret
                            }
                        }
                    }
                }
                SocLogger.setResponse(startDate)
                let logAddress = "{sin_family=AF_INET, sin_port=[\(toAddress.port)], sin_addr=\"\(toAddress.addr)\"}"
                let logBuffer = SocLogger.getHdrAscii(data: data, length: sent)
                let logMsg = "{msg_name=\(logAddress), msg_namelen=\(sinlen), msg_iov=[\(logBuffer)], msg_iovlen=\(iovlen), msg_control=\(logControl), msg_controllen=\(msgControlLen), msg_flags=0}"
                SocLogger.trace(funcName: "sendmsg", argsText: "\(fd), \(logMsg), \(logFlags)", retval: Int32(sent))
                
            case AF_UNIX:
                var sun = sockaddr_un()
                sun.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
                sun.sun_family = UInt8(toAddress.family)
                _ = toAddress.addr.withCString { path in
                    Darwin.memcpy(&(sun.sun_path), path, Int(strlen(path)))
                }
                let sunlen = socklen_t(sun.sun_len)
                let startDate = Date()
                sent = withUnsafeMutablePointer(to: &vec) { vecPtr in
                    withUnsafeMutablePointer(to: &sun) { sockaddr_un in
                        sockaddr_un.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                            msgControl.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                                let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                                var messageHeader = msghdr(msg_name: sockaddr,
                                                           msg_namelen: sunlen,
                                                           msg_iov: vecPtr,
                                                           msg_iovlen: iovlen,
                                                           msg_control: unsafeBufferPointer.baseAddress,
                                                           msg_controllen: socklen_t(msgControlLen),
                                                           msg_flags: 0)
                                let ret = withUnsafeMutablePointer(to: &messageHeader) { messageHeader in
                                    return Darwin.sendmsg(fd, messageHeader, flags)
                                }
                                return ret
                            }
                        }
                    }
                }
                SocLogger.setResponse(startDate)
                let logAddress = "{sun_family=AF_UNIX, sun_path=\"\(toAddress.addr)\"}"
                let logBuffer = SocLogger.getHdrAscii(data: data, length: sent)
                let logMsg = "{msg_name=\(logAddress), msg_namelen=\(sunlen), msg_iov=[\(logBuffer)], msg_iovlen=\(iovlen), msg_control=\(logControl), msg_controllen=\(msgControlLen), msg_flags=0}"
                SocLogger.trace(funcName: "sendmsg", argsText: "\(fd), \(logMsg), \(logFlags)", retval: Int32(sent))
                
            default:
                throw SocError.InvalidParameter
            }
        }
        else {
            let startDate = Date()
            sent = withUnsafeMutablePointer(to: &vec) { vecPtr in
                msgControl.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                    let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                    var messageHeader = msghdr(msg_name: nil,
                                               msg_namelen: 0,
                                               msg_iov: vecPtr,
                                               msg_iovlen: iovlen,
                                               msg_control: unsafeBufferPointer.baseAddress,
                                               msg_controllen: socklen_t(msgControlLen),
                                               msg_flags: 0)
                    let ret = withUnsafeMutablePointer(to: &messageHeader) { messageHeader in
                        return Darwin.sendmsg(fd, messageHeader, flags)
                    }
                    return ret
                }
            }
            SocLogger.setResponse(startDate)
            let logBuffer = SocLogger.getHdrAscii(data: data, length: sent)
            let logMsg = "{msg_name=NULL, msg_namelen=0, msg_iov=[\(logBuffer)], msg_iovlen=\(iovlen), msg_control=\(logControl), msg_controllen=\(msgControlLen), msg_flags=0}"
            SocLogger.trace(funcName: "sendmsg", argsText: "\(fd), \(logMsg), \(logFlags)", retval: Int32(sent))
        }
        guard sent != -1 else {
            throw SocError.SocketError(code: errno, function: "sendmsg")
        }
        SocLogger.dataDump(data: data, length: sent, label: "msg_iov[0]:")
        SocLogger.dataDump(data: msgControl, length: msgControlLen, label: "msg_control:")
        return sent
    }
    
    func recv(data: inout Data, flags: Int32) throws -> Int {
        let startDate = Date()
        let buflen = data.count
        let received = data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
            let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
            return Darwin.recv(fd, unsafeBufferPointer.baseAddress, buflen, flags)
        }
        SocLogger.setResponse(startDate)
        let logBuffer = SocLogger.getHdrAscii(data: data, length: received)
        let logFlags = SocLogger.getMsgFlagsMask(flags)
        SocLogger.trace(funcName: "recv", argsText: "\(fd), \(logBuffer), \(buflen), \(logFlags)", retval: Int32(received))
        guard received != -1 else {
            throw SocError.SocketError(code: errno, function: "recv")
        }
        return received
    }
    
    func recvfrom(data: inout Data, flags: Int32, needAddress: Bool) throws -> (Int, SocAddress?) {
        let buflen = data.count
        let logFlags = SocLogger.getMsgFlagsMask(flags)
        var address: SocAddress? = nil
        let received: size_t
        
        if needAddress {
            switch self.family {
            case PF_INET:
                var sin = sockaddr_in()
                var sinlen = socklen_t(MemoryLayout<sockaddr_in>.size)
                let startDate = Date()
                received = withUnsafeMutablePointer(to: &sin) { sockaddr_in in
                    sockaddr_in.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                        data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                            let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                            return Darwin.recvfrom(fd, unsafeBufferPointer.baseAddress, buflen, 0, sockaddr, &sinlen)
                        }
                    }
                }
                SocLogger.setResponse(startDate)
                let addr = String.init(cString: inet_ntoa(sin.sin_addr))
                let logBuffer = SocLogger.getHdrAscii(data: data, length: received)
                let logAddress = "{sin_family=AF_INET, sin_port=[\(sin.sin_port)], sin_addr=\"\(addr)\"}"
                SocLogger.trace(funcName: "recvfrom", argsText: "\(fd), \(logBuffer), \(buflen), \(logFlags), \(logAddress), [\(sinlen)]", retval: Int32(received))
                address = SocAddress(family: AF_INET, addr: addr, port: UInt16(sin.sin_port))
                
            case PF_UNIX:
                var sun = sockaddr_un()
                var sunlen = socklen_t(MemoryLayout<sockaddr_un>.size)
                let startDate = Date()
                received = withUnsafeMutablePointer(to: &sun) { sockaddr_un in
                    sockaddr_un.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                        data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                            let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                            return Darwin.recvfrom(fd, unsafeBufferPointer.baseAddress, buflen, flags, sockaddr, &sunlen)
                        }
                    }
                }
                SocLogger.setResponse(startDate)
                let capacity = MemoryLayout.size(ofValue: sun.sun_path)
                let path = withUnsafePointer(to: &sun.sun_path) {
                    $0.withMemoryRebound(to: UInt8.self, capacity: capacity) {
                        String(cString: $0)
                    }
                }
                let logBuffer = SocLogger.getHdrAscii(data: data, length: received)
                let logAddress = "{sun_family=AF_UNIX, sun_path=\"\(path)\"}"
                SocLogger.trace(funcName: "recvfrom", argsText: "\(fd), \(logBuffer), \(buflen), \(logFlags), \(logAddress), [\(sunlen)]", retval: Int32(received))
                address = SocAddress(family: AF_UNIX, addr: path)
                
            default:
                throw SocError.InvalidParameter
            }
        }
        else {
            let startDate = Date()
            received = data.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                return Darwin.recvfrom(fd, unsafeBufferPointer.baseAddress, buflen, flags, nil, nil)
            }
            SocLogger.setResponse(startDate)
            let logBuffer = SocLogger.getHdrAscii(data: data, length: received)
            SocLogger.trace(funcName: "recvfrom", argsText: "\(fd), \(logBuffer), \(buflen), \(logFlags), NULL, NULL", retval: Int32(received))
        }
        guard received != -1 else {
            throw SocError.SocketError(code: errno, function: "recvfrom")
        }
        SocLogger.dataDump(data: data, length: received)
        return (received, address)
    }
    
    func recvmsg(datas: inout [Data], controlLen: Int, flags: Int32, needAddress: Bool) throws -> (Int, [SocCmsg], Int32, SocAddress?) {
        let iovlen = Int32(datas.count)
        guard iovlen == 1 else {
            throw SocError.InvalidParameter
        }
        var msgFlags: Int32 = 0
        var msgControl = Data([UInt8](repeating: 0, count: controlLen))
        var msgControlLen = controlLen

        let logFlags = SocLogger.getMsgFlagsMask(flags)
        var address: SocAddress? = nil
        
        let received: size_t
        var vec = datas[0].withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> iovec in
            return iovec(iov_base: pointer.baseAddress, iov_len: pointer.count)
        }
        if needAddress {
            switch self.family {
            case PF_INET:
                var sin = sockaddr_in()
                var sinlen = socklen_t(MemoryLayout<sockaddr_in>.size)
                let startDate = Date()
                received = withUnsafeMutablePointer(to: &vec) { vecPtr in
                    withUnsafeMutablePointer(to: &sin) { sockaddr_in in
                        sockaddr_in.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                            msgControl.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                                let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                                var messageHeader = msghdr(msg_name: sockaddr,
                                                           msg_namelen: sinlen,
                                                           msg_iov: vecPtr,
                                                           msg_iovlen: iovlen,
                                                           msg_control: unsafeBufferPointer.baseAddress,
                                                           msg_controllen: socklen_t(msgControlLen),
                                                           msg_flags: msgFlags)
                                defer {
                                    sinlen = messageHeader.msg_namelen
                                    msgControlLen = Int(messageHeader.msg_controllen)
                                    msgFlags = messageHeader.msg_flags
                                }
                                let ret = withUnsafeMutablePointer(to: &messageHeader) { messageHeader in
                                    return Darwin.recvmsg(fd, messageHeader, flags)
                                }
                                return ret
                            }
                        }
                    }
                }
                SocLogger.setResponse(startDate)
                let addr = String.init(cString: inet_ntoa(sin.sin_addr))
                let logAddress = "{sin_family=AF_INET, sin_port=[\(sin.sin_port)], sin_addr=\"\(addr)\"}"
                let logBuffer = SocLogger.getHdrAscii(data: datas[0], length: received)
                let logControl = SocLogger.getHdrAscii(data: msgControl, length: msgControlLen)
                let logMsgFlags = SocLogger.getMsgFlagsMask(msgFlags)
                let logMsg = "{msg_name=\(logAddress), msg_namelen=[\(sinlen)], msg_iov=[\(logBuffer)], msg_iovlen=\(iovlen), msg_control=\(logControl), msg_controllen=[\(msgControlLen)], msg_flags=[\(logMsgFlags)]}"
                SocLogger.trace(funcName: "recvmsg", argsText: "\(fd), \(logMsg), \(logFlags)", retval: Int32(received))
                address = SocAddress(family: AF_INET, addr: addr, port: UInt16(sin.sin_port))
                
            case PF_UNIX:
                var sun = sockaddr_un()
                var sunlen = socklen_t(MemoryLayout<sockaddr_un>.size)
                let startDate = Date()
                received = withUnsafeMutablePointer(to: &vec) { vecPtr in
                    withUnsafeMutablePointer(to: &sun) { sockaddr_un in
                        sockaddr_un.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddr in
                            msgControl.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                                let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                                var messageHeader = msghdr(msg_name: sockaddr,
                                                           msg_namelen: sunlen,
                                                           msg_iov: vecPtr,
                                                           msg_iovlen: iovlen,
                                                           msg_control: unsafeBufferPointer.baseAddress,
                                                           msg_controllen: socklen_t(msgControlLen),
                                                           msg_flags: msgFlags)
                                defer {
                                    sunlen = messageHeader.msg_namelen
                                    msgControlLen = Int(messageHeader.msg_controllen)
                                    msgFlags = messageHeader.msg_flags
                                }
                                let ret = withUnsafeMutablePointer(to: &messageHeader) { messageHeader in
                                    return Darwin.recvmsg(fd, messageHeader, flags)
                                }
                                return ret
                            }
                        }
                    }
                }
                SocLogger.setResponse(startDate)
                let capacity = MemoryLayout.size(ofValue: sun.sun_path)
                let path = withUnsafePointer(to: &sun.sun_path) {
                    $0.withMemoryRebound(to: UInt8.self, capacity: capacity) {
                        String(cString: $0)
                    }
                }
                let logAddress = "{sun_family=AF_UNIX, sun_path=\"\(path)\"}"
                let logBuffer = SocLogger.getHdrAscii(data: datas[0], length: received)
                let logControl = SocLogger.getHdrAscii(data: msgControl, length: msgControlLen)
                let logMsgFlags = SocLogger.getMsgFlagsMask(msgFlags)
                let logMsg = "{msg_name=\(logAddress), msg_namelen=[\(sunlen)], msg_iov=[\(logBuffer)], msg_iovlen=\(iovlen), msg_control=\(logControl), msg_controllen=[\(msgControlLen)], msg_flags=[\(logMsgFlags)]}"
                SocLogger.trace(funcName: "recvmsg", argsText: "\(fd), \(logMsg), \(logFlags)", retval: Int32(received))
                address = SocAddress(family: AF_UNIX, addr: path)
                
            default:
                throw SocError.InvalidParameter
            }
        }
        else {
            let startDate = Date()
            received = withUnsafeMutablePointer(to: &vec) { vecPtr in
                msgControl.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> size_t in
                    let unsafeBufferPointer = pointer.bindMemory(to: UInt8.self)
                    var messageHeader = msghdr(msg_name: nil,
                                               msg_namelen: 0,
                                               msg_iov: vecPtr,
                                               msg_iovlen: iovlen,
                                               msg_control: unsafeBufferPointer.baseAddress,
                                               msg_controllen: socklen_t(msgControlLen),
                                               msg_flags: msgFlags)
                    defer {
                        msgControlLen = Int(messageHeader.msg_controllen)
                        msgFlags = messageHeader.msg_flags
                    }
                    let ret = withUnsafeMutablePointer(to: &messageHeader) { messageHeader in
                        return Darwin.recvmsg(fd, messageHeader, flags)
                    }
                    return ret
                }
            }
            SocLogger.setResponse(startDate)
            let logBuffer = SocLogger.getHdrAscii(data: datas[0], length: received)
            let logControl = SocLogger.getHdrAscii(data: msgControl, length: msgControlLen)
            let logMsgFlags = SocLogger.getMsgFlagsMask(msgFlags)
            let logMsg = "{msg_name=NULL, msg_namelen=[0], msg_iov=[\(logBuffer)], msg_iovlen=\(iovlen), msg_control=\(logControl), msg_controllen=[\(msgControlLen)], msg_flags=[\(logMsgFlags)]}"
            SocLogger.trace(funcName: "recvmsg", argsText: "\(fd), \(logMsg), \(logFlags)", retval: Int32(received))
        }
        guard received != -1 else {
            throw SocError.SocketError(code: errno, function: "recvmsg")
        }
        SocLogger.dataDump(data: datas[0], length: received, label: "msg_iov[0]:")
        SocLogger.dataDump(data: msgControl, length: msgControlLen, label: "msg_control:")
        let cmsgs = SocCmsg.loadCmsgs(control: msgControl, length: msgControlLen)
//        let cmsgs: [SocCmsg] = []
        return (received, cmsgs, msgFlags, address)
    }

    func getsockname() throws -> SocAddress {
        let address: SocAddress
        let ret: Int32
        switch self.family {
        case PF_INET:
            var sin = sockaddr_in()
            var sinlen = socklen_t(MemoryLayout<sockaddr_in>.size)
            let startDate = Date()
            ret = withUnsafeMutablePointer(to: &sin) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.getsockname(fd, $0, &sinlen)
                }
            }
            SocLogger.setResponse(startDate)
            let addr = String.init(cString: inet_ntoa(sin.sin_addr))
            let logAddress = "{sin_family=AF_INET, sin_port=\(sin.sin_port), sin_addr=\"\(addr)\"}"
            SocLogger.trace(funcName: "getsockname", argsText: "\(fd), \(logAddress), [\(sinlen)]", retval: Int32(ret))
            address = SocAddress(family: AF_INET, addr: addr, port: UInt16(sin.sin_port))
            
        case PF_UNIX:
            var sun = sockaddr_un()
            var sunlen = socklen_t(MemoryLayout<sockaddr_un>.size)
            let startDate = Date()
            ret = withUnsafeMutablePointer(to: &sun) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.getsockname(fd, $0, &sunlen)
                }
            }
            SocLogger.setResponse(startDate)
            let capacity = MemoryLayout.size(ofValue: sun.sun_path)
            let path = withUnsafePointer(to: &sun.sun_path) {
                $0.withMemoryRebound(to: UInt8.self, capacity: capacity) {
                    String(cString: $0)
                }
            }
            let logAddress = "{sun_family=AF_UNIX, sun_path=\"\(path)\"}"
            SocLogger.trace(funcName: "getsockname", argsText: "\(fd), \(logAddress), [\(sunlen)]", retval: Int32(ret))
            address = SocAddress(family: AF_UNIX, addr: path)
            
        default:
            throw SocError.InvalidParameter
        }
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "getpeername")
        }
        return address
    }
    
    func getpeername() throws -> SocAddress {
        let address: SocAddress
        let ret: Int32
        switch self.family {
        case PF_INET:
            var sin = sockaddr_in()
            var sinlen = socklen_t(MemoryLayout<sockaddr_in>.size)
            let startDate = Date()
            ret = withUnsafeMutablePointer(to: &sin) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.getpeername(fd, $0, &sinlen)
                }
            }
            SocLogger.setResponse(startDate)
            let addr = String.init(cString: inet_ntoa(sin.sin_addr))
            let logAddress = "{sin_famiy=AF_INET, sin_port=\(sin.sin_port), sin_addr=\"\(addr)\"}"
            SocLogger.trace(funcName: "getpeername", argsText: "\(fd), \(logAddress), [\(sinlen)]", retval: Int32(ret))
            address = SocAddress(family: AF_INET, addr: addr, port: UInt16(sin.sin_port))
            
        case PF_UNIX:
            var sun = sockaddr_un()
            var sunlen = socklen_t(MemoryLayout<sockaddr_un>.size)
            let startDate = Date()
            ret = withUnsafeMutablePointer(to: &sun) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    Darwin.getpeername(fd, $0, &sunlen)
                }
            }
            SocLogger.setResponse(startDate)
            let capacity = MemoryLayout.size(ofValue: sun.sun_path)
            let path = withUnsafePointer(to: &sun.sun_path) {
                $0.withMemoryRebound(to: UInt8.self, capacity: capacity) {
                    String(cString: $0)
                }
            }
            let logAddress = "{sun_family=AF_UNIX, sun_path=\"\(path)\"}}"
            SocLogger.trace(funcName: "getpeername", argsText: "\(fd), \(logAddress), [\(sunlen)]", retval: Int32(ret))
            address = SocAddress(family: AF_UNIX, addr: path)
            
        default:
            throw SocError.InvalidParameter
        }
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "getpeername")
        }
        return address
    }
    
    func shutdown(how: Int32) throws {
        var logHow = String(how)
        if how < SocLogger.howNames.count {
            logHow = SocLogger.howNames[Int(how)]
        }
        let startDate = Date()
        let ret = Darwin.shutdown(fd, how)
        SocLogger.setResponse(startDate)
        SocLogger.trace(funcName: "shutdown", argsText: "\(fd), \(logHow)", retval: Int32(ret))
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "shutdown")
        }
    }
    
    func fcntl(cmd: Int32, flags: Int32) throws -> Int32 {
        let logCmd = (cmd == F_GETFL) ? "F_GETFL" : "F_SETFL"
        let logFlags = SocLogger.getFileFlagsMask(fileFlags: flags)
        
        let startDate = Date()
        let ret = Darwin.fcntl(fd, cmd, flags)
        SocLogger.setResponse(startDate)
        SocLogger.trace(funcName: "fcntl", argsText: "\(fd), \(logCmd), \(logFlags)", retval: ret)
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "fcntl")
        }
        return ret
    }
    
    func poll(events: Int32, timeout: Int32) throws -> Int32 {
        var fds = [ pollfd(fd: self.fd, events: Int16(events), revents: 0) ]
        let startDate = Date()
        let ret = Darwin.poll(&fds, 1, timeout)
        SocLogger.setResponse(startDate)
        let logFDS = "{fd=\(fd), events=\(SocLogger.getEventsMask(events)), revents=\(SocLogger.getEventsMask(Int32(fds[0].revents)))}"
        SocLogger.trace(funcName: "poll", argsText: "[\(logFDS)], 1, \(timeout)", retval: ret)
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "poll")
        }
        return Int32(fds[0].revents)
    }
    
    static func poll(sockets: inout [SocSocket]) -> Int {
        do {
            return try Self.poll(sockets: &sockets, events: POLLIN|POLLPRI|POLLOUT, timeout: 0)
        }
        catch {
            return -1
        }
    }
    
    static func poll(sockets: inout [SocSocket], events: Int32, timeout: Int32) throws -> Int {
        var fds: [pollfd] = []
        for i in 0 ..< sockets.count {
            if sockets[i].isClosed || sockets[i].isRdShutdown {
                continue
            }
            fds.append(pollfd(fd: sockets[i].fd, events: Int16(events), revents: 0))
        }
        if fds.count == 0 {
            return -1
        }
        let startDate = Date()
        let ret = Darwin.poll(&fds, nfds_t(fds.count), timeout)
        SocLogger.setResponse(startDate)
        var logFDS = ""
        for i in 0 ..< fds.count {
            if !logFDS.isEmpty {
                logFDS += ", "
            }
            logFDS += "{fd=\(fds[i].fd), events=\(SocLogger.getEventsMask(Int32(fds[i].events))), revents=\(SocLogger.getEventsMask(Int32(fds[i].revents)))}"
            for j in 0 ..< sockets.count {
                if sockets[j].isClosed || sockets[j].fd != fds[i].fd {
                    continue
                }
                sockets[j].revents = Int32(fds[i].revents)
                break
            }
        }
        SocLogger.trace(funcName: "poll", argsText: "[\(logFDS)], \(fds.count), \(timeout)", retval: ret)
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "poll")
        }
        return Int(ret)
    }
    
    func close() throws {
        let startDate = Date()
        let ret = Darwin.close(fd)
        SocLogger.setResponse(startDate)
        SocLogger.trace(funcName: "close", argsText: "\(fd)", retval: Int32(ret))
        guard ret != -1 else {
            throw SocError.SocketError(code: errno, function: "close")
        }
    }
}
