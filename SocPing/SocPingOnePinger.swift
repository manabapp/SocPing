//
//  SocPingOnePinger.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import SwiftUI
import Darwin

struct SocPingOnePinger: View {
    @EnvironmentObject var object: SocPingSharedObject
    var address: SocAddress
    @State private var text: String = ""
    @State private var isInterrupted: Bool = false
    @State private var alertTitle: String = "Unexpected error."
    @State private var alertMessage: String = ""
    @State private var isPopAlert: Bool = false
    
    @State private var cntSent: Int = 0               // counter of outbound packets
    @State private var cntReceived: Int = 0           // counter of inbound packets we got back
    @State private var progress: Double = 0.0         // action progress
    @State private var progressTotal: Double = 100.0  // reset in reset() later (this value not use)
    
    static let waittimeDefault = 10000   // Standard period for common ping command (msec)
    static let payloadSizeDefault = 56   // Standard size for common ping command
    static let ttlDefault = 64          // Standard value for common ping command
    
    var isInProgress: Bool {
        return self.object.isProcessing && self.object.runningActionType == SocPingList.actionTypeOnePing
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: self.progress, total: self.progressTotal)
            
            SocPingScreen(text: self.$text)
                .frame(maxHeight: .infinity)
            
            Form {
                Button(action: {
                    if self.isInProgress {
                        SocLogger.debug("SocPingOnePinger: Button: Stop")
                        self.isInterrupted = true
                        return
                    }
                    if self.object.isProcessing {
                        self.alertTitle = NSLocalizedString("Message_Multiple_actions_not_possible", comment: "")
                        self.alertMessage = SocPingList.actionNames[self.object.runningActionType] + " in progress"
                        self.isPopAlert = true
                        return
                    }
                    SocLogger.debug("SocPingOnePinger: Button: Start")
                    self.reset()
                    
                    //==============================================================
                    // Preparate Echo instance
                    //==============================================================
                    var echo = SocPingEcho(proto: object.oneSettingIpProto, address: self.address)
                    
                    //==============================================================
                    // Create sockets
                    //==============================================================
                    var socket: SocSocket
                    var udpSocket: SocSocket
                    do {
                        socket = try SocSocket(family: AF_INET, type: SOCK_DGRAM, proto: IPPROTO_ICMP)
                        udpSocket = try SocSocket(family: AF_INET, type: SOCK_DGRAM, proto: IPPROTO_UDP)  // No use in ICMP
                        SocLogger.debug("SocPingOnePinger: Socket FDs (ICMP:\(socket.fd), UDP:\(udpSocket.fd))")
                    }
                    catch let error as SocError {
                        self.alertTitle = error.message
                        self.alertMessage = error.detail
                        self.isPopAlert = true
                        return
                    }
                    catch {
                        SocLogger.error("SocPingOnePinger: \(error)")
                        assertionFailure("SocPingOnePinger: \(error)")
                        self.isPopAlert = true
                        return
                    }

                    self.object.isProcessing = true
                    self.object.runningActionType = SocPingList.actionTypeOnePing
                    self.isInterrupted = false
                    
                    DispatchQueue.global().async {
                        do {
                            try self.preset(echo: &echo, socket: socket, udpSocket: udpSocket)
                            
                            var msg = "PING "
                            msg += self.address.hostName.isEmpty ? self.address.addr : self.address.hostName
                            msg += " (\(self.address.addr)): "
                            msg += "\(echo.payloadLen) data bytes"
                            self.outputAsync(msg)
                            
                            try self.action(echo: &echo, socket: socket, udpSocket: udpSocket)
                        }
                        catch let error as SocError {
                            self.alertTitle = error.message
                            self.alertMessage = error.detail
                            self.isPopAlert = true
                        }
                        catch let error as SocPingError {
                            self.alertTitle = error.message
                            self.alertMessage = ""
                            self.isPopAlert = true
                        }
                        catch {
                            SocLogger.error("SocPingOnePinger: \(error)")
                            assertionFailure("SocPingOnePinger: \(error)")
                            self.isPopAlert = true
                        }
                        DispatchQueue.main.async {
                            try! socket.close()
                            try! udpSocket.close()
                            self.object.isProcessing = false
                            SocLogger.debug("SocPingOnePinger: isProcessing = \(self.object.isProcessing)")
                            if self.isInterrupted {
                                self.isInterrupted = false
                                SocLogger.debug("SocPingOnePinger: isInterrupted = \(self.isInterrupted)")
                            }
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: self.isInProgress ? "stop.fill" : "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 19, height: 19, alignment: .center)
                        Text(self.isInProgress ? "Button_Stop" : "Button_Start")
                            .padding(.leading, 10)
                            .padding(.trailing, 20)
                        Spacer()
                    }
                }
                .alert(isPresented: self.$isPopAlert) {
                    Alert(title: Text(self.alertTitle), message: Text(self.alertMessage))
                }
            }
            .listStyle(PlainListStyle())
            .frame(height: 110)
        }
        .navigationBarTitle(Text(address.addr), displayMode: .inline)
        .navigationBarBackButtonHidden(self.isInProgress)
    }
    
    func preset(echo: inout SocPingEcho, socket: SocSocket, udpSocket: SocSocket) throws {
        SocLogger.debug("SocPingOnePinger.preset: start")
        //==============================================================
        // Setting echo parameters
        //==============================================================
        if echo.proto == IPPROTO_ICMP {
            switch object.oneSettingIdType {
            case SocPingEcho.valueTypeUserSet:
                echo.setId(UInt16(object.oneSettingIcmpId))
            case SocPingEcho.valueTypeRandom:
                echo.setId(UInt16.random(in: 0 ... .max))
            default:  // SocPingEcho.valueTypeDefault
                echo.setId(UInt16(getpid() & 0xFFFF))
            }
            switch object.oneSettingSeqType {
            case SocPingEcho.valueTypeUserSet:
                echo.setSeq(UInt16(object.oneSettingIcmpSeq))
            case SocPingEcho.valueTypeRandom:
                echo.isSeqRandom = true
                echo.setSeq(UInt16.random(in: 0 ... .max))
            default:  // SocPingEcho.valueTypeDefault
                echo.setSeq(0)
            }
        }
        else {  // UDP
            switch object.oneSettingPortType {
            case SocPingEcho.valueTypeUserSet:
                echo.setPort(UInt16(object.oneSettingUdpPort))
            case SocPingEcho.valueTypeRandom:
                echo.isPortRandom = true
                echo.setPort(UInt16.random(in: UInt16(SocPingEcho.portRangeStart) ... .max))
            default:  // SocPingEcho.valueTypeDefault
                echo.setPort(UInt16(SocPingEcho.pingPortDefault))
            }
        }
        switch object.oneSettingPayloadSizeType {
        case SocPingEcho.valueTypeUserSet:
            echo.setPayload(type: object.oneSettingPayloadDataType,
                            length: object.oneSettingPayloadSize)
        default:  // SocPingEcho.valueTypeDefault
            echo.setPayload(type: object.oneSettingPayloadDataType,
                            length: SocPingOnePinger.payloadSizeDefault)
        }
        
        //==============================================================
        // Setting socket options
        //==============================================================
        try socket.setsockopt(level: SOL_SOCKET, option: SO_RCVBUF, value: SocOptval(int: Int(IP_MAXPACKET) + 128))
        try socket.setsockopt(level: SOL_SOCKET, option: SO_TIMESTAMP, value: SocOptval(bool: true))
        
        if echo.isBroadcast {
            if echo.proto == IPPROTO_ICMP {
                try socket.setsockopt(level: SOL_SOCKET, option: SO_BROADCAST, value: SocOptval(bool: true))
            }
            else {
                try udpSocket.setsockopt(level: SOL_SOCKET, option: SO_BROADCAST, value: SocOptval(bool: true))
            }
        }
        if object.oneSettingDontroute {
            if echo.proto == IPPROTO_ICMP {
                try socket.setsockopt(level: SOL_SOCKET, option: SO_DONTROUTE, value: SocOptval(bool: true))
            }
            else {
                try udpSocket.setsockopt(level: SOL_SOCKET, option: SO_DONTROUTE, value: SocOptval(bool: true))
            }
        }
        if object.oneSettingNoLoop {
            if echo.isMulticast {
                try socket.setsockopt(level: IPPROTO_IP, option: IP_MULTICAST_LOOP, value: SocOptval(bool: false))
                if echo.proto == IPPROTO_UDP {
                    try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_MULTICAST_LOOP, value: SocOptval(bool: false))
                }
            }
        }
        if object.oneSettingUseTos {
            if echo.proto == IPPROTO_ICMP {
                try socket.setsockopt(level: IPPROTO_IP, option: IP_TOS, value: SocOptval(int: object.oneSettingTos))
            }
            else {
                try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_TOS, value: SocOptval(int: object.oneSettingTos))
            }
        }
        if object.oneSettingUseTtl {
            if echo.isMulticast {
                if echo.proto == IPPROTO_ICMP {
                    try socket.setsockopt(level: IPPROTO_IP, option: IP_MULTICAST_TTL, value: SocOptval(int: object.oneSettingTtl))
                }
                else {
                    try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_MULTICAST_TTL, value: SocOptval(int: object.oneSettingTtl))
                }
            }
            else {
                if echo.proto == IPPROTO_ICMP {
                    try socket.setsockopt(level: IPPROTO_IP, option: IP_TTL, value: SocOptval(int: object.oneSettingTtl))
                }
                else {
                    try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_TTL, value: SocOptval(int: object.oneSettingTtl))
                }
            }
        }
        if object.oneSettingUseSrcIf {
            let interface = object.interfaces[object.oneSettingInterface]
            guard interface.isActive else {
                SocLogger.debug("SocPingOnePinger.preset: device(\(object.oneSettingInterface)) not found or address not assigned")
                throw SocPingError.DeviceNotAvail
            }
            if echo.isMulticast {
                try socket.setsockopt(level: IPPROTO_IP, option: IP_MULTICAST_IF, value: SocOptval(addr: interface.inet.addr))
                if echo.proto == IPPROTO_UDP {
                    try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_MULTICAST_IF, value: SocOptval(addr: interface.inet.addr))
                }
            }
            else {
                try socket.setsockopt(level: IPPROTO_IP, option: IP_BOUND_IF, value: SocOptval(int: interface.index))
                if echo.proto == IPPROTO_UDP {
                    try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_BOUND_IF, value: SocOptval(int: interface.index))
                }
            }
        }
        if object.oneSettingUseLsrr {
            var array: [in_addr] = []
            for i in 0 ..< object.gateways.count {
                array.append(in_addr(s_addr: inet_addr(object.gateways[i].addr)))
            }
            array.append(in_addr(s_addr: inet_addr(echo.addr)))
            let inAddrData = Data(bytes: &array, count: 4 * array.count)
            var bytes: [UInt8] = [0,0,0]
            bytes[Int(IPOPT_OPTVAL)] = UInt8(IPOPT_LSRR)
            bytes[Int(IPOPT_OLEN)] = UInt8(inAddrData.count + 3)
            bytes[Int(IPOPT_OFFSET)] = UInt8(IPOPT_MINOFF)
            let data: Data? = Data([UInt8(IPOPT_NOP)] + bytes + inAddrData.uint8array!)
            if echo.proto == IPPROTO_ICMP {
                try socket.setsockopt(level: IPPROTO_IP, option: IP_OPTIONS, value: SocOptval(data: data))
            }
            else {
                try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_OPTIONS, value: SocOptval(data: data))
            }
            DispatchQueue.main.async {
                self.output()  // blank
                self.output("IP Option: \(data!.count) bytes set")
                self.dump(base: data!, length: data!.count)
                self.output()  // blank
            }
            printIpOptions(data!)
        }
        if object.oneSettingUseRr {
            var bytes = [UInt8](repeating: 0, count: MAX_IPOPTLEN)
            bytes[Int(IPOPT_OPTVAL)] = UInt8(IPOPT_RR)
            bytes[Int(IPOPT_OLEN)] = UInt8(MAX_IPOPTLEN - 1)
            bytes[Int(IPOPT_OFFSET)] = UInt8(IPOPT_MINOFF)
            bytes[MAX_IPOPTLEN - 1] = UInt8(IPOPT_EOL)
            let data: Data? = Data(bytes)
            if echo.proto == IPPROTO_ICMP {
                try socket.setsockopt(level: IPPROTO_IP, option: IP_OPTIONS, value: SocOptval(data: data))
            }
            else {
                try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_OPTIONS, value: SocOptval(data: data))
            }
            DispatchQueue.main.async {
                self.output()  // blank
                self.output("IP Option: \(data!.count) bytes set")
                self.dump(base: data!, length: data!.count)
                self.output()  // blank
            }
            printIpOptions(data!)
        }
        SocLogger.debug("SocPingOnePinger.preset: done")
    }

    func action(echo: inout SocPingEcho, socket: SocSocket, udpSocket: SocSocket) throws {
        SocLogger.debug("SocPingOnePinger.action: start")
        self.progressAsync(0.01)  // Progress 1 %

        //==============================================================
        // Send echo request
        //==============================================================
        var sendTv = timeval()
        try self.sendEcho(echo: &echo, socket: echo.proto == IPPROTO_ICMP ? socket : udpSocket, sendTv: &sendTv)
        
        let intervalSec: Double = 1.000
        let lastDate = Date()
        while !self.isInterrupted {
            let revents: Int32
            //======================================================
            // Wait for reply (Polling)
            //======================================================
            do {
                revents = try socket.poll(events: POLLIN, timeout: Int32(intervalSec * 1000))
            }
            catch let error as SocError {  // Poll: Error
                if error.code == EINTR {
                    SocLogger.error("SocPingOnePinger.action: poll() = -1 Err#\(EINTR) EINTR")
                    self.outputAsyncVerbose("Polling: retry due to Err#\(EINTR) EINTR")
                    continue
                }
                throw error
            }
            catch {
                throw error
            }
            SocLogger.debug("SocPingOnePinger.action: poll() done - \(SocLogger.getEventsMask(revents))")
            var percent = Date().timeIntervalSince(lastDate) * 1000.0 / Double(object.oneSettingWaittime)
            if percent > 0.9 {
                percent = 0.9
            }
            self.progressAsync(percent)
            
            if revents == 0 {  // Poll: Timeout
                if self.cntReceived >= 1 && (echo.isBroadcast || echo.isMulticast) {
                    SocLogger.debug("SocPingOnePinger.action: no more replies for \(echo.isBroadcast ? "broadcast" : "multicast")")
                    self.outputAsync("no more replies for \(echo.isBroadcast ? "broadcast" : "multicast")")
                    self.progressAsync()  // Progress completed
                    break
                }
                let elapsedMsec = Int(Date().timeIntervalSince(lastDate) * 1000.0)
                self.outputAsyncVerbose("Polling: timed out")
                if elapsedMsec >= object.oneSettingWaittime {
                    if echo.proto == IPPROTO_ICMP {
                        SocLogger.debug("SocPingOnePinger.action: Request timeout for icmp_seq \(echo.seq)")
                        self.outputAsync("Request timeout for icmp_seq \(echo.seq)")
                    }
                    else {
                        SocLogger.debug("SocPingOnePinger.action: Request timeout for udp_dstport \(echo.port)")
                        self.outputAsync("Request timeout for udp_dstport \(echo.port)")
                    }
                    self.progressAsync()  // Progress completed
                    break
                }
                continue
            }
            if revents & POLLIN == 0 {
                // should be POLLERR, POLLHUP, POLLNVAL. we unexpect POLLPRI or POLLOUT
                SocLogger.error("SocPingOnePinger.action: maybe error event occurred")
                throw SocPingError.UnexpectedRevents(events: revents)
            }
            if object.oneSettingVerbose {
                DispatchQueue.main.async {
                    self.output("Polling: \(SocLogger.getEventsMask(revents)) (Ready to receive)")
                    self.output()  // blank
                }
            }
            
            //======================================================
            // Receive echo reply
            //======================================================
            try self.recvEchoreply(echo: &echo, socket: socket, sendTv: sendTv)
            if self.cntReceived >= 1 {
                SocLogger.debug("SocPingOnePinger.action: \(self.cntReceived) packets received")
                if !echo.isBroadcast && !echo.isMulticast {
                    self.progressAsync()  // Progress completed
                    break
                }
            }
        }
        if self.isInterrupted {
            self.outputAsync("Terminated")
        }
        SocLogger.debug("SocPingOnePinger.action: \(self.isInterrupted ? "interrupted" : "normal end")")
    }
    
    func sendEcho(echo: inout SocPingEcho, socket: SocSocket, sendTv: inout timeval) throws {
        let datagram = try echo.getDatagram()
        let sent: size_t
        Darwin.gettimeofday(&sendTv, nil)
        SocLogger.debug("SocPingOnePinger.sendEcho: gettimeofday = \(String(format: "%d.%06d", sendTv.tv_sec, sendTv.tv_usec))")
        sent = try socket.sendto(data: datagram, address: echo.address)
        self.cntSent += 1
        if object.oneSettingVerbose {
            DispatchQueue.main.async {
                self.output()  // blank
                if sent == datagram.count {
                    self.output("Echo request: \(sent) bytes sent")
                }
                else {
                    self.output("Echo request: \(sent) bytes sent instead of \(datagram.count) bytes")
                }
                self.dump(base: datagram, length: sent)
                self.output()  // blank
            }
        }
        if sent != datagram.count {
            SocLogger.debug("SocPingOnePinger.sendEcho: partial sent (\(sent) bytes)")
            return
        }
        if echo.proto == IPPROTO_ICMP {
            let icmpHdr = SocPingEcho.getIcmpHdr(base: datagram, offset: 0)
            self.printIcmpHdr(icmpHdr)
            self.outputAsyncVerbose()  // blank
        }
        else {
            self.outputAsyncVerbose(" => UDP DstPort  : \(String(format: "%04x              (%d)", echo.port, echo.port))")
            SocLogger.debug("SocPingOnePinger.sendEcho: UDP port = \(echo.port)")
        }
        self.outputAsyncVerbose(" => Send time    : \(String(format: "%08x %08x (%d.%06d)", sendTv.tv_sec, sendTv.tv_usec, sendTv.tv_sec, sendTv.tv_usec))")
        self.outputAsyncVerbose()  // blank
        SocLogger.debug("SocPingOnePinger.sendEcho: echo sent (\(sent) bytes)")
    }
    
    func recvEchoreply(echo: inout SocPingEcho, socket: SocSocket, sendTv: timeval) throws {
        var recvTv = timeval()
        
        var buffers: [Data] = []
        buffers.append(Data([UInt8](repeating: 0, count: 65536)))  // Maximum size of IPv4 packet (IP_MAXPACKET) is 65535
        var control = Data([UInt8](repeating: 0, count: 28))
        let (received, from, controlLen, _) = try socket.recvmsg(datas: &buffers, control: &control)
        Darwin.gettimeofday(&recvTv, nil)  // Rewrites timestamp gotton from cmsg if  SO_TIMESTAMP is set
        SocLogger.debug("SocPingOnePinger.recvEchoreply: \(received) bytes received")
        SocLogger.debug("SocPingOnePinger.recvEchoreply: gettimeofday = \(String(format: "%d.%06d", recvTv.tv_sec, recvTv.tv_usec))")
        
        let data = buffers[0]
        if object.oneSettingVerbose {
            DispatchQueue.main.async {
                self.output("Echo reply: \(received) bytes received")
                self.dump(base: data, length: received)
                self.output()  // blank
            }
        }
        let ipHdrLen = (received > 0) ? SocPingEcho.getIpHdrLen(base: data, offset: 0) : 0
        var msg = "\(received - ipHdrLen) bytes from "
        if from == nil {
            SocLogger.error("SocPingOnePinger.recvEchoreply: recvmsg() no from address")  // no reachable
            msg += "unknown:"
        }
        else {
            msg += "\(from!.addr):"
        }
        if received < ipHdrLen + ICMP_HDRLEN {
            self.outputAsyncVerbose()  // blank
            self.outputAsync("\(msg) packet too short")
            self.outputAsyncVerbose()  // blank
            SocLogger.debug("SocPingOnePinger.recvEchoreply: packet too short")
            return
        }
        let ipHdr = SocPingEcho.getIpHdr(base: data, offset: 0)
        self.printIpHdr(ipHdr)
        if ipHdrLen > IP_HDRLEN {
            printIpOptions(Data(data[IP_HDRLEN ..< ipHdrLen]))
        }
        let icmpHdr = SocPingEcho.getIcmpHdr(base: data, offset: ipHdrLen)
        self.printIcmpHdr(icmpHdr)
        
        if echo.proto == IPPROTO_ICMP && icmpHdr.icmp_type == ICMP_ECHOREPLY {
            if icmpHdr.icmp_id != echo.id {
                SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.typeMessage) - invalid ICMP id = \(icmpHdr.icmp_id)")
                return
            }
            SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.message)")
        }
        else if echo.proto == IPPROTO_UDP && icmpHdr.icmp_type == ICMP_UNREACH && icmpHdr.icmp_code == ICMP_UNREACH_PORT {
            let ipHdrLen2 = (received > ipHdrLen + ICMP_HDRLEN) ? SocPingEcho.getIpHdrLen(base: data, offset: ipHdrLen + ICMP_HDRLEN) : 0
            if received < ipHdrLen + ICMP_HDRLEN + ipHdrLen2 + UDP_HDRLEN {
                SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.typeMessage) - including IP packet too short")
                return
            }
            let ipHdr2 = SocPingEcho.getIpHdr(base: data, offset: ipHdrLen + ICMP_HDRLEN)
            self.printIpHdr(ipHdr2)
            let udpHdr = SocPingEcho.getUdpHdr(base: data, offset: ipHdrLen + ICMP_HDRLEN + ipHdrLen2)
            self.printUdpHdr(udpHdr)
            if udpHdr.uh_dport != echo.port {
                SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.typeMessage) - invalid UDP port = \(udpHdr.uh_dport)")
                return
            }
            SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.message)")
        }
        else {
            if icmpHdr.hasIpHdr {
                let ipHdrLen2 = (received > ipHdrLen + ICMP_HDRLEN) ? SocPingEcho.getIpHdrLen(base: data, offset: ipHdrLen + ICMP_HDRLEN) : 0
                let protoHdrLen = echo.proto == IPPROTO_ICMP ? ICMP_HDRLEN : UDP_HDRLEN
                if received < ipHdrLen + ICMP_HDRLEN + ipHdrLen2 + protoHdrLen {
                    SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.typeMessage) - including IP packet too short")
                    return
                }
                let ipHdr2 = SocPingEcho.getIpHdr(base: data, offset: ipHdrLen + ICMP_HDRLEN)
                self.printIpHdr(ipHdr2)
                // No check IP address(ipHdr2.dstAddr) because it may be change with Loose Source Routing
                if ipHdr2.ip_p != echo.proto {
                    SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.typeMessage) - unexpected echo packet (IP Proto: \(ipHdr2.ip_p))")
                    return
                }
                if ipHdr2.ip_p == IPPROTO_ICMP {
                    let icmpHdr2 = SocPingEcho.getIcmpHdr(base: data, offset: ipHdrLen + ICMP_HDRLEN + ipHdrLen2)
                    self.printIcmpHdr(icmpHdr2)
                    if icmpHdr2.icmp_type != ICMP_ECHO {
                        SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.typeMessage) - unexpected echo packet (ICMP Type: \(icmpHdr2.icmp_type))")
                        return
                    }
                    if icmpHdr2.icmp_id != echo.id {
                        SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.typeMessage) - unexpected echo packet (ICMP Id: \(icmpHdr2.icmp_id))")
                        return
                    }
                }
                else {
                    let udpHdr2 = SocPingEcho.getUdpHdr(base: data, offset: ipHdrLen + ICMP_HDRLEN + ipHdrLen2)
                    self.printUdpHdr(udpHdr2)
                    if udpHdr2.uh_dport != echo.port {
                        SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.typeMessage) - unexpected echo packet (UDP Port: \(udpHdr2.uh_dport))")
                        return
                    }
                }
                self.outputAsyncVerbose()
                self.outputAsync("\(msg) \(icmpHdr.message)")
            }
            self.cntReceived += 1
            SocLogger.debug("SocPingOnePinger.recvEchoreply: \(icmpHdr.message)")
            return
        }
        self.cntReceived += 1
        var hasCmsgTv = false
        if object.oneSettingVerbose {
            DispatchQueue.main.async {
                self.output()  // blank
                self.output("Control data: \(controlLen) bytes received")
                self.dump(base: control, length: controlLen)
                self.output()  // blank
            }
        }
        let cmsgs = SocCmsg.createCmsgs(control: control, length: controlLen)
        let isPrintIndex = cmsgs.count > 1
        for i in 0 ..< cmsgs.count {
            if isPrintIndex {
                self.outputAsyncVerbose(" Cmsg[\(i)]")
            }
            self.printCmsg(cmsgs[i])
            if cmsgs[i].hdr.cmsg_level == SOL_SOCKET && cmsgs[i].hdr.cmsg_type == SCM_TIMESTAMP {
                recvTv = cmsgs[i].tv
                hasCmsgTv = true
            }
        }
        self.outputAsyncVerbose()  // blank
        if !hasCmsgTv {  // SocPingEcho.respTypeGettimeofday
            self.outputAsyncVerbose(" => Receive time : \(String(format: "%08x %08x (%d.%06d)", sendTv.tv_sec, sendTv.tv_usec, sendTv.tv_sec, sendTv.tv_usec))")
            self.outputAsyncVerbose()  // blank
        }
        
        if echo.proto == IPPROTO_ICMP {
            msg += " icmp_seq=\(icmpHdr.icmp_seq)"
        }
        else {
            msg += " udp_dport=\(echo.port)"
        }
        msg += " ttl=\(ipHdr.ip_ttl)"
        msg += String(format: " time=%.3f ms", SocPingEcho.subRtt(sendTv, recvTv) * 1000.0)
        self.outputAsync(msg)
        self.outputAsyncVerbose()
    }
    
    func reset() {
        self.text = ""
        if object.oneSettingVerbose {
            self.text += SocLogger.dateFormatter.string(from: Date())
            self.text += "\n"
        }
        self.cntSent = 0
        self.cntReceived = 0
        self.progress = 0.0
        self.progressTotal = 1.0
    }
    
    func progressAsync(_ progress: Double = 0.0) {
        DispatchQueue.main.async {
            self.progress = progress == 0.0 ? self.progressTotal : progress
        }
    }
    
    func output(_ msg: String = "") {
        self.text += msg
        self.text += "\n"
    }
    
    func outputAsync(_ msg: String = "") {
        DispatchQueue.main.async {
            self.output(msg)
        }
    }
    
    func outputVerbose(_ msg: String = "") {
        if object.oneSettingVerbose {
            self.output(msg)
        }
    }
    
    func outputAsyncVerbose(_ msg: String = "") {
        if object.oneSettingVerbose {
            self.outputAsync(msg)
        }
    }

    func dump(base: Data, length: Int) {
        var index: Int = 0
        var num: Int = 0
        var dumpString: String = ""
        var detailString: String = ""
        
        if length == 0 {
            return
        }
        let bytes = base.uint8array!
        while index < bytes.count && index < length {
            dumpString = String(format: " %04d:  ", index)
            if index >= SocLogger.dumpMaxSize {
                dumpString += "=== MORE ==="
                self.output(dumpString)
                return
            }
            detailString = "    "
            while index < bytes.count && index < length {
                dumpString += String(format: "%02x", bytes[index])
                detailString += SocPingEcho.printableLetters.contains(bytes[index].char) ? String(format: "%c", bytes[index]) : "."
                index += 1
                if index >= bytes.count || index >= length {
                    break
                }
                if index % 16 == 0 {
                    break
                }
                if index % 8 == 0 {
                    detailString += " "
                }
                if index % 4 == 0 {
                    dumpString += " "
                }
            }
            num = 16 - (index % 16)
            if num > 0 && num < 16 {
                dumpString += String(repeating: " ", count: num * 2 + Int(num / 4))
            }
            dumpString += detailString
            self.output(dumpString)
        }
    }
    
    func printIpHdr(_ ipHdr: ip) {
        if !object.oneSettingVerbose {
            return
        }
        DispatchQueue.main.async {
            var ipProtoName: String = ""
            for i in 0 ..< SocLogger.protocols.count {
                if SocLogger.protocols[i] == ipHdr.ip_p {
                    ipProtoName = SocLogger.protocolNames[i]
                    break
                }
            }
            var offBits: String = "0b"
            offBits += (ipHdr.ip_off & 0x8000) == 0x8000 ? "1" : "0"
            offBits += (ipHdr.ip_off & 0x4000) == 0x4000 ? "1" : "0"
            offBits += (ipHdr.ip_off & 0x2000) == 0x2000 ? "1" : "0"
            var offBitNames: String = ""
            offBitNames += (ipHdr.ip_off & 0x4000) == 0x4000 ? "DF" : "not DF"
            offBitNames += (ipHdr.ip_off & 0x2000) == 0x2000 ? ", MF" : ", not MF"
            self.output(" -> IP Version   : \(String(format: "%1x                 (%d)", ipHdr.ip_v, ipHdr.ip_v))")
            self.output(" -> IP HdrLen    : \(String(format: "%1x << 2            (%d)", ipHdr.ip_hl, ipHdr.ip_hl << 2))")
            self.output(" -> IP ToS       : \(String(format: "%02x                (%d)", ipHdr.ip_tos, ipHdr.ip_tos))")
            self.output(" -> IP TotalLen  : \(String(format: "%04x              (%d)", ipHdr.ip_len, ipHdr.ip_len))")
            self.output(" -> IP ID        : \(String(format: "%04x              (%d)", ipHdr.ip_id, ipHdr.ip_id))")
            self.output(" -> IP Flags     : \(String(format: "%04x & e000 >> 13 ", ipHdr.ip_off))(\(offBits)) \(offBitNames)")
            self.output(" -> IP Offset    : \(String(format: "%04x & 1fff       (%d)", ipHdr.ip_off, ipHdr.ip_off & 0x1fff))")
            self.output(" -> IP TTL       : \(String(format: "%02x                (%d)", ipHdr.ip_ttl, ipHdr.ip_ttl))")
            self.output(" -> IP Protocol  : \(String(format: "%02x                (%d)", ipHdr.ip_p, ipHdr.ip_p)) \(ipProtoName)")
            self.output(" -> IP Cksum     : \(String(format: "%04x              (%d)", ipHdr.ip_sum, ipHdr.ip_sum))")
            self.output(" -> IP Src       : \(String(format: "%08x          ", ipHdr.ip_src.s_addr.bigEndian))(\(String.init(cString: inet_ntoa(ipHdr.ip_src))))")
            self.output(" -> IP Dst       : \(String(format: "%08x          ", ipHdr.ip_dst.s_addr.bigEndian))(\(String.init(cString: inet_ntoa(ipHdr.ip_dst))))")
        }
    }
    
    func printIpOptions(_ options: Data) {
        if !object.oneSettingVerbose {
            return
        }
        DispatchQueue.main.async {
            let bytes = options.uint8array!
            var i = 0
            eol: while i < bytes.count {
                var debugMsg: String = ""
                var optvalName = "Unknown"
                for j in 0 ..< SocLogger.optvals.count {
                    if SocLogger.optvals[j] == bytes[i] {
                        optvalName = SocLogger.optvalNames[j]
                        break
                    }
                }
                self.output(" -> IPOPT Val    : \(String(format: "%02x                (%d)", bytes[i], bytes[i])) \(optvalName)")
                switch Int32(bytes[i]) {
                case IPOPT_EOL:
                    self.output(" -> IPOPT Len    : EOL(\(bytes[i]))");
                    self.output(" -> IPOPT Offset : EOL(\(bytes[i]))");
                    break eol
                case IPOPT_NOP:
                    i += 1
                case IPOPT_LSRR:
                    fallthrough
                case IPOPT_SSRR:
                    fallthrough
                case IPOPT_RR:
                    debugMsg += ": "
                    self.output(" -> IPOPT Len    : \(String(format: "%02x                (%d)", bytes[i + 1], bytes[i + 1]))")
                    self.output(" -> IPOPT Offset : \(String(format: "%02x                (%d)", bytes[i + 2], bytes[i + 2]))")
                    var length = Int(bytes[i + 1])
                    i += 3
                    length -= Int(IPOPT_MINOFF - 1)
                    if length < 4 {
                        i += length
                        break
                    }
                    var cnt = 0
                    while cnt * 4 < length {
                        cnt += 1
                        let inAddr = Data(bytes[i ..< i + 4]).withUnsafeBytes { $0.load(as: in_addr.self) }
                        let addr = String.init(cString: inet_ntoa(inAddr))
                        self.output("         Route(\(cnt)): \(String(format: "%08x          ", inAddr.s_addr.bigEndian))(\(addr))")
                        debugMsg += "\(addr),"
                        i += 4  // size of in_addr
                    }
                default:
                    self.output("    (Unexpected)")
                    break eol
                }
                SocLogger.debug("SocPingOnePinger.printIpOptions: \(debugMsg)")
            }
        }
    }
    
    func printIcmpHdr(_ icmpHdr: icmp) {
        if !object.oneSettingVerbose {
            return
        }
        DispatchQueue.main.async {
            self.output(" -> ICMP Type    : \(String(format: "%02x                (%d)", icmpHdr.icmp_type, icmpHdr.icmp_type)) \(icmpHdr.typeMessage)")
            self.output(" -> ICMP Code    : \(String(format: "%02x                (%d)", icmpHdr.icmp_code, icmpHdr.icmp_code)) \(icmpHdr.codeMessage)")
            self.output(" -> ICMP Cksum   : \(String(format: "%04x              (%d)", icmpHdr.icmp_cksum, icmpHdr.icmp_cksum))")
            
            switch Int32(icmpHdr.icmp_type) {
            case ICMP_ECHOREPLY:
                fallthrough
            case ICMP_ECHO:
                self.output(" -> ICMP ID      : \(String(format: "%04x              (%d)", icmpHdr.icmp_id, icmpHdr.icmp_id))")
                self.output(" -> ICMP Seq     : \(String(format: "%04x              (%d)", icmpHdr.icmp_seq, icmpHdr.icmp_seq))")
            case ICMP_UNREACH:
                if icmpHdr.icmp_code != ICMP_UNREACH_NEEDFRAG {
                    break
                }
                self.output(" -> ICMP NextMtu : \(String(format: "%04x              (%d)", icmpHdr.icmp_nextmtu, icmpHdr.icmp_nextmtu))")
            case ICMP_SOURCEQUENCH:
                fallthrough
            case ICMP_TIMXCEED:
                self.output(" -> ICMP Length  : \(String(format: "%02x                (%d)", icmpHdr.icmp_len, icmpHdr.icmp_len))")
            case ICMP_PARAMPROB:
                self.output(" -> ICMP Pointer : \(String(format: "%02x                (%d)", icmpHdr.icmp_pptr, icmpHdr.icmp_len))")
                self.output(" -> ICMP Length  : \(String(format: "%02x                (%d)", icmpHdr.icmp_len, icmpHdr.icmp_len))")
            case ICMP_REDIRECT:
                self.output(" -> ICMP Gateway : \(String(format: "%08x          ", icmpHdr.icmp_gwaddr.s_addr.bigEndian))(\(String.init(cString: inet_ntoa(icmpHdr.icmp_gwaddr))))")
            case ICMP_ROUTERADVERT:
                self.output(" -> ICMP NumAddrs: \(String(format: "%02x                (%d)", icmpHdr.icmp_num_addrs, icmpHdr.icmp_num_addrs))")
                self.output(" -> ICMP wpa     : \(String(format: "%02x                (%d)", icmpHdr.icmp_wpa, icmpHdr.icmp_wpa))")
                self.output(" -> ICMP Lifetime: \(String(format: "%04x              (%d)", icmpHdr.icmp_lifetime, icmpHdr.icmp_lifetime))")
            default:
                break
            }
        }
    }
    
    func printUdpHdr(_ udpHdr: udphdr) {
        if !object.oneSettingVerbose {
            return
        }
        DispatchQueue.main.async {
            self.output(" -> UDP SrcPort  : \(String(format: "%04x              (%d)", udpHdr.uh_sport, udpHdr.uh_sport))")
            self.output(" -> UDP DstPort  : \(String(format: "%04x              (%d)", udpHdr.uh_dport, udpHdr.uh_dport))")
            self.output(" -> UDP Length   : \(String(format: "%04x              (%d)", udpHdr.uh_ulen, udpHdr.uh_ulen))")
            self.output(" -> UDP Cksum    : \(String(format: "%04x              (%d)", udpHdr.uh_sum, udpHdr.uh_sum))")
        }
    }
    
    func printCmsg(_ cmsg: SocCmsg) {
        if !object.oneSettingVerbose {
            return
        }
        var levelName = String(cmsg.hdr.cmsg_level)
        var typeName = String(cmsg.hdr.cmsg_type)
        var valType = SocCmsg.typeData
        for i in 0 ..< SocCmsg.cmsgLevels.count {
            if SocCmsg.cmsgLevels[i] == cmsg.hdr.cmsg_level {
                levelName = SocCmsg.cmsgLevelNames[i]
                break
            }
        }
        if cmsg.hdr.cmsg_level == SOL_SOCKET {
            for i in 0 ..< SocCmsg.solCmsgTypes.count {
                if SocCmsg.solCmsgTypes[i].0 == cmsg.hdr.cmsg_type {
                    valType = SocCmsg.solCmsgTypes[i].1
                    typeName = SocCmsg.solCmsgTypes[i].2
                    break
                }
            }
        }
        DispatchQueue.main.async {
            self.output(" -> CMSG Length  : \(String(format: "%04x              (%d)", cmsg.hdr.cmsg_len, cmsg.hdr.cmsg_len))")
            self.output(" -> CMSG Level   : \(String(format: "%04x              (%d)", cmsg.hdr.cmsg_level, cmsg.hdr.cmsg_level)) \(levelName)")
            self.output(" -> CMSG Type    : \(String(format: "%04x              (%d)", cmsg.hdr.cmsg_type, cmsg.hdr.cmsg_type)) \(typeName)")
            switch valType {
            case SocCmsg.typeTv:
                let tvString = String(format: "%08x %08x (%d.%06d)", cmsg.tv.tv_sec, cmsg.tv.tv_usec, cmsg.tv.tv_sec, cmsg.tv.tv_usec)
                self.output(" -> CMSG Data    : \(tvString)")
                SocLogger.debug("SocCmsg.printCmsg: Len=\(cmsg.hdr.cmsg_len),Level=\(levelName),Type=\(typeName),Tv=\(tvString)")
            default:
                self.output(" -> CMSG Data    : ")
                self.dump(base: cmsg.data, length: cmsg.data.count)
                SocLogger.debug("SocCmsg.printCmsg: Len=\(cmsg.hdr.cmsg_len),Level=\(levelName),Type=\(typeName),Data=\(cmsg.data.count)bytes")
            }
        }
    }
}
