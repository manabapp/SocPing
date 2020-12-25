//
//  SocPingSharedObject.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import SwiftUI

final class SocPingSharedObject: ObservableObject {
    @Published var orientation: UIInterfaceOrientation = .unknown
    @Published var isProcessing: Bool = false
    @Published var runningActionType: Int = SocPingList.actionTypeOnePing
    @Published var deviceWidth: CGFloat = 0.0
    @Published var interfaces = [SocPingInterface(deviceType: SocPingInterface.deviceTypeWifi),
                                 SocPingInterface(deviceType: SocPingInterface.deviceTypeCellurar),
                                 SocPingInterface(deviceType: SocPingInterface.deviceTypeHotspot),
                                 SocPingInterface(deviceType: SocPingInterface.deviceTypeLoopback)]
    @Published var gwOrders = [Int](repeating: 0, count: SocPingAddressManager.maxRegistNumber)
    
    var isPingInfinitely: Bool { return self.pingSettingLoopType == 0 }
    var isPingSweeping: Bool { return self.pingSettingPayloadSizeType == SocPingEcho.valueTypeSweep }
    var pingSweepingCount: Int { return (self.pingSettingSweepingMax - self.pingSettingSweepingMin) / self.pingSettingSweepingIncr + 1 }
    static var isJa: Bool { return Locale.preferredLanguages.first!.hasPrefix("ja") }
    
    //  App's loading parameters are follows.
    //===== Common =====
    @Published var addresses: [SocAddress] = []
    @Published var gateways: [SocAddress] = []
    @Published var isAgreed: Bool = false
    @Published var agreementDate: Date? = nil
    
    @Published var appSettingDescription: Bool = true {
        didSet {
            UserDefaults.standard.set(appSettingDescription, forKey: "appSettingDescription")
            SocLogger.debug("SoctestSharedObject: appSettingDescription = \(appSettingDescription)")
        }
    }
    @Published var appSettingIdleTimerDisabled: Bool = false {
        didSet {
            UserDefaults.standard.set(appSettingIdleTimerDisabled, forKey: "appSettingIdleTimerDisabled")
            UIApplication.shared.isIdleTimerDisabled = appSettingIdleTimerDisabled
            SocLogger.debug("SocPingSharedObject: appSettingIdleTimerDisabled = \(appSettingIdleTimerDisabled)")
            SocLogger.debug("SocPingSharedObject: UIApplication.shared.isIdleTimerDisabled = \(appSettingIdleTimerDisabled)")
        }
    }
    @Published var appSettingScreenColorInverted: Bool = false {
        didSet {
            UserDefaults.standard.set(appSettingScreenColorInverted, forKey: "appSettingScreenColorInverted")
            SocLogger.debug("SocPingSharedObject: appSettingScreenColorInverted = \(appSettingScreenColorInverted)")
        }
    }
    @Published var appSettingTraceLevel: Int = SocLogger.traceLevelCall {
        didSet {
            UserDefaults.standard.set(appSettingTraceLevel, forKey: "appSettingTraceLevel")
            SocLogger.debug("SocPingSharedObject: appSettingTraceLevel = \(appSettingTraceLevel)")
            SocLogger.setTraceLevel(appSettingTraceLevel)
        }
    }
    @Published var appSettingDebugEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(appSettingDebugEnabled, forKey: "appSettingDebugEnabled")
            SocLogger.debug("SoctestSharedObject: appSettingDebugEnabled = \(appSettingDebugEnabled)")
            if appSettingDebugEnabled {
                SocLogger.enableDebug()
            }
            else {
                SocLogger.disableDebug()
            }
        }
    }
    
    //===== One Ping =====
    @Published var oneSettingVerbose: Bool = false {
        didSet {
            UserDefaults.standard.set(oneSettingVerbose, forKey: "oneSettingVerbose")
            SocLogger.debug("SocPingSharedObject: oneSettingVerbose = \(oneSettingVerbose)")
        }
    }
    @Published var oneSettingIpProto: Int32 = IPPROTO_ICMP {  // 0:ICMP, 1:UDP
        didSet {
            UserDefaults.standard.set(Int(oneSettingIpProto), forKey: "oneSettingIpProto")
            SocLogger.debug("SocPingSharedObject: oneSettingIpProto = \(oneSettingIpProto)")
        }
    }
    @Published var oneSettingIdType: Int = SocPingEcho.valueTypeDefault {
        didSet {
            UserDefaults.standard.set(oneSettingIdType, forKey: "oneSettingIdType")
            SocLogger.debug("SocPingSharedObject: oneSettingIdType = \(oneSettingIdType)")
        }
    }
    @Published var oneSettingIcmpId: Int = 0 {
        didSet {
            UserDefaults.standard.set(oneSettingIcmpId, forKey: "oneSettingIcmpId")
            SocLogger.debug("SocPingSharedObject: oneSettingIcmpId = \(oneSettingIcmpId)")
        }
    }
    @Published var oneSettingSeqType: Int = SocPingEcho.valueTypeDefault {
        didSet {
            UserDefaults.standard.set(oneSettingSeqType, forKey: "oneSettingSeqType")
            SocLogger.debug("SocPingSharedObject: oneSettingSeqType = \(oneSettingSeqType)")
        }
    }
    @Published var oneSettingIcmpSeq: Int = 0 {
        didSet {
            UserDefaults.standard.set(oneSettingIcmpSeq, forKey: "oneSettingIcmpSeq")
            SocLogger.debug("SocPingSharedObject: oneSettingIcmpSeq = \(oneSettingIcmpSeq)")
        }
    }
    @Published var oneSettingPortType: Int = SocPingEcho.valueTypeDefault {
        didSet {
            UserDefaults.standard.set(oneSettingPortType, forKey: "oneSettingPortType")
            SocLogger.debug("SocPingSharedObject: oneSettingPortType = \(oneSettingPortType)")
        }
    }
    @Published var oneSettingUdpPort: Int = SocPingEcho.pingPortDefault {
        didSet {
            UserDefaults.standard.set(oneSettingUdpPort, forKey: "oneSettingUdpPort")
            SocLogger.debug("SocPingSharedObject: oneSettingUdpPort = \(oneSettingUdpPort)")
        }
    }
    @Published var oneSettingPayloadDataType: Int = SocPingEcho.payloadTypeC {
        didSet {
            UserDefaults.standard.set(oneSettingPayloadDataType, forKey: "oneSettingPayloadDataType")
            SocLogger.debug("SocPingSharedObject: oneSettingPayloadDataType = \(oneSettingPayloadDataType)")
        }
    }
    @Published var oneSettingPayloadSizeType: Int = SocPingEcho.valueTypeDefault {
        didSet {
            UserDefaults.standard.set(oneSettingPayloadSizeType, forKey: "oneSettingPayloadSizeType")
            SocLogger.debug("SocPingSharedObject: oneSettingPayloadSizeType = \(oneSettingPayloadSizeType)")
        }
    }
    @Published var oneSettingPayloadSize: Int = SocPingOnePinger.payloadSizeDefault {
        didSet {
            UserDefaults.standard.set(oneSettingPayloadSize, forKey: "oneSettingPayloadSize")
            SocLogger.debug("SocPingSharedObject: oneSettingPayloadSize = \(oneSettingPayloadSize)")
        }
    }
    @Published var oneSettingWaittime: Int = SocPingOnePinger.waittimeDefault {
        didSet {
            UserDefaults.standard.set(oneSettingWaittime, forKey: "oneSettingWaittime")
            SocLogger.debug("SocPingSharedObject: oneSettingWaittime = \(oneSettingWaittime)")
        }
    }
    @Published var oneSettingUseTtl: Bool = false {
        didSet {
            UserDefaults.standard.set(oneSettingUseTtl, forKey: "oneSettingUseTtl")
            SocLogger.debug("SocPingSharedObject: oneSettingUseTtl = \(oneSettingUseTtl)")
        }
    }
    @Published var oneSettingTtl: Int = SocPingOnePinger.ttlDefault {
        didSet {
            UserDefaults.standard.set(oneSettingTtl, forKey: "oneSettingTtl")
            SocLogger.debug("SocPingSharedObject: oneSettingTtl = \(oneSettingTtl)")
        }
    }
    @Published var oneSettingUseTos: Bool = false {
        didSet {
            UserDefaults.standard.set(oneSettingUseTos, forKey: "oneSettingUseTos")
            SocLogger.debug("SocPingSharedObject: oneSettingUseTos = \(oneSettingUseTos)")
        }
    }
    @Published var oneSettingTos: Int = 0 {
        didSet {
            UserDefaults.standard.set(oneSettingTos, forKey: "oneSettingTos")
            SocLogger.debug("SocPingSharedObject: oneSettingTos = \(oneSettingTos)")
        }
    }
    @Published var oneSettingDontroute: Bool = false {
        didSet {
            UserDefaults.standard.set(oneSettingDontroute, forKey: "oneSettingDontroute")
            SocLogger.debug("SocPingSharedObject: oneSettingDontroute = \(oneSettingDontroute)")
        }
    }
    @Published var oneSettingNoLoop: Bool = false {
        didSet {
            UserDefaults.standard.set(oneSettingNoLoop, forKey: "oneSettingNoLoop")
            SocLogger.debug("SocPingSharedObject: oneSettingNoLoop = \(oneSettingNoLoop)")
        }
    }
    @Published var oneSettingUseSrcIf: Bool = false {
        didSet {
            UserDefaults.standard.set(oneSettingUseSrcIf, forKey: "oneSettingUseSrcIf")
            SocLogger.debug("SocPingSharedObject: oneSettingUseSrcIf = \(oneSettingUseSrcIf)")
        }
    }
    @Published var oneSettingInterface: Int = SocPingInterface.deviceTypeLoopback {
        didSet {
            UserDefaults.standard.set(oneSettingInterface, forKey: "oneSettingInterface")
            SocLogger.debug("SocPingSharedObject: oneSettingInterface = \(oneSettingInterface)")
        }
    }
    @Published var oneSettingUseLsrr: Bool = false {
        didSet {
            UserDefaults.standard.set(oneSettingUseLsrr, forKey: "oneSettingUseLsrr")
            SocLogger.debug("SocPingSharedObject: oneSettingUseLsrr = \(oneSettingUseLsrr)")
            if oneSettingUseLsrr && oneSettingUseRr {
                oneSettingUseRr = false
                UserDefaults.standard.set(oneSettingUseRr, forKey: "oneSettingUseRr")
                SocLogger.debug("SocPingSharedObject: oneSettingUseRr = \(oneSettingUseRr)")
            }
        }
    }
    @Published var oneSettingUseRr: Bool = false {
        didSet {
            UserDefaults.standard.set(oneSettingUseRr, forKey: "oneSettingUseRr")
            SocLogger.debug("SocPingSharedObject: oneSettingUseRr = \(oneSettingUseRr)")
            if oneSettingUseRr && oneSettingUseLsrr {
                oneSettingUseLsrr = false
                UserDefaults.standard.set(oneSettingUseLsrr, forKey: "oneSettingUseLsrr")
                SocLogger.debug("SocPingSharedObject: oneSettingUseLsrr = \(oneSettingUseLsrr)")
            }
        }
    }
    
    //===== Ping =====
    @Published var pingSettingPayloadDataType: Int = SocPingEcho.payloadTypeC {
        didSet {
            UserDefaults.standard.set(pingSettingPayloadDataType, forKey: "pingSettingPayloadDataType")
            SocLogger.debug("SocPingSharedObject: pingSettingPayloadDataType = \(pingSettingPayloadDataType)")
        }
    }
    @Published var pingSettingPayloadSizeType: Int = SocPingEcho.valueTypeDefault {
        didSet {
            UserDefaults.standard.set(pingSettingPayloadSizeType, forKey: "pingSettingPayloadSizeType")
            SocLogger.debug("SocPingSharedObject: pingSettingPayloadSizeType = \(pingSettingPayloadSizeType)")
            if isPingSweeping && isPingInfinitely {
                pingSettingLoopType = 1
                UserDefaults.standard.set(pingSettingLoopType, forKey: "pingSettingLoopType")
                SocLogger.debug("SocPingSharedObject: pingSettingLoopType = \(pingSettingLoopType)")
            }
        }
    }
    @Published var pingSettingPayloadSize: Int = SocPingPinger.payloadSizeDefault {
        didSet {
            UserDefaults.standard.set(pingSettingPayloadSize, forKey: "pingSettingPayloadSize")
            SocLogger.debug("SocPingSharedObject: pingSettingPayloadSize = \(pingSettingPayloadSize)")
        }
    }
    @Published var pingSettingSweepingMin: Int = SocPingEcho.tvLen {
        didSet {
            UserDefaults.standard.set(pingSettingSweepingMin, forKey: "pingSettingSweepingMin")
            SocLogger.debug("SocPingSharedObject: pingSettingSweepingMin = \(pingSettingSweepingMin)")
        }
    }
    @Published var pingSettingSweepingMax: Int = ICMP_MAXLEN {
        didSet {
            UserDefaults.standard.set(pingSettingSweepingMax, forKey: "pingSettingSweepingMax")
            SocLogger.debug("SocPingSharedObject: pingSettingSweepingMax = \(pingSettingSweepingMax)")
        }
    }
    @Published var pingSettingSweepingIncr: Int = 1 {
        didSet {
            UserDefaults.standard.set(pingSettingSweepingIncr, forKey: "pingSettingSweepingIncr")
            SocLogger.debug("SocPingSharedObject: pingSettingSweepingIncr = \(pingSettingSweepingIncr)")
        }
    }
    @Published var pingSettingLoopType: Int = 0 {  // 0:Infinitely loop, 1:Stops after loop
        didSet {
            UserDefaults.standard.set(pingSettingLoopType, forKey: "pingSettingLoopType")
            SocLogger.debug("SocPingSharedObject: pingSettingLoopType = \(pingSettingLoopType)")
            if isPingInfinitely && isPingSweeping {
                pingSettingPayloadSizeType = SocPingEcho.valueTypeDefault
                UserDefaults.standard.set(pingSettingPayloadSizeType, forKey: "pingSettingPayloadSizeType")
                SocLogger.debug("SocPingSharedObject: pingSettingPayloadSizeType = \(pingSettingPayloadSizeType)")
            }
        }
    }
    @Published var pingSettingInterval: Int = SocPingPinger.intervalDefault {
        didSet {
            UserDefaults.standard.set(pingSettingInterval, forKey: "pingSettingInterval")
            SocLogger.debug("SocPingSharedObject: pingSettingInterval = \(pingSettingInterval)")
        }
    }
    @Published var pingSettingEchoes: Int = SocPingPinger.echoesDefault {
        didSet {
            UserDefaults.standard.set(pingSettingEchoes, forKey: "pingSettingEchoes")
            SocLogger.debug("SocPingSharedObject: pingSettingEchoes = \(pingSettingEchoes)")
        }
    }
    @Published var pingSettingWaittime: Int = SocPingPinger.waittimeDefault {
        didSet {
            UserDefaults.standard.set(pingSettingWaittime, forKey: "pingSettingWaittime")
            SocLogger.debug("SocPingSharedObject: pingSettingWaittime = \(pingSettingWaittime)")
        }
    }
    
    //===== Traceroute =====
    @Published var traceSettingIpProto: Int32 = IPPROTO_ICMP {  // 0:ICMP, 1:UDP
        didSet {
            UserDefaults.standard.set(Int(traceSettingIpProto), forKey: "traceSettingIpProto")
            SocLogger.debug("SocPingSharedObject: traceSettingIpProto = \(traceSettingIpProto)")
        }
    }
    @Published var traceSettingPortType: Int = SocPingEcho.valueTypeDefault {
        didSet {
            UserDefaults.standard.set(traceSettingPortType, forKey: "traceSettingPortType")
            SocLogger.debug("SocPingSharedObject: traceSettingPortType = \(traceSettingPortType)")
        }
    }
    @Published var traceSettingUdpPort: Int = SocPingEcho.tracePortDefault {
        didSet {
            UserDefaults.standard.set(traceSettingUdpPort, forKey: "traceSettingUdpPort")
            SocLogger.debug("SocPingSharedObject: traceSettingUdpPort = \(traceSettingUdpPort)")
        }
    }
    @Published var traceSettingPayloadDataType: Int = SocPingEcho.payloadTypeZ {
        didSet {
            UserDefaults.standard.set(traceSettingPayloadDataType, forKey: "traceSettingPayloadDataType")
            SocLogger.debug("SocPingSharedObject: traceSettingPayloadDataType = \(traceSettingPayloadDataType)")
        }
    }
    @Published var traceSettingPayloadSizeType: Int = SocPingEcho.valueTypeDefault {
        didSet {
            UserDefaults.standard.set(traceSettingPayloadSizeType, forKey: "traceSettingPayloadSizeType")
            SocLogger.debug("SocPingSharedObject: traceSettingPayloadSizeType = \(traceSettingPayloadSizeType)")
        }
    }
    @Published var traceSettingPayloadSize: Int = SocPingTracer.payloadSizeDefault {
        didSet {
            UserDefaults.standard.set(traceSettingPayloadSize, forKey: "traceSettingPayloadSize")
            SocLogger.debug("SocPingSharedObject: traceSettingPayloadSize = \(traceSettingPayloadSize)")
        }
    }
    @Published var traceSettingProbes: Int = SocPingTracer.probesDefault {
        didSet {
            UserDefaults.standard.set(traceSettingProbes, forKey: "traceSettingProbes")
            SocLogger.debug("SocPingSharedObject: traceSettingProbes = \(traceSettingProbes)")
        }
    }
    @Published var traceSettingPause: Int = 0 {
        didSet {
            UserDefaults.standard.set(traceSettingPause, forKey: "traceSettingPause")
            SocLogger.debug("SocPingSharedObject: traceSettingPause = \(traceSettingPause)")
        }
    }
    @Published var traceSettingWaittime: Int = SocPingTracer.waittimeDefault {
        didSet {
            UserDefaults.standard.set(traceSettingWaittime, forKey: "traceSettingWaittime")
            SocLogger.debug("SocPingSharedObject: traceSettingWaittime = \(traceSettingWaittime)")
        }
    }
    @Published var traceSettingDontroute: Bool = false {
        didSet {
            UserDefaults.standard.set(traceSettingDontroute, forKey: "traceSettingDontroute")
            SocLogger.debug("SocPingSharedObject: traceSettingDontroute = \(traceSettingDontroute)")
        }
    }
    @Published var traceSettingTtlFirst: Int = 1 {
        didSet {
            UserDefaults.standard.set(traceSettingTtlFirst, forKey: "traceSettingTtlFirst")
            SocLogger.debug("SocPingSharedObject: traceSettingTtlFirst = \(traceSettingTtlFirst)")
        }
    }
    @Published var traceSettingTtlMax: Int = SocPingTracer.ttlDefault {
        didSet {
            UserDefaults.standard.set(traceSettingTtlMax, forKey: "traceSettingTtlMax")
            SocLogger.debug("SocPingSharedObject: traceSettingTtlMax = \(traceSettingTtlMax)")
        }
    }
    @Published var traceSettingUseTos: Bool = false {
        didSet {
            UserDefaults.standard.set(traceSettingUseTos, forKey: "traceSettingUseTos")
            SocLogger.debug("SocPingSharedObject: traceSettingUseTos = \(traceSettingUseTos)")
        }
    }
    @Published var traceSettingTos: Int = 0 {
        didSet {
            UserDefaults.standard.set(traceSettingTos, forKey: "traceSettingTos")
            SocLogger.debug("SocPingSharedObject: traceSettingTos = \(traceSettingTos)")
        }
    }
    @Published var traceSettingUseSrcIf: Bool = false {
        didSet {
            UserDefaults.standard.set(traceSettingUseSrcIf, forKey: "traceSettingUseSrcIf")
            SocLogger.debug("SocPingSharedObject: traceSettingUseSrcIf = \(traceSettingUseSrcIf)")
        }
    }
    @Published var traceSettingInterface: Int = SocPingInterface.deviceTypeLoopback {
        didSet {
            UserDefaults.standard.set(traceSettingInterface, forKey: "traceSettingInterface")
            SocLogger.debug("SocPingSharedObject: traceSettingInterface = \(traceSettingInterface)")
        }
    }
    @Published var traceSettingUseLsrr: Bool = false {
        didSet {
            UserDefaults.standard.set(traceSettingUseLsrr, forKey: "traceSettingUseLsrr")
            SocLogger.debug("SocPingSharedObject: traceSettingUseLsrr = \(traceSettingUseLsrr)")
        }
    }
    @Published var traceSettingNameResolved: Bool = true {
        didSet {
            UserDefaults.standard.set(traceSettingNameResolved, forKey: "traceSettingNameResolved")
            SocLogger.debug("SocPingSharedObject: traceSettingNameResolved = \(traceSettingNameResolved)")
        }
    }
    
    func getAgreementDate() -> String {
        let value = UserDefaults.standard.object(forKey: "agreementDate")
        guard let date = value as? Date else {
            return "N/A"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "C")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "YYYY/MM/dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }
    
    static func saveAddresses(addresses: [SocAddress]) {
        var stringsArray: [String] = []
        
        for address in addresses {
            if address.isAny {
                continue
            }
            let stringsElement = "\(address.addr):\(address.hostName)"
            stringsArray.append(stringsElement)
        }
        if stringsArray.count > 0 {
            SocLogger.debug("SocPingSharedObject.saveAddresses: \(stringsArray.count) addresses")
            UserDefaults.standard.set(stringsArray, forKey: "addresses")
        }
        else {
            SocLogger.debug("SocPingSharedObject.saveAddresses: removeObject")
            UserDefaults.standard.removeObject(forKey: "addresses")
        }
    }
    
    static func saveGateways(gateways: [SocAddress]) {
        var stringArray: [String] = []
        
        for address in gateways {
            stringArray.append(address.addr)
        }
        if stringArray.count > 0 {
            SocLogger.debug("SocPingSharedObject.saveGateways: \(stringArray.count) gateways")
            UserDefaults.standard.set(stringArray, forKey: "gateways")
        }
        else {
            SocLogger.debug("SocPingSharedObject.saveGateways: removeObject")
            UserDefaults.standard.removeObject(forKey: "gateways")
        }
    }
    
    init() {
        //===== Common =====
        isAgreed = UserDefaults.standard.bool(forKey: "isAgreed")
        if UserDefaults.standard.object(forKey: "appSettingDescription") != nil {  //Default is not false
            appSettingDescription = UserDefaults.standard.bool(forKey: "appSettingDescription")
        }
        appSettingIdleTimerDisabled = UserDefaults.standard.bool(forKey: "appSettingIdleTimerDisabled")
        appSettingScreenColorInverted = UserDefaults.standard.bool(forKey: "appSettingScreenColorInverted")
        if UserDefaults.standard.object(forKey: "appSettingTraceLevel") != nil {  //Default is not 0
            appSettingTraceLevel = UserDefaults.standard.integer(forKey: "appSettingTraceLevel")
        }
        appSettingDebugEnabled = UserDefaults.standard.bool(forKey: "appSettingDebugEnabled")
        
        //===== One Ping =====
        oneSettingVerbose = UserDefaults.standard.bool(forKey: "oneSettingVerbose")
        if UserDefaults.standard.object(forKey: "oneSettingIpProto") != nil {  //Default is not 0
            let intValue = UserDefaults.standard.integer(forKey: "oneSettingIpProto")
            oneSettingIpProto = Int32(intValue)
        }
        oneSettingIdType = UserDefaults.standard.integer(forKey: "oneSettingIdType")
        oneSettingIcmpId = UserDefaults.standard.integer(forKey: "oneSettingIcmpId")
        oneSettingSeqType = UserDefaults.standard.integer(forKey: "oneSettingSeqType")
        oneSettingIcmpSeq = UserDefaults.standard.integer(forKey: "oneSettingIcmpSeq")
        oneSettingPortType = UserDefaults.standard.integer(forKey: "oneSettingPortType")
        oneSettingUdpPort = UserDefaults.standard.integer(forKey: "oneSettingUdpPort")
        if UserDefaults.standard.object(forKey: "oneSettingPayloadDataType") != nil {  //Default is not 0
            oneSettingPayloadDataType = UserDefaults.standard.integer(forKey: "oneSettingPayloadDataType")
        }
        oneSettingPayloadSizeType = UserDefaults.standard.integer(forKey: "oneSettingPayloadSizeType")
        if UserDefaults.standard.object(forKey: "oneSettingPayloadSize") != nil {  //Default is not 0
            oneSettingPayloadSize = UserDefaults.standard.integer(forKey: "oneSettingPayloadSize")
        }
        if UserDefaults.standard.object(forKey: "oneSettingWaittime") != nil {  //Default is not 0
            oneSettingWaittime = UserDefaults.standard.integer(forKey: "oneSettingWaittime")
        }
        oneSettingUseTtl = UserDefaults.standard.bool(forKey: "oneSettingUseTtl")
        if UserDefaults.standard.object(forKey: "oneSettingTtl") != nil {  //Default is not 0
            oneSettingTtl = UserDefaults.standard.integer(forKey: "oneSettingTtl")
        }
        oneSettingUseTos = UserDefaults.standard.bool(forKey: "oneSettingUseTos")
        oneSettingTos = UserDefaults.standard.integer(forKey: "oneSettingTos")
        oneSettingDontroute = UserDefaults.standard.bool(forKey: "oneSettingDontroute")
        oneSettingNoLoop = UserDefaults.standard.bool(forKey: "oneSettingNoLoop")
        oneSettingUseSrcIf = UserDefaults.standard.bool(forKey: "oneSettingUseSrcIf")
        oneSettingInterface = UserDefaults.standard.integer(forKey: "oneSettingInterface")
        oneSettingUseLsrr = UserDefaults.standard.bool(forKey: "oneSettingUseLsrr")
        oneSettingUseRr = UserDefaults.standard.bool(forKey: "oneSettingUseRr")

        //===== Ping =====
        if UserDefaults.standard.object(forKey: "pingSettingPayloadDataType") != nil {  //Default is not 0
            pingSettingPayloadDataType = UserDefaults.standard.integer(forKey: "pingSettingPayloadDataType")
        }
        pingSettingPayloadSizeType = UserDefaults.standard.integer(forKey: "pingSettingPayloadSizeType")
        if UserDefaults.standard.object(forKey: "pingSettingPayloadSize") != nil {  //Default is not 0
            pingSettingPayloadSize = UserDefaults.standard.integer(forKey: "pingSettingPayloadSize")
        }
        if UserDefaults.standard.object(forKey: "pingSettingSweepingMin") != nil {  //Default is not 0
            pingSettingSweepingMin = UserDefaults.standard.integer(forKey: "pingSettingSweepingMin")
        }
        if UserDefaults.standard.object(forKey: "pingSettingSweepingMax") != nil {  //Default is not 0
            pingSettingSweepingMax = UserDefaults.standard.integer(forKey: "pingSettingSweepingMax")
        }
        if UserDefaults.standard.object(forKey: "pingSettingSweepingIncr") != nil {  //Default is not 0
            pingSettingSweepingIncr = UserDefaults.standard.integer(forKey: "pingSettingSweepingIncr")
        }
        pingSettingLoopType = UserDefaults.standard.integer(forKey: "pingSettingLoopType")
        if UserDefaults.standard.object(forKey: "pingSettingInterval") != nil {  //Default is not 0
            pingSettingInterval = UserDefaults.standard.integer(forKey: "pingSettingInterval")
        }
        if UserDefaults.standard.object(forKey: "pingSettingEchoes") != nil {  //Default is not 0
            pingSettingEchoes = UserDefaults.standard.integer(forKey: "pingSettingEchoes")
        }
        if UserDefaults.standard.object(forKey: "pingSettingWaittime") != nil {  //Default is not 0
            pingSettingWaittime = UserDefaults.standard.integer(forKey: "pingSettingWaittime")
        }

        //===== Traceroute =====
        if UserDefaults.standard.object(forKey: "traceSettingIpProto") != nil {  //Default is not 0
            let intValue = UserDefaults.standard.integer(forKey: "traceSettingIpProto")
            traceSettingIpProto = Int32(intValue)
        }
        traceSettingPortType = UserDefaults.standard.integer(forKey: "traceSettingPortType")
        if UserDefaults.standard.object(forKey: "traceSettingUdpPort") != nil {  //Default is not 0
            traceSettingUdpPort = UserDefaults.standard.integer(forKey: "traceSettingUdpPort")
        }
        traceSettingPayloadDataType = UserDefaults.standard.integer(forKey: "traceSettingPayloadDataType")
        traceSettingPayloadSizeType = UserDefaults.standard.integer(forKey: "traceSettingPayloadSizeType")
        if UserDefaults.standard.object(forKey: "traceSettingPayloadSize") != nil {  //Default is not 0
            traceSettingPayloadSize = UserDefaults.standard.integer(forKey: "traceSettingPayloadSize")
        }
        if UserDefaults.standard.object(forKey: "traceSettingProbes") != nil {  //Default is not 0
            traceSettingProbes = UserDefaults.standard.integer(forKey: "traceSettingProbes")
        }
        traceSettingPause = UserDefaults.standard.integer(forKey: "traceSettingPause")
        if UserDefaults.standard.object(forKey: "traceSettingWaittime") != nil {  //Default is not 0
            traceSettingWaittime = UserDefaults.standard.integer(forKey: "traceSettingWaittime")
        }
        if UserDefaults.standard.object(forKey: "traceSettingTtlFirst") != nil {  //Default is not 0
            traceSettingTtlFirst = UserDefaults.standard.integer(forKey: "traceSettingTtlFirst")
        }
        if UserDefaults.standard.object(forKey: "traceSettingTtlMax") != nil {  //Default is not 0
            traceSettingTtlMax = UserDefaults.standard.integer(forKey: "traceSettingTtlMax")
        }
        traceSettingUseTos = UserDefaults.standard.bool(forKey: "traceSettingUseTos")
        traceSettingTos = UserDefaults.standard.integer(forKey: "traceSettingTos")
        traceSettingDontroute = UserDefaults.standard.bool(forKey: "traceSettingDontroute")
        traceSettingUseSrcIf = UserDefaults.standard.bool(forKey: "traceSettingUseSrcIf")
        traceSettingInterface = UserDefaults.standard.integer(forKey: "traceSettingInterface")
        traceSettingUseLsrr = UserDefaults.standard.bool(forKey: "traceSettingUseLsrr")
        if UserDefaults.standard.object(forKey: "traceSettingNameResolved") != nil {  //Default is not false
            traceSettingNameResolved = UserDefaults.standard.bool(forKey: "traceSettingNameResolved")
        }
        
        SocSocket.initSoc()
        SocLogger.setTraceLevel(appSettingTraceLevel)
        if appSettingDebugEnabled {
            SocLogger.enableDebug()
        }
        SocLogger.debug("Agreed the Terms of Service: \(self.getAgreementDate())")
        for i in 0 ..< self.interfaces.count {
            self.interfaces[i].ifconfig()
        }
        let width = CGFloat(UIScreen.main.bounds.width)
        let height = CGFloat(UIScreen.main.bounds.height)
        deviceWidth = width < height ? width : height
        SocPingScreen.initSize(width: deviceWidth)
        SocLogger.debug("Load App Setting:")
        SocLogger.debug("appSettingDescription = \(appSettingDescription)")
        SocLogger.debug("appSettingIdleTimerDisabled = \(appSettingIdleTimerDisabled)")
        SocLogger.debug("appSettingScreenColorInverted = \(appSettingScreenColorInverted)")
        SocLogger.debug("appSettingTraceLevel = \(appSettingTraceLevel)")
        SocLogger.debug("appSettingDebugEnabled = \(appSettingDebugEnabled)")
        SocLogger.debug("Load Address:")
        if UserDefaults.standard.object(forKey: "addresses") != nil {
            if let stringsArray: [String] = UserDefaults.standard.stringArray(forKey: "addresses") {
                for stringsElement in stringsArray {
                    let array: [String] = stringsElement.components(separatedBy: ":")
                    if array.count == 2 {
                        let addr = SocAddress(family: AF_INET, addr: array[0], port: 0, hostName: array[1])
                        addresses.append(addr)
                        SocLogger.debug("address - \(addr.addr):\(addr.hostName)")
                    }
                    else {
                        SocLogger.error("Invalid address - \(stringsElement)")
                        assertionFailure("Invalid address - \(stringsElement)")
                    }
                }
            }
        }
        let addr = SocAddress(family: AF_INET, addr: "0.0.0.0", port: 0, hostName: "")
        addresses.append(addr)
        SocLogger.debug("address - 0.0.0.0:0 (ANY address)")
        SocLogger.debug("Load Gateways:")
        if UserDefaults.standard.object(forKey: "gateways") != nil {
            if let stringArray: [String] = UserDefaults.standard.stringArray(forKey: "gateways") {
                for i in 0 ..< stringArray.count {
                    var hit = false
                    for j in 0 ..< addresses.count {
                        if addresses[j].addr == stringArray[i] {
                            gateways.append(addresses[j])
                            hit = true
                            break
                        }
                    }
                    SocLogger.debug("(\(i + 1))\(stringArray[i]) \(hit ? "" : "miss")")
                }
            }
        }
        SocLogger.debug("Load Settings:")
        SocLogger.debug("oneSettingVerbose = \(oneSettingVerbose)")
        SocLogger.debug("oneSettingIpProto = \(oneSettingIpProto)")
        SocLogger.debug("oneSettingIdType = \(oneSettingIdType)")
        SocLogger.debug("oneSettingIcmpId = \(oneSettingIcmpId)")
        SocLogger.debug("oneSettingSeqType = \(oneSettingSeqType)")
        SocLogger.debug("oneSettingIcmpSeq = \(oneSettingIcmpSeq)")
        SocLogger.debug("oneSettingPortType = \(oneSettingPortType)")
        SocLogger.debug("oneSettingUdpPort = \(oneSettingUdpPort)")
        SocLogger.debug("oneSettingPayloadDataType = \(oneSettingPayloadDataType)")
        SocLogger.debug("oneSettingPayloadSizeType = \(oneSettingPayloadSizeType)")
        SocLogger.debug("oneSettingPayloadSize = \(oneSettingPayloadSize)")
        SocLogger.debug("oneSettingWaittime = \(oneSettingWaittime)")
        SocLogger.debug("oneSettingUseTtl = \(oneSettingUseTtl)")
        SocLogger.debug("oneSettingTtl = \(oneSettingTtl)")
        SocLogger.debug("oneSettingUseTos = \(oneSettingUseTos)")
        SocLogger.debug("oneSettingTos = \(oneSettingTos)")
        SocLogger.debug("oneSettingNoLoop = \(oneSettingNoLoop)")
        SocLogger.debug("oneSettingDontroute = \(oneSettingDontroute)")
        SocLogger.debug("oneSettingUseSrcIf = \(oneSettingUseSrcIf)")
        SocLogger.debug("oneSettingInterface = \(oneSettingInterface)")
        SocLogger.debug("oneSettingUseLsrr = \(oneSettingUseLsrr)")
        SocLogger.debug("oneSettingUseRr = \(oneSettingUseRr)")
        SocLogger.debug("pingSettingPayloadDataType = \(pingSettingPayloadDataType)")
        SocLogger.debug("pingSettingPayloadSizeType = \(pingSettingPayloadSizeType)")
        SocLogger.debug("pingSettingPayloadSize = \(pingSettingPayloadSize)")
        SocLogger.debug("pingSettingSweepingMin = \(pingSettingSweepingMin)")
        SocLogger.debug("pingSettingSweepingMax = \(pingSettingSweepingMax)")
        SocLogger.debug("pingSettingSweepingIncr = \(pingSettingSweepingIncr)")
        SocLogger.debug("pingSettingLoopType = \(pingSettingLoopType)")
        SocLogger.debug("pingSettingInterval = \(pingSettingInterval)")
        SocLogger.debug("pingSettingEchoes = \(pingSettingEchoes)")
        SocLogger.debug("pingSettingWaittime = \(pingSettingWaittime)")
        SocLogger.debug("traceSettingIpProto = \(traceSettingIpProto)")
        SocLogger.debug("traceSettingPortType = \(traceSettingPortType)")
        SocLogger.debug("traceSettingUdpPort = \(traceSettingUdpPort)")
        SocLogger.debug("traceSettingPayloadDataType = \(traceSettingPayloadDataType)")
        SocLogger.debug("traceSettingPayloadSizeType = \(traceSettingPayloadSizeType)")
        SocLogger.debug("traceSettingPayloadSize = \(traceSettingPayloadSize)")
        SocLogger.debug("traceSettingProbes = \(traceSettingProbes)")
        SocLogger.debug("traceSettingPause = \(traceSettingPause)")
        SocLogger.debug("traceSettingWaittime = \(traceSettingWaittime)")
        SocLogger.debug("traceSettingDontroute = \(traceSettingDontroute)")
        SocLogger.debug("traceSettingTtlFirst = \(traceSettingTtlFirst)")
        SocLogger.debug("traceSettingTtlMax = \(traceSettingTtlMax)")
        SocLogger.debug("traceSettingUseTos = \(traceSettingUseTos)")
        SocLogger.debug("traceSettingTos = \(traceSettingTos)")
        SocLogger.debug("traceSettingUseSrcIf = \(traceSettingUseSrcIf)")
        SocLogger.debug("traceSettingInterface = \(traceSettingInterface)")
        SocLogger.debug("traceSettingUseLsrr = \(traceSettingUseLsrr)")
        SocLogger.debug("traceSettingNameResolved = \(traceSettingNameResolved)")
        SocLogger.debug("Check Device Configuration:")
        SocLogger.debug("WiFi Address = \(interfaces[SocPingInterface.deviceTypeWifi].inet.addr)")
        SocLogger.debug("Cellurar Address = \(interfaces[SocPingInterface.deviceTypeCellurar].inet.addr)")
        SocLogger.debug("Hotspot Address = \(interfaces[SocPingInterface.deviceTypeHotspot].inet.addr)")
        SocLogger.debug("Loopback Address = \(interfaces[SocPingInterface.deviceTypeLoopback].inet.addr)")
        SocLogger.debug("Appearance = \(UITraitCollection.current.userInterfaceStyle == .dark ? "Dark mode" : "Light mode")")
        SocLogger.debug("TimeZone = \(TimeZone.current)")
        SocLogger.debug("Languages = \(Locale.preferredLanguages)")
        SocLogger.debug("Screen Size = \(width) * \(height)")
        SocLogger.debug("SocPingSharedObject.init: done")
    }
}
