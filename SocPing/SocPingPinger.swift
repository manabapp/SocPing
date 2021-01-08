//
//  SocPingPinger.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import SwiftUI
import Darwin

struct SocPingPinger: View {
    @EnvironmentObject var object: SocPingSharedObject
    var address: SocAddress
    @State private var text: String = ""
    @State private var text2: String = ""
    @State private var isInterrupted: Bool = false
    @State private var alertTitle: String = "Unexpected error."
    @State private var alertMessage: String = ""
    @State private var isPopAlert: Bool = false
    
    // Statistics
    @State private var echoes: Int = 0
    @State private var cntSent: Int = 0                  // number of outbound packets
    @State private var cntReceived: Int = 0              // number of packets we got back
    @State private var cntDups: Int = 0                  // number of duplicates
    @State private var cntMissedMax: Int = 0             // max value of cntSent - cntReceived - 1
    @State private var cntTimeout: Int = 0               // number of packets we got back after waittime
    @State private var rttMax: Double = 0.0              // Max RTT
    @State private var rttMin: Double = 1000000.0        // Min RTT
    @State private var rttSum: Double = 0.0              //
    @State private var rttSumSquare: Double = 0.0        //
    @State private var progress: Double = 0.0            //
    @State private var progressTotal: Double = 100.0     // Initializes in reset(), so not use the value
    
    static let echoesDefault = 32        // In SE 1gen's, fill in screen height
    static let intervalDefault = 1000    // msec
    static let waittimeDefault = 10000   // msec
    static let payloadSizeDefault = 56   // Standard size for common ping command
    static let dupAccuracy: Int = 1024
    @State var dupTable: [UInt8] = []
    private func setDup(_ i: Int) { dupTable[(i) >> 3] |= UInt8(1 << ((i) & 0x07)) }
    private func clrDup(_ i: Int) { dupTable[(i) >> 3] &= ~UInt8(1 << ((i) & 0x07)) }
    private func chkDup(_ i: Int) -> Bool { return dupTable[(i) >> 3] & UInt8(1 << ((i) & 0x07)) > 0 }
    
    var isInProgress: Bool {
        return self.object.isProcessing && self.object.runningActionType == SocPingEcho.actionTypePing
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: self.progress, total: self.progressTotal)
            
            SocPingScreen(text: self.$text)
                .frame(maxHeight: .infinity)
            
            SocPingScreen(text: self.$text2)
                .frame(height: 60)
            
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
                    SocLogger.debug("SocPingPinger: Button: Start")
                    self.reset()
                    self.dupTable = [UInt8](repeating: 0, count: SocPingPinger.dupAccuracy)  // for monitoring duplicate packets
                    SocLogger.debug("SocPingPinger: init dup table (accuracy = \(SocPingPinger.dupAccuracy))")
                    
                    //==============================================================
                    // Preparate Echo instance
                    //==============================================================
                    var echo = SocPingEcho(proto: IPPROTO_ICMP, address: self.address)
                    
                    //==============================================================
                    // Create sockets
                    //==============================================================
                    var socket: SocSocket
                    do {
                        socket = try SocSocket(family: AF_INET, type: SOCK_DGRAM, proto: IPPROTO_ICMP)
                        SocLogger.debug("SocPingPinger: Socket FD (ICMP:\(socket.fd))")
                    }
                    catch let error as SocError {
                        self.alertTitle = error.message
                        self.alertMessage = error.detail
                        self.isPopAlert = true
                        return
                    }
                    catch {
                        SocLogger.error("SocPingPinger: \(error)")
                        assertionFailure("SocPingPinger: \(error)")
                        self.isPopAlert = true
                        return
                    }
                    
                    self.object.isProcessing = true
                    self.object.runningActionType = SocPingEcho.actionTypePing
                    self.isInterrupted = false
                    
                    DispatchQueue.global().async {
                        do {
                            self.setEchoParam(echo: &echo)
                            
                            var msg = "PING "
                            msg += echo.hostName.isEmpty ? echo.addr : echo.hostName
                            msg += " (\(echo.addr)): "
                            msg += object.isPingSweeping ? "(\(echo.payloadLen) ... \(echo.payloadMaxLen))" : "\(echo.payloadLen)"
                            msg += " data bytes"
                            self.outputAsync(msg)
                            
                            try self.setSocketOption(echo: echo, socket: socket)
                            try self.action(echo: &echo, socket: socket)
                            self.statistics()
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
                            SocLogger.error("SocPingPinger: \(error)")
                            assertionFailure("SocPingPinger: \(error)")
                            self.isPopAlert = true
                        }
                        DispatchQueue.main.async {
                            try! socket.close()
                            self.object.isProcessing = false
                            SocLogger.debug("SocPingPinger: isProcessing = \(self.object.isProcessing)")
                            if self.isInterrupted {
                                self.isInterrupted = false
                                SocLogger.debug("SocPingPinger: isInterrupted = \(self.isInterrupted)")
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
        echo.setId(UInt16(getpid() & 0xFFFF))
        echo.setSeq(0)
        
        switch object.pingSettingPayloadSizeType {
        case SocPingEcho.valueTypeUserSet:
            echo.setPayload(type: object.pingSettingPayloadDataType,
                            length: object.pingSettingPayloadSize,
                            useTv: true)
        case SocPingEcho.valueTypeSweep:
            echo.setPayload(type: object.pingSettingPayloadDataType,
                            length: object.pingSettingSweepingMin,
                            maxLength: object.pingSettingSweepingMax,
                            incr: object.pingSettingSweepingIncr,
                            useTv: true)
        default:  // SocPingEcho.valueTypeDefault:
            echo.setPayload(type: object.pingSettingPayloadDataType,
                            length: SocPingPinger.payloadSizeDefault,
                            useTv: true)
        }
        
        if object.isPingInfinitely {
            self.echoes = 0
        }
        else if object.isPingSweeping {
            self.echoes = object.pingSweepingCount
        }
        else {
            self.echoes = object.pingSettingEchoes
        }
        SocLogger.debug("SocPingPinger.setEchoParam: done")
    }

    func setSocketOption(echo: SocPingEcho, socket: SocSocket) throws {
        SocLogger.debug("SocPingPinger.setSocketOption: start")
        try socket.setsockopt(level: SOL_SOCKET, option: SO_RCVBUF, value: SocOptval(int: Int(IP_MAXPACKET) + 128))
        try socket.setsockopt(level: SOL_SOCKET, option: SO_TIMESTAMP, value: SocOptval(bool: true))
        SocLogger.debug("SocPingPinger.setSocketOption: done")
    }

    func action(echo: inout SocPingEcho, socket: SocSocket) throws {
        SocLogger.debug("SocPingPinger.action: start")
        
        //==============================================================
        // Send echo request
        //==============================================================
        try self.sendEcho(echo: &echo, socket: socket)
        
        var intervalSec = Double(object.pingSettingInterval) / 1000.0
        var timeoutSec: Double = 0.0
        var nowDate = Date()
        var lastDate = Date()
        var revents: Int32 = 0
        var isAllSent: Bool = false
        
        while true {
            //======================================================
            // Wait for reply (Polling)
            //======================================================
            nowDate = Date()
            timeoutSec = intervalSec + lastDate.timeIntervalSince(nowDate)
            if timeoutSec < 0 {
                timeoutSec = 0.0
            }
            do {
                revents = try socket.poll(events: POLLIN, timeout: Int32(timeoutSec * 1000))
            }
            catch let error as SocError {  // Poll: Error
                if error.code == EINTR {
                    SocLogger.error("SocPingPinger.action: poll() = -1 Err#\(EINTR) EINTR")
                    continue
                }
                throw error
            }
            catch {
                throw error
            }
            SocLogger.debug("SocPingPinger.action: poll() done - \(SocLogger.getEventsMask(revents))")
            
            if revents == 0 {  // Poll: Timeout
                SocLogger.debug("SocPingPinger.action: poll() timed out")
                if self.isInterrupted {
                    break
                }
                if self.echoes == 0 || self.cntSent < self.echoes {
                    //==============================================================
                    // Send next echo request
                    //==============================================================
                    try self.sendEcho(echo: &echo, socket: socket)
                }
                else if isAllSent || object.isPingSweeping {
                    SocLogger.debug("SocPingPinger.action: almost done")
                    break
                }
                else {
                    SocLogger.debug("SocPingPinger.action: All \(self.cntSent) packets sent")
                    isAllSent = true  // One more waiting
                    if self.cntReceived > 0 {
                        intervalSec = 2 * self.rttMax
                        if intervalSec < 1.0 {
                            intervalSec = 1.0
                        }
                    }
                    else {
                        intervalSec = Double(object.pingSettingWaittime) / 1000.0
                    }
                }
                lastDate = Date()
                if self.cntSent - self.cntReceived - 1 > self.cntMissedMax {
                    self.cntMissedMax = self.cntSent - self.cntReceived - 1
                    SocLogger.debug("SocPingPinger.action: Request timeout for icmp_seq \(self.cntSent - 2)")
                    self.outputAsync("Request timeout for icmp_seq \(self.cntSent - 2)")
                }
                continue
            }
            if revents & POLLIN == 0 {
                // should be POLLERR, POLLHUP, POLLNVAL. we unexpect POLLPRI or POLLOUT
                SocLogger.error("SocPingPinger.action: poll() another event (maybe error occurred)")
                throw SocPingError.UnexpectedRevents(events: revents)
            }
            
            //======================================================
            // Receive echo reply
            //======================================================
            try self.recvEchoreply(echo: &echo, socket: socket)
            if self.echoes > 0 && self.cntReceived >= self.echoes {
                SocLogger.debug("SocPingPinger.action: All \(self.cntReceived) packets received")
                break
            }
        }
        if self.isInterrupted {
            self.outputAsync("Terminated")
        }
        SocLogger.debug("SocPingPinger.action: \(self.isInterrupted ? "interrupted" : "normal end")")
    }
    
    func sendEcho(echo: inout SocPingEcho, socket: SocSocket) throws {
        echo.incr()  // increments seq/sweep size
        let datagram = try echo.getDatagram()
        self.clrDup(Int(self.cntSent) % SocPingPinger.dupAccuracy)
        let sent = try socket.sendto(data: datagram, address: echo.address)
        self.cntSent += 1
        self.progressAsync()
        SocLogger.debug("SocPingPinger.sendEcho: \(sent != datagram.count ? "partial" : "echo") sent (\(sent) bytes)")
    }
    
    func recvEchoreply(echo: inout SocPingEcho, socket: SocSocket) throws {
        var isDup = false
        var sendTv = timeval()  // Sets timestamp to payload in getDatagram(), and gets it with recvmsg(2)
        var recvTv = timeval()  // Gets just after calling recvmsg(2), and gets timestamp from cmsg with recvmsg depending on setting
        var rtt: Double = 0.0

        var buffers: [Data] = []
        buffers.append(Data([UInt8](repeating: 0, count: 65536)))  // Maximum size of IPv4 packet (IP_MAXPACKET) is 65535
        var control = Data([UInt8](repeating: 0, count: 28))
        let (received, from, controlLen, _) = try socket.recvmsg(datas: &buffers, control: &control)
        Darwin.gettimeofday(&recvTv, nil)
        let data = buffers[0]
        SocLogger.debug("SocPingPinger.recvEchoreply: \(received) bytes received")
        
        let ipHdrLen = (received > 0) ? SocPingEcho.getIpHdrLen(base: data, offset: 0) : 0
        var msg = "\(received - ipHdrLen) bytes from "
        if from == nil {
            SocLogger.error("SocPingPinger.recvEchoreply: recvmsg() no from address")  // no reachable
            msg += "unknown:"
        }
        else {
            msg += "\(from!.addr):"
        }
        if received < ipHdrLen + ICMP_HDRLEN {
            self.outputAsync("\(msg) packet too short")
            SocLogger.debug("SocPingPinger.recvEchoreply: packet too short")
            return
        }
        let ipHdr = SocPingEcho.getIpHdr(base: data, offset: 0)
        let icmpHdr = SocPingEcho.getIcmpHdr(base: data, offset: ipHdrLen)
        if icmpHdr.icmp_type != ICMP_ECHOREPLY {
            if icmpHdr.hasIpHdr {
                let ipHdrLen2 = (received > ipHdrLen + ICMP_HDRLEN) ? SocPingEcho.getIpHdrLen(base: data, offset: ipHdrLen + ICMP_HDRLEN) : 0
                if received < ipHdrLen + ICMP_HDRLEN + ipHdrLen2 + ICMP_HDRLEN {
                    SocLogger.debug("SocPingPinger.recvEchoreply: \(icmpHdr.typeMessage) - including IP packet too short")
                    return
                }
                let ipHdr2 = SocPingEcho.getIpHdr(base: data, offset: ipHdrLen + ICMP_HDRLEN)
                // No check IP address(ipHdr2.dstAddr) because it may be change with Loose Source Routing
                if ipHdr2.ip_p != IPPROTO_ICMP {
                    SocLogger.debug("SocPingPinger.recvEchoreply: \(icmpHdr.typeMessage) - unexpected echo packet (IP Proto: \(ipHdr2.ip_p))")
                    return
                }
                let icmpHdr2 = SocPingEcho.getIcmpHdr(base: data, offset: ipHdrLen + ICMP_HDRLEN + ipHdrLen2)
                if icmpHdr2.icmp_type != ICMP_ECHO {
                    SocLogger.debug("SocPingPinger.recvEchoreply: \(icmpHdr.typeMessage) - unexpected echo packet (ICMP Type: \(icmpHdr2.icmp_type))")
                    return
                }
                if icmpHdr2.icmp_id != echo.id {
                    SocLogger.debug("SocPingPinger.recvEchoreply: \(icmpHdr.typeMessage) - unexpected echo packet (ICMP Id: \(icmpHdr2.icmp_id))")
                    return
                }
                self.outputAsync("\(msg) \(icmpHdr.message)")
            }
            SocLogger.debug("SocPingPinger.recvEchoreply: \(icmpHdr.message)")
            return
        }
        if icmpHdr.icmp_id != echo.id {
            SocLogger.debug("SocPingPinger.recvEchoreply: invalid ICMP id = \(icmpHdr.icmp_id)")
            return
        }
        SocLogger.debug("SocPingPinger.recvEchoreply: \(icmpHdr.message)")
        self.cntReceived += 1
        isDup = self.chkDup(Int(icmpHdr.icmp_seq) % SocPingPinger.dupAccuracy)
        if isDup {
            self.cntDups += 1
            self.cntReceived -= 1
        }
        else {
            self.setDup(Int(icmpHdr.icmp_seq) % SocPingPinger.dupAccuracy)
        }
        
        let cmsgs = SocCmsg.createCmsgs(control: control, length: controlLen)
        for i in 0 ..< cmsgs.count {
            if cmsgs[i].hdr.cmsg_level == SOL_SOCKET && cmsgs[i].hdr.cmsg_type == SCM_TIMESTAMP {
                recvTv = cmsgs[i].tv  // Rewrite
                break
            }
        }
        if received >= ipHdrLen + ICMP_HDRLEN + SocPingEcho.tvLen {
            sendTv = SocPingEcho.getPayloadTv(base: data, offset: ipHdrLen + ICMP_HDRLEN)
            rtt = SocPingEcho.subRtt(sendTv, recvTv)
            self.rttSum += rtt
            self.rttSumSquare += rtt * rtt
            if rtt < self.rttMin {
                self.rttMin = rtt
            }
            if rtt > self.rttMax {
                self.rttMax = rtt
            }
            if Int(rtt * 1000.0) >= object.pingSettingWaittime {
                self.cntTimeout += 1
                self.statistics()
                SocLogger.debug("SocPingPinger.recvEchoreply: timed out - rtt=\(rtt), id=\(icmpHdr.icmp_id)")
                return
            }
        }
        
        msg += " icmp_seq=\(icmpHdr.icmp_seq)"
        msg += " ttl=\(ipHdr.ip_ttl)"
        if rtt > 0 {
            msg += String(format: " time=%.3f ms", rtt * 1000.0)
        }
        if isDup && !echo.isMulticast {
            msg += " (DUP!)"
        }
        self.outputAsync(msg)
        self.statistics()
    }
    
    func statistics() {
        var msg = "--- \(self.address.hostName.isEmpty ? self.address.addr : self.address.hostName) ping statistics ---\n"
        msg += "\(self.cntSent) packets transmitted, "
        msg += "\(self.cntReceived) packets received, "
        if self.cntDups > 0 {
            msg += "+\(self.cntDups) duplicates, "
        }
        if self.cntSent > 0 {
            msg += String(format: "%.1f", Double(self.cntSent - self.cntReceived) * 100.0 / Double(self.cntSent))
            msg += "% packet loss"
        }
        if self.cntTimeout > 0 {
            msg += ", \(self.cntTimeout) packets out of wait time"
        }
        msg += "\n"
        if self.cntReceived > 0 {
            let cntTotalRecvs = self.cntReceived + self.cntDups
            let rttAvg = self.rttSum / Double(cntTotalRecvs)
            let vari = self.rttSumSquare / Double(cntTotalRecvs) - rttAvg * rttAvg
            msg += "round-trip min/avg/max/stddev = "
            msg += String(format: "%.3f/%.3f/%.3f/%.3f", self.rttMin * 1000.0, rttAvg * 1000.0, self.rttMax * 1000.0, sqrt(vari) * 1000.0)
            msg += " ms\n"
        }
        DispatchQueue.main.async {
            self.text2 = msg
        }
    }
    
    func reset() {
        self.text = ""
        self.text2 = ""
        self.cntSent = 0
        self.cntReceived = 0
        self.cntDups = 0
        self.cntMissedMax = 0
        self.cntTimeout = 0
        self.rttMax = 0.0
        self.rttMin = 1000000.0
        self.rttSum = 0.0
        self.rttSumSquare = 0.0
        self.progress = 0.0
        if object.isPingInfinitely {
            self.progressTotal = 100.0  // loop 0 ..< 100
        }
        else if object.isPingSweeping {
            self.progressTotal = Double(object.pingSweepingCount)
        }
        else {
            self.progressTotal = Double(object.pingSettingEchoes)
        }
    }
    
    func progressAsync() {
        DispatchQueue.main.async {
            if object.isPingInfinitely {
                if self.progress < 99.0 {
                    self.progress += 1.0
                }
                else {
                    self.progress = 0.0  // Progress Loop
                }
            }
            else {
                self.progress += 1.0
            }
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
}
