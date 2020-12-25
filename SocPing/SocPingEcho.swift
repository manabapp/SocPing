//
//  SocPingEcho.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import Darwin
import Foundation

struct SocPingEcho {
    let proto: Int32         // ICMP or UDP
    var icmpHdr: icmp        // for ICMP
    var address: SocAddress  // for UDP
    
    var type: UInt8       { return self.icmpHdr.icmp_type   }
    var code: UInt8       { return self.icmpHdr.icmp_code   }
    var cksum: UInt16     { return self.icmpHdr.icmp_cksum  }
    var id: UInt16        { return self.icmpHdr.icmp_id     }
    var seq: UInt16       { return self.icmpHdr.icmp_seq    }
    var addr: String      { return self.address.addr        }
    var port: UInt16      { return self.address.port        }
    var hostName: String  { return self.address.hostName    }
    var isMulticast: Bool { return self.address.isMulticast }
    var isBroadcast: Bool { return self.address.isBroadcast }
    
    // These parameter is sets in each preset() after initialization
    var counter: Int = 0                      // increment counter
    var baseNumber: Int = 0                   // base seq/port for increment
    var isSeqRandom: Bool = false             // ICMP seq type is random
    var isPortRandom: Bool = false            // UDP port type is random
    var isDataRandom: Bool = false            // payloadData type is random
    var payloadData: [UInt8] = []             //
    var payloadLen: Int = 0                   //
    var payloadMaxLen: Int = ICMP_MAXLEN      // for UDP, same length
    var payloadIncr: Int = 0                  // increment size of payload in sweeping mode
    var usePayloadTv: Bool = false            // timeval is set to head of payload
    
    static let tvLen = 8                      // length of structure timeval (sec:4 + usec:4)
    static let valueTypeDefault: Int = 0      // PID(ICMP id), 0(ICMP seq), 49152(UDP port)
    static let valueTypeUserSet: Int = 1      // Sets by User
    static let valueTypeRandom: Int = 2       // ICMP id, seq(0-65535), UDP port(49152-65535: Dynamic & Private port range ref. IANA)
    static let valueTypeSweep: Int = 2        // payload size
    static let portRangeStart: Int = 49152    // Start of the range
    static let pingPortDefault: Int = 31338   // same as nmap
    static let tracePortDefault: Int = 33434  // same as macOS's, cisco traceroute
    static let payloadTypeZ: Int = 0          // All Zero bits (0x00, 0x00, 0x00, 0x00, ...)
    static let payloadTypeF: Int = 1          // All One bits (0xFF, 0xFF, 0xFF, 0xFF, ...)
    static let payloadTypeC: Int = 2          // Continuas digit number (0x08, 0x09, 0x0a, 0x0b, ...)
    static let payloadTypeR: Int = 3          // Random
    static let printableLetters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~ "
    
    static func subRtt(_ sent: timeval, _ received: timeval) -> Double {
        let subSec = Int64(received.tv_sec) - Int64(sent.tv_sec)
        let subUsec = Int64(received.tv_usec) - Int64(sent.tv_usec)
        let rtt = Double(subSec) + Double(subUsec) / 1000000.0
        SocLogger.debug("SocPingEcho.subRtt: \(received) - \(sent) = \(rtt)")
        return rtt
    }
    
    static func getIpHdrLen(base: Data, offset: Int) -> Int {
        let ipVhl = Data(base[offset ..< offset + 1]).withUnsafeBytes { $0.load(as: UInt8.self) }
        let ipHdrLen = Int((ipVhl & 0xF) << 2)
        SocLogger.debug("SocPingEcho.getIpHdrLen: \(ipHdrLen)")
        return ipHdrLen
    }
    
    static func getIpHdr(base: Data, offset: Int) -> ip {
        let ipHdr = Data(base[offset ..< offset + IP_HDRLEN]).withUnsafeBytes { $0.load(as: ip.self) }
        SocLogger.debug("SocPingEcho.getIpHdr: \(ipHdr)")
        return ipHdr
    }
    
    static func getIcmpHdr(base: Data, offset: Int) -> icmp {
        let icmpHdr = Data(base[offset ..< offset + ICMP_HDRLEN]).withUnsafeBytes { $0.load(as: icmp.self) }
        SocLogger.debug("SocPingEcho.getIcmpHdr: \(icmpHdr)")
        return icmpHdr
    }
    
    static func getUdpHdr(base: Data, offset: Int) -> udphdr {
//        let udpHdr = Data(base[offset ..< offset + UDP_HDRLEN]).withUnsafeBytes { $0.load(as: udphdr.self) }
        let sport = Data(base[offset ..< offset + 2]).withUnsafeBytes { $0.load(as: UInt16.self) }
        let dport = Data(base[offset + 2 ..< offset + 4]).withUnsafeBytes { $0.load(as: UInt16.self) }
        let len = Data(base[offset + 4 ..< offset + 6]).withUnsafeBytes { $0.load(as: UInt16.self) }
        let cksum = Data(base[offset + 6 ..< offset + 8]).withUnsafeBytes { $0.load(as: UInt16.self) }
        let udpHdr = udphdr(uh_sport: sport.bigEndian, uh_dport: dport.bigEndian, uh_ulen: len.bigEndian, uh_sum: cksum.bigEndian)
        SocLogger.debug("SocPingEcho.getUdpHdr: \(udpHdr)")
        return udpHdr
    }
    
    static func getPayloadTv(base: Data, offset: Int) -> timeval {
        var tv = timeval()
        let sec = Data(base[offset ..< offset + 4]).withUnsafeBytes { $0.load(as: UInt32.self) }
        let usec = Data(base[offset + 4 ..< offset + 8]).withUnsafeBytes { $0.load(as: UInt32.self) }
        tv.tv_sec = Int(sec.bigEndian & 0x7FFFFFFF)
        tv.tv_usec = Int32(usec.bigEndian & 0x7FFFFFFF)
        SocLogger.debug("SocPingEcho.getPayloadTv: \(tv)")
        return tv
    }

    init(proto: Int32, address: SocAddress) {
        self.proto = proto
        self.icmpHdr = icmp(type: UInt8(ICMP_ECHO), code: 0)
        self.address = address
        SocLogger.debug("SocPingEcho.init: proto=\(proto), address=\(address.addr)")
    }
    
    mutating func setId(_ id: UInt16) {
        self.icmpHdr.icmp_id = id
        SocLogger.debug("SocPingEcho.setId: \(id)")
    }
    
    mutating func setSeq(_ seq: UInt16) {
        self.icmpHdr.icmp_seq = seq
        self.baseNumber = Int(seq)
        SocLogger.debug("SocPingEcho.setSeq: \(seq)")
    }
    
    mutating func setPort(_ port: UInt16) {
        self.address.port = port
        self.baseNumber = Int(port)
        SocLogger.debug("SocPingEcho.setPort: \(port)")
    }
    
    mutating func setPayload(type: Int, length: Int, maxLength: Int = 0, incr: Int = 0, useTv: Bool = false) {
        self.payloadLen = length
        if maxLength > 0 {
            self.payloadMaxLen = maxLength
        }
        if incr > 0 {
            self.payloadIncr = incr
        }
        self.usePayloadTv = useTv
        
        switch type {
        case SocPingEcho.payloadTypeZ:
            self.payloadData = [UInt8](repeating: UInt8.min, count: self.payloadMaxLen)
        case SocPingEcho.payloadTypeF:
            self.payloadData = [UInt8](repeating: UInt8.max, count: self.payloadMaxLen)
        case SocPingEcho.payloadTypeC:
            var byte: UInt8 = 0
            for _ in 0 ..< self.payloadMaxLen {
                self.payloadData.append(byte)
                byte = (byte < UInt8.max) ? byte + 1 : UInt8.min
            }
        default: //payloadTypeR
            self.isDataRandom = true
            for _ in 0 ..< self.payloadMaxLen { self.payloadData.append(UInt8.random(in: .min ... .max)) }
        }
        SocLogger.debug("SocPingEcho.setPayload: type=\(type), length=\(length), maxLength=\(self.payloadMaxLen), useTv=\(self.usePayloadTv)")
    }
    
    mutating func incr() {
        if self.proto == IPPROTO_ICMP {
            if self.isSeqRandom {
                self.icmpHdr.icmp_seq = UInt16.random(in: .min ... .max)
            }
            else {
                let number: Int = (self.baseNumber + self.counter) % (Int(UInt16.max) + 1)
                self.icmpHdr.icmp_seq = UInt16(number)
            }
        }
        else {
            if self.isPortRandom {
                self.address.port = UInt16.random(in: UInt16(SocPingEcho.portRangeStart) ... .max)
            }
            else {
                let number: Int = (self.baseNumber + self.counter) % (Int(UInt16.max) - self.baseNumber + 1)
                self.address.port = UInt16(self.baseNumber + number)
            }
        }
        if self.payloadIncr > 0 && self.payloadLen < self.payloadMaxLen {
            self.payloadLen += self.payloadIncr * self.counter
            if self.payloadLen > self.payloadMaxLen {
                self.payloadLen = self.payloadMaxLen
            }
        }
        self.counter += 1
        SocLogger.debug("SocPingEcho.incr: icmpSeq=\(self.seq), udpPort=\(self.port), payloadLen=\(self.payloadLen)")
    }
    
    mutating func getDatagram() throws -> Data {
        if self.isDataRandom {  // If random type, recreates every time
            self.payloadData = []
            let size = (self.payloadLen < SocPingEcho.tvLen) ? SocPingEcho.tvLen : self.payloadLen
            for _ in 0 ..< size { self.payloadData.append(UInt8.random(in: .min ... .max)) }
            SocLogger.debug("SocPingEcho.getDatagram: new random data - \(size) bytes")
        }
        if self.usePayloadTv {
            var tv = timeval()
            gettimeofday(&tv, nil)
            var payloadTvSec = UInt32(tv.tv_sec).bigEndian
            let secBytePointer = withUnsafePointer(to: &payloadTvSec) {
                $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt32>.size) {
                    UnsafeBufferPointer(start: $0, count: MemoryLayout<UInt32>.size)
                }
            }
            var payloadTvUsec = UInt32(tv.tv_usec).bigEndian
            let usecBytePointer = withUnsafePointer(to: &payloadTvUsec) {
                $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt32>.size) {
                    UnsafeBufferPointer(start: $0, count: MemoryLayout<UInt32>.size)
                }
            }
            let bytes = Array(secBytePointer) + Array(usecBytePointer)
            for i in 0 ..< bytes.count {  // bytes.count is equal as SocPingEcho.tvLen
                self.payloadData[i] = bytes[i]
            }
            SocLogger.debug("SocPingEcho.getDatagram: tv = \(tv)")
        }
        if self.proto == IPPROTO_ICMP {
            var i = 0
            let bytes = self.payloadData
            var sum = UInt64(UInt16(self.type) + UInt16(self.code) >> 1) + UInt64(self.id) + UInt64(self.seq)
            while i < self.payloadLen {
                if (i + 1) == self.payloadLen {
                    sum += Data([bytes[i], 0]).withUnsafeBytes { UInt64($0.load(as: UInt16.self)) }
                }
                else {
                    sum += Data([bytes[i], bytes[i + 1]]).withUnsafeBytes { UInt64($0.load(as: UInt16.self)) }
                }
                i += 2
            }
            while sum >> 16 != 0 {
                sum = (sum & 0xffff) + (sum >> 16)
            }
            guard sum < UInt16.max else {
                SocLogger.error("SocPingEcho.getDatagram: sum:\(sum) > \(UInt16.max)")
                assertionFailure("SocPingEcho.getDatagram: sum:\(sum) > \(UInt16.max)")
                throw SocPingError.InternalError
            }
            self.icmpHdr.icmp_cksum = ~UInt16(sum)
            SocLogger.debug("SocPingEcho.getDatagram: cksum = \(self.cksum)")
        }
        
        if self.proto == IPPROTO_ICMP {
            var icmpHdr = self.icmpHdr
            let data = Data(bytes: &icmpHdr, count: ICMP_HDRLEN)
            let bytes = data.uint8array!
            SocLogger.debug("SocPingEcho.getDatagram: ICMP data created (size: \(ICMP_HDRLEN + self.payloadLen) bytes)")
            return Data(_: bytes + self.payloadData.prefix(self.payloadLen))
        }
        else {
            SocLogger.debug("SocPingEcho.getDatagram: UDP data created (size: \(self.payloadLen) bytes)")
            return Data(_: self.payloadData.prefix(self.payloadLen))
        }
    }
}
