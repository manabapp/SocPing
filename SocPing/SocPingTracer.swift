//
//  SocPingTracer.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//  Changed by Hirose Manabu on 2021/02/12. (version 1.1)
//

import SwiftUI

struct SocPingTracer: View {
    @EnvironmentObject var object: SocPingSharedObject
    var address: SocAddress
    @State private var text: String = ""
    @State private var isInterrupted: Bool = false
    @State private var alertTitle: String = "Unexpected error."
    @State private var alertMessage: String = ""
    @State private var isPopAlert: Bool = false
    
    @State private var cntSent: Int = 0                  // sequence # for outbound packets = #sent
    @State private var cntReceived: Int = 0              // # of packets we got back
    @State private var progress: Double = 0.0
    @State private var progressTotal: Double = 100.0     // Initializes in reset(), so not use the value
    
    static let waittimeDefault = 5000   // msec
    static let payloadSizeDefault = 24  // Standard size for common traceroute command for UDP
    static let probesDefault: Int = 3   //
    static let pauseMax: Int = 1000     //
    static let ttlDefault = 64          //

    static let unreachLabels = [
        (ICMP_UNREACH_NET, " !N"),
        (ICMP_UNREACH_HOST, " !H"),
        (ICMP_UNREACH_SRCFAIL, " !S"),
        (ICMP_UNREACH_NET_UNKNOWN, " !U"),
        (ICMP_UNREACH_HOST_UNKNOWN, " !W"),
        (ICMP_UNREACH_ISOLATED, " !I"),
        (ICMP_UNREACH_NET_PROHIB, " !A"),
        (ICMP_UNREACH_HOST_PROHIB, " !Z"),
        (ICMP_UNREACH_TOSNET, " !Q"),
        (ICMP_UNREACH_TOSHOST, " !T"),
        (ICMP_UNREACH_FILTER_PROHIB, " !X"),
        (ICMP_UNREACH_HOST_PRECEDENCE, " !V"),
        (ICMP_UNREACH_PRECEDENCE_CUTOFF, " !C")
    ]
    
    var isInProgress: Bool {
        return self.object.isProcessing && self.object.runningActionType == SocPingEcho.actionTypeTraceroute
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
                        self.alertMessage = SocPingEcho.actionNames[self.object.runningActionType] + " in progress"
                        self.isPopAlert = true
                        return
                    }
                    SocLogger.debug("SocPingTracer: Button: Start")
                    self.reset()
                    
                    //==============================================================
                    // Preparate Echo instance
                    //==============================================================
                    var echo = SocPingEcho(proto: object.traceSettingIpProto, address: self.address)
                    
                    //==============================================================
                    // Create sockets
                    //==============================================================
                    var socket: SocSocket
                    var udpSocket: SocSocket
                    do {
                        socket = try SocSocket(family: AF_INET, type: SOCK_DGRAM, proto: IPPROTO_ICMP)
                        udpSocket = try SocSocket(family: AF_INET, type: SOCK_DGRAM, proto: IPPROTO_UDP)  // No use in ICMP
                        SocLogger.debug("SocPingTracer: Socket FDs (ICMP:\(socket.fd), UDP:\(udpSocket.fd))")
                    }
                    catch let error as SocError {
                        self.alertTitle = error.message
                        self.alertMessage = error.detail
                        self.isPopAlert = true
                        return
                    }
                    catch {
                        SocLogger.error("SocPingTracer: \(error)")
                        assertionFailure("SocPingTracer: \(error)")
                        self.isPopAlert = true
                        return
                    }
                    
                    self.object.isProcessing = true
                    self.object.runningActionType = SocPingEcho.actionTypeTraceroute
                    self.isInterrupted = false
                    
                    DispatchQueue.global().async {
                        do {
                            self.setEchoParam(echo: &echo)
                            
                            var msg = "traceroute to "
                            msg += self.address.hostName.isEmpty ? self.address.addr : self.address.hostName
                            msg += " (\(self.address.addr))"
                            if object.traceSettingUseSrcIf {
                                if object.interfaces[object.traceSettingInterface].isActive {
                                    msg += " from \(object.interfaces[object.traceSettingInterface].inet.addr)"
                                }
                            }
                            msg += ", \(object.traceSettingTtlMax) hops max, "
                            msg += "\(echo.payloadLen) byte packets"
                            self.outputAsync(msg)
                            
                            try self.setSocketOption(echo: echo, socket: socket, udpSocket: udpSocket)
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
                            SocLogger.error("SocPingTracer: \(error)")
                            assertionFailure("SocPingTracer: \(error)")
                            self.isPopAlert = true
                        }
                        DispatchQueue.main.async {
                            try! socket.close()
                            try! udpSocket.close()
                            self.object.isProcessing = false
                            SocLogger.debug("SocPingTracer: isProcessing = \(self.object.isProcessing)")
                            if self.isInterrupted {
                                self.isInterrupted = false
                                SocLogger.debug("SocPingTracer: isInterrupted = \(self.isInterrupted)")
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
    
    func setEchoParam(echo: inout SocPingEcho) {
        SocLogger.debug("SocPingPinger.setEchoParam: start")
        if echo.proto == IPPROTO_ICMP {
            echo.setId(UInt16(getpid() & 0xFFFF))
            echo.setSeq(0)
        }
        else {  // UDP
            switch object.traceSettingPortType {
            case SocPingEcho.valueTypeUserSet:
                echo.setPort(UInt16(object.traceSettingUdpPort))
            case SocPingEcho.valueTypeRandom:
                echo.isPortRandom = true
                echo.setPort(UInt16.random(in: UInt16(SocPingEcho.portRangeStart) ... .max))
            default:  // SocPingEcho.valueTypeDefault
                echo.setPort(UInt16(SocPingEcho.tracePortDefault))
            }
        }
        switch object.traceSettingPayloadSizeType {
        case SocPingEcho.valueTypeUserSet:
            echo.setPayload(type: object.traceSettingPayloadDataType,
                            length: object.traceSettingPayloadSize)
        default:  // SocPingEcho.valueTypeDefault:
            echo.setPayload(type: object.traceSettingPayloadDataType,
                            length: SocPingTracer.payloadSizeDefault)
        }
        SocLogger.debug("SocPingTracer.setEchoParam: done")
    }

    func setSocketOption(echo: SocPingEcho, socket: SocSocket, udpSocket: SocSocket) throws {
        SocLogger.debug("SocPingTracer.setSocketOption: start")
        try socket.setsockopt(level: SOL_SOCKET, option: SO_RCVBUF, value: SocOptval(int: Int(IP_MAXPACKET) + 128))
        if object.traceSettingDontroute {
            if echo.proto == IPPROTO_ICMP {
                try socket.setsockopt(level: SOL_SOCKET, option: SO_DONTROUTE, value: SocOptval(bool: true))
            }
            else {
                try udpSocket.setsockopt(level: SOL_SOCKET, option: SO_DONTROUTE, value: SocOptval(bool: true))
            }
        }
        if object.traceSettingUseTos {
            if echo.proto == IPPROTO_ICMP {
                try socket.setsockopt(level: IPPROTO_IP, option: IP_TOS, value: SocOptval(int: object.traceSettingTos))
            }
            else {
                try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_TOS, value: SocOptval(int: object.traceSettingTos))
            }
        }
        if object.traceSettingUseSrcIf {
            let interface = object.interfaces[object.oneSettingInterface]
            guard interface.isActive else {
                SocLogger.debug("SocPingTracer.preset: device(\(object.traceSettingInterface)) not found or address not assigned")
                throw SocPingError.DeviceNotAvail
            }
            try socket.setsockopt(level: IPPROTO_IP, option: IP_BOUND_IF, value: SocOptval(int: interface.index))
            if echo.proto == IPPROTO_UDP {
                try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_BOUND_IF, value: SocOptval(int: interface.index))
            }
        }
        if object.traceSettingUseLsrr {
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
        }
        SocLogger.debug("SocPingTracer.setSocketOption: done")
    }
    
    func action(echo: inout SocPingEcho, socket: SocSocket, udpSocket: SocSocket) throws {
        SocLogger.debug("SocPingTracer.action: start")
        let intervalUSec = object.traceSettingPause * 1000
        let waitSec = Double(object.traceSettingWaittime) / 1000.0
        
        loop: for ttl in object.traceSettingTtlFirst ... object.traceSettingTtlMax {
            var lastAddr: String = ""
            var hasLastAddr: Bool = false
            var isReached: Bool = false
            var unreachCount: Int = 0
            
            let msg = String(format: "%2d ", ttl)
            self.writeAsync(msg)
            for count in 0 ..< object.traceSettingProbes {
                if self.isInterrupted {
                    break loop
                }
                
                if count > 0 && intervalUSec > 0 {
                    SocLogger.debug("SocPingTracer.action: usleep(\(intervalUSec))")
                    usleep(UInt32(intervalUSec));
                }
                
                //==============================================================
                // Send probe
                //==============================================================
                let sent: Int
                echo.incr()  // increments seq/port
                let datagram = try echo.getDatagram()
                let sendDate = Date()
                if echo.proto == IPPROTO_ICMP {
                    try socket.setsockopt(level: IPPROTO_IP, option: IP_TTL, value: SocOptval(int: ttl))
                    sent = try socket.sendto(data: datagram, flags: 0, address: echo.address)
                }
                else {
                    try udpSocket.setsockopt(level: IPPROTO_IP, option: IP_TTL, value: SocOptval(int: ttl))
                    sent = try udpSocket.sendto(data: datagram, flags: 0, address: echo.address)
                }
                self.cntSent += 1
                self.progressAsync(self.cntSent)
                SocLogger.debug("SocPingTracer.action: \(sent != datagram.count ? "partial" : "probe") sent (\(sent) bytes)")
                
                while true {
                    //======================================================
                    // Wait for reply (Polling)
                    //======================================================
                    var revents: Int32 = 0
                    var timeoutSec = waitSec - Date().timeIntervalSince(sendDate)
                    if timeoutSec < 0 {
                        timeoutSec = 0.001
                    }
                    do {
                        revents = try socket.poll(events: POLLIN, timeout: Int32(timeoutSec * 1000))
                    }
                    catch let error as SocError {  // Poll: Error
                        if error.code == EINTR {
                            SocLogger.error("SocPingTracer.action: poll() = -1 Err#\(EINTR) EINTR")
                            continue
                        }
                        throw error
                    }
                    catch {
                        throw error
                    }
                    if revents == 0 {  // Poll: Timeout
                        SocLogger.debug("SocPingTracer.action: poll() timed out")
                        if self.isInterrupted {
                            break loop
                        }
                        self.writeAsync(" *")
                        break
                    }
                    SocLogger.debug("SocPingTracer.action: poll() done - \(SocLogger.getEventsMask(revents))")
                    if revents & POLLIN == 0 {  // should be POLLERR, POLLHUP, POLLNVAL. we unexpect POLLPRI or POLLOUT
                        SocLogger.error("SocPingTracer.action: poll() another event (maybe error occurred)")
                        throw SocPingError.UnexpectedRevents(events: revents)
                    }
                    
                    //======================================================
                    // Receive reply
                    //======================================================
                    var data = Data([UInt8](repeating: 0, count: 65536))  // Maximum size of IPv4 packet (IP_MAXPACKET) is 65535
                    var (received, from) = try socket.recvfrom(data: &data, flags: 0, needAddress: true)
                    let rtt = Date().timeIntervalSince(sendDate)
                    SocLogger.debug("SocPingTracer.action: \(received) bytes received")
                    if from == nil {
                        SocLogger.error("SocPingTracer.action: no from address")
                        continue  // no reachable
                    }
                    let ipHdrLen = (received > 0) ? SocPingEcho.getIpHdrLen(base: data, offset: 0) : 0
                    if received < ipHdrLen + ICMP_HDRLEN {
                        self.outputAsync("packet too short (\(received) bytes) from \(from!.addr))")
                        SocLogger.debug("SocPingTracer.action: packet too short")
                        continue
                    }
                    let ipHdr = SocPingEcho.getIpHdr(base: data, offset: 0)
                    let icmpHdr = SocPingEcho.getIcmpHdr(base: data, offset: ipHdrLen)
                    if echo.proto == IPPROTO_ICMP && icmpHdr.icmp_type == ICMP_ECHOREPLY {
                        if icmpHdr.icmp_id != echo.id || icmpHdr.icmp_seq != echo.seq {
                            SocLogger.debug("SocPingTracer.action: unexpected echo reply (ICMP Id: \(icmpHdr.icmp_id), Seq: \(icmpHdr.icmp_seq))")
                            continue
                        }
                    }
                    else if (icmpHdr.icmp_type == ICMP_TIMXCEED && icmpHdr.icmp_code == ICMP_TIMXCEED_INTRANS) || icmpHdr.icmp_type == ICMP_UNREACH {
                        let ipHdrLen2 = (received > ipHdrLen + ICMP_HDRLEN) ? SocPingEcho.getIpHdrLen(base: data, offset: ipHdrLen + ICMP_HDRLEN) : 0
                        let protoHdrLen = echo.proto == IPPROTO_ICMP ? ICMP_HDRLEN : UDP_HDRLEN
                        if received < ipHdrLen + ICMP_HDRLEN + ipHdrLen2 + protoHdrLen {
                            SocLogger.debug("SocPingTracer.action: \(icmpHdr.typeMessage) - including IP packet too short")
                            continue
                        }
                        let ipHdr2 = SocPingEcho.getIpHdr(base: data, offset: ipHdrLen + ICMP_HDRLEN)
                        // No check IP address(ipHdr2.dstAddr) because it may be change with Loose Source Routing
                        if ipHdr2.ip_p != echo.proto {
                            SocLogger.debug("SocPingTracer.action: \(icmpHdr.typeMessage) - unexpected echo packet (IP Proto: \(ipHdr2.ip_p))")
                            continue
                        }
                        if ipHdr2.ip_p == IPPROTO_ICMP {
                            let icmpHdr2 = SocPingEcho.getIcmpHdr(base: data, offset: ipHdrLen + ICMP_HDRLEN + ipHdrLen2)
                            if icmpHdr2.icmp_type != ICMP_ECHO {
                                SocLogger.debug("SocPingTracer.action: \(icmpHdr.typeMessage) - unexpected echo packet (ICMP Type: \(icmpHdr2.icmp_type))")
                                continue
                            }
                            if icmpHdr2.icmp_id != echo.id {
                                SocLogger.debug("SocPingTracer.action: \(icmpHdr.typeMessage) - unexpected echo packet (ICMP Id: \(icmpHdr2.icmp_id))")
                                continue
                            }
                            if icmpHdr2.icmp_seq != echo.seq {
                                SocLogger.debug("SocPingTracer.action: \(icmpHdr.typeMessage) - unexpected echo packet (ICMP Seq: \(icmpHdr2.icmp_seq))")
                                continue
                            }
                        }
                        else {
                            let udpHdr2 = SocPingEcho.getUdpHdr(base: data, offset: ipHdrLen + ICMP_HDRLEN + ipHdrLen2)
                            if udpHdr2.uh_dport != echo.port {
                                SocLogger.debug("SocPingTracer.action: \(icmpHdr.typeMessage) - unexpected echo packet (UDP Port: \(udpHdr2.uh_dport))")
                                continue
                            }
                        }
                    }
                    else {
                        SocLogger.debug("SocPingTracer.action: \(icmpHdr.typeMessage) - unexpected packet (\(icmpHdr))")
                        continue
                    }
                    self.cntReceived += 1
                    
                    if !hasLastAddr || from!.addr != lastAddr {
                        if hasLastAddr {
                            self.outputAsync()  // blank
                            self.writeAsync("   ")
                        }
                        if object.traceSettingNameResolved {
                            try from!.resolveHostName()
                            self.writeAsync(" \(from!.hostName.isEmpty ? from!.addr : from!.hostName) (\(from!.addr))");
                        }
                        else {
                            self.writeAsync(" \(from!.addr)");
                        }
                        lastAddr = from!.addr
                        hasLastAddr = true
                    }
                    let rttString: String
                    switch rtt {
                    case 0.0 ..< 0.01:
                        rttString = String(format: "  %.3f ms", rtt)
                    case 0.01 ..< 0.1:
                        rttString = String(format: "  %.2f ms", rtt)
                    case 0.1 ..< 1.0:
                        rttString = String(format: "  %.1f ms", rtt)
                    default:
                        rttString = String(format: "  %.0f ms", rtt)
                    }
                    self.writeAsync(rttString)
                    if echo.proto == IPPROTO_ICMP && icmpHdr.icmp_type == ICMP_ECHOREPLY {
                        if ipHdr.ip_ttl <= 1 {
                            self.writeAsync(" !")
                        }
                        isReached = true
                        SocLogger.debug("SocPingTracer.action: \(from!.addr) -> \(rttString) \(icmpHdr.typeMessage):\(ipHdr.ip_ttl)")
                        break
                    }
                    if icmpHdr.icmp_type == ICMP_TIMXCEED {
                        SocLogger.debug("SocPingTracer.action: \(from!.addr) -> \(rttString) \(icmpHdr.codeMessage)")
                        break
                    }
                    // icmpHdr.icmpType == ICMP_UNREACH
                    switch Int32(icmpHdr.icmp_code) {
                    case ICMP_UNREACH_PORT:
                        if ipHdr.ip_ttl <= 1 {
                            self.writeAsync(" !")
                        }
                        isReached = true
                        SocLogger.debug("SocPingTracer.action: \(from!.addr) -> \(rttString) \(icmpHdr.codeMessage):\(ipHdr.ip_ttl)")
                    case ICMP_UNREACH_PROTOCOL:
                        self.writeAsync(" !P")
                        isReached = true
                        SocLogger.debug("SocPingTracer.action: \(from!.addr) -> \(rttString) \(icmpHdr.codeMessage)")
                    default:
                        if icmpHdr.icmp_code == ICMP_UNREACH_NEEDFRAG {
                            self.writeAsync(" !F-\(icmpHdr.icmp_nextmtu)")
                        }
                        else {
                            var label = " !<\(icmpHdr.icmp_code)>"
                            for i in 0 ..< SocPingTracer.unreachLabels.count {
                                if SocPingTracer.unreachLabels[i].0 == icmpHdr.icmp_code {
                                    label = SocPingTracer.unreachLabels[i].1
                                    break
                                }
                            }
                            self.writeAsync(label)
                        }
                        unreachCount += 1
                        SocLogger.debug("SocPingTracer.action: \(from!.addr) -> \(rttString) \(icmpHdr.codeMessage)")
                    }
                    break
                }
            }
            self.outputAsync()
            if isReached || (unreachCount > 0 && unreachCount > object.traceSettingProbes - 1) {
//                self.progress = self.progressTotal  // Progress completed
                self.progressAsync()  // Progress completed
                SocLogger.debug("SocPingTracer.action: reached")
                break
            }
        }
        if self.isInterrupted {
            self.outputAsync(" Terminated")  // Only Traceroute, inserts blank 
        }
        SocLogger.debug("SocPingTracer.action: \(self.isInterrupted ? "interrupted" : "normal end")")
    }
    
    func reset() {
        self.text = ""
        self.cntSent = 0
        self.cntReceived = 0
        self.progress = 0.0
        self.progressTotal = Double(object.traceSettingTtlMax * object.traceSettingProbes)
    }
    
    func progressAsync(_ progress: Int = 0) {
        DispatchQueue.main.async {
            self.progress = progress == 0 ? self.progressTotal : Double(progress)
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
    
    func writeAsync(_ msg: String = "") {
        DispatchQueue.main.async {
            self.text += msg
        }
    }
}
