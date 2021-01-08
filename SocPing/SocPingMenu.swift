//
//  SocPingMenu.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import Foundation
import SwiftUI
import UIKit

let APP_VERTION = "1.0.0"
let COPYRIGHT = "Copyright © 2021 manabapp. All rights reserved."
let URL_BASE = "https://manabapp.github.io/"
let URL_TERMS = URL_BASE + "SocPing/TermsOfService.html"
let URL_TERMS_JA = URL_BASE + "SocPing/TermsOfService_ja.html"
let URL_POLICY = URL_BASE + "SocPing/PrivacyPolicy.html"
let URL_POLICY_JA = URL_BASE + "SocPing/PrivacyPolicy_ja.html"
let URL_WEBPAGE = URL_BASE + "Apps/App_SocPing/index.html"
let URL_WEBPAGE_JA = URL_BASE + "Apps/App_SocPing/index_ja.html"
let MAIL_ADDRESS = "manabapp@gmail.com"

struct SocPingMenu: View {
    @EnvironmentObject var object: SocPingSharedObject
    @State var logText: String = ""
    @State private var alertTitle: String = "Unexpected error."
    @State private var isPopAlert: Bool = false
    
    static func getBytes(_ size: Int) -> Text {
        if size == 1 {
            return Text("1 \(NSLocalizedString("Label_byte", comment: ""))")
        }
        else {
            return Text("\(size) \(NSLocalizedString("Label_bytes", comment: ""))")
        }
    }
    
    static func getPackets(_ num: Int) -> Text {
        if num == 1 {
            return Text("1 \(NSLocalizedString("Label_packet", comment: ""))")
        }
        else {
            return Text("\(num) \(NSLocalizedString("Label_packets", comment: ""))")
        }
    }
    
    static func getSeconds(_ msec: Int) -> Text {
        return Text(String(format: "%.3f ", Double(msec) / 1000.0) + NSLocalizedString("Label_sec", comment: ""))
    }
    
    var body: some View {
        List {
            Section(header: Text("Header_PREFERENCES")) {
                NavigationLink(destination: AppSettings()) {
                    CommonRaw(name:"App Settings", image:"wrench", detail:"Description_App_Settings")
                }
                NavigationLink(destination: PingSettings(payloadLen: object.pingSettingPayloadSize,
                                                        interval: object.pingSettingInterval,
                                                        echoes: object.pingSettingEchoes,
                                                        sweepingMin: object.pingSettingSweepingMin,
                                                        sweepingMax: object.pingSettingSweepingMax,
                                                        sweepingIncr: object.pingSettingSweepingIncr,
                                                        waittime: object.pingSettingWaittime)) {
                    CommonRaw(name:"Ping Settings", image:"circle", detail:"Description_Ping_Settings")
                }
                NavigationLink(destination: TracerouteSettings(basePort: object.traceSettingUdpPort,
                                                              payloadLen: object.traceSettingPayloadSize,
                                                              pause: object.traceSettingPause,
                                                              waittime: object.traceSettingWaittime,
                                                              ttlFirst: object.traceSettingTtlFirst,
                                                              ttlMax: object.traceSettingTtlMax,
                                                              tos: object.traceSettingTos)) {
                    CommonRaw(name:"Traceroute Settings", image:"arrow.triangle.swap", detail:"Description_Traceroute_Settings")
                }
                NavigationLink(destination: OnePingSettings(icmpId: object.oneSettingIcmpId,
                                                           icmpSeq: object.oneSettingIcmpSeq,
                                                           udpPort: object.oneSettingUdpPort,
                                                           payloadLen: object.oneSettingPayloadSize,
                                                           waittime: object.oneSettingWaittime,
                                                           ttl: object.oneSettingTtl,
                                                           tos: object.oneSettingTos)) {
                    CommonRaw(name:"One Ping Settings", image:"1.circle", detail:"Description_One_Ping_Settings")
                }
            }
            Section(header: Text("Header_LOG")) {
                ZStack {
                    NavigationLink(destination: SocPingLogViewer(text: self.$logText)) {
                        Text("")
                    }
                    Button(action: {
                        SocLogger.debug("SocPingMenu: Button: Log Viewer")
                        self.logText = SocLogger.getLog()
                    }) {
                        CommonRaw(name:"Log Viewer", image:"note.text", detail:"Description_Log_Viewer")
                    }
                }
            }
            Section(header: Text("Header_INFORMATION")) {
                NavigationLink(destination: AboutApp()) {
                    CommonRaw(name:"About App", image:"info.circle", detail:"Description_About_App")
                }
                Button(action: {
                    SocLogger.debug("SocPingMenu: Button: Policy")
                    do {
                        let url = URL(string: SocPingSharedObject.isJa ? URL_POLICY_JA : URL_POLICY)!
                        guard UIApplication.shared.canOpenURL(url) else {
                            throw SocPingError.CantOpenURL
                        }
                        UIApplication.shared.open(url)
                    }
                    catch let error as SocPingError {
                        self.alertTitle = error.message
                        self.isPopAlert = true
                    }
                    catch {
                        SocLogger.error("SocPingMenu: \(error)")
                        assertionFailure("SocPingMenu: \(error)")
                        self.isPopAlert = true
                    }
                }) {
                    CommonRaw(name:"Privacy Policy", image:"hand.raised.fill", detail:"Description_Privacy_Policy")
                }
                .alert(isPresented: self.$isPopAlert) {
                    Alert(title: Text(self.alertTitle))
                }
                Button(action: {
                    SocLogger.debug("SocPingMenu: Button: Terms")
                    do {
                        let url = URL(string: SocPingSharedObject.isJa ? URL_TERMS_JA : URL_TERMS)!
                        guard UIApplication.shared.canOpenURL(url) else {
                            throw SocPingError.CantOpenURL
                        }
                        UIApplication.shared.open(url)
                    }
                    catch let error as SocPingError {
                        self.alertTitle = error.message
                        self.isPopAlert = true
                    }
                    catch {
                        SocLogger.error("SocPingMenu: \(error)")
                        assertionFailure("SocPingMenu: \(error)")
                        self.isPopAlert = true
                    }
                }) {
                    CommonRaw(name:"Terms of Service", image:"doc.plaintext", detail:"Description_Terms_of_Service")
                }
                .alert(isPresented: self.$isPopAlert) {
                    Alert(title: Text(self.alertTitle))
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle("Menu", displayMode: .inline)
    }
}

fileprivate struct CommonRaw: View {
    @EnvironmentObject var object: SocPingSharedObject
    let name: String
    let image: String
    let detail: LocalizedStringKey
    
    var body: some View {
        HStack {
            Image(systemName: self.image)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(self.name)
                        .font(.system(size: 20))
                    Spacer()
                }
                if object.appSettingDescription {
                    HStack {
                        Text(self.detail)
                            .font(.system(size: 12))
                            .foregroundColor(Color.init(UIColor.systemGray))
                        Spacer()
                    }
                }
            }
            .padding(.leading)
        }
    }
}

fileprivate struct AppSettings: View {
    @EnvironmentObject var object: SocPingSharedObject
    
    var body: some View {
        List {
            Section(header: Text("DESCRIPTION").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_app_DESCRIPTION").font(.system(size: 12)) : nil) {
                Toggle(isOn: self.$object.appSettingDescription) {
                    Text("Label_Enabled")
                }
            }
            Section(header: Text("IDLE TIMER").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_app_IDLE_TIMER").font(.system(size: 12)) : nil) {
                Toggle(isOn: self.$object.appSettingIdleTimerDisabled) {
                    Text("Label_Disabled")
                }
            }
            Section(header: Text("SCREEN COLOR").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_app_SCREEN_COLOR").font(.system(size: 12)) : nil) {
                Toggle(isOn: self.$object.appSettingScreenColorInverted) {
                    Text("Label_Inverted")
                }
            }
            Section(header: Text("SYSTEM CALL TRACE").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_app_SYSTEM_CALL_TRACE").font(.system(size: 12)) : nil) {
                Picker("", selection: self.$object.appSettingTraceLevel) {
                    Text("Label_TRACE_Level1").tag(SocLogger.traceLevelNoData)
                    Text("Label_TRACE_Level2").tag(SocLogger.traceLevelInLine)
                    Text("Label_TRACE_Level3").tag(SocLogger.traceLevelHexDump)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
#if DEBUG
            Section(header: Text("DEBUG").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_app_DEBUG").font(.system(size: 12)) : nil) {
                Toggle(isOn: self.$object.appSettingDebugEnabled) {
                    Text("Label_Enabled")
                }
            }
#endif
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("App Settings", displayMode: .inline)
    }
}

fileprivate struct PingSettings: View {
    @EnvironmentObject var object: SocPingSharedObject
    @State private var stringPayloadLen: String
    @State private var stringInterval: String
    @State private var stringEchoes: String
    @State private var stringSweepingMin: String
    @State private var stringSweepingMax: String
    @State private var stringSweepingIncr: String
    @State private var stringWaittime: String
    @State private var isSetPayloadLen: Bool = false
    @State private var isSetInterval: Bool = false
    @State private var isSetEchoes: Bool = false
    @State private var isSetSweeping: Bool = false
    @State private var isSetWaittime: Bool = false
    @State private var alertTitle: String = "Unexpected error."
    @State private var isPopAlert: Bool = false
    
    init(payloadLen: Int,
         interval: Int,
         echoes: Int,
         sweepingMin: Int,
         sweepingMax: Int,
         sweepingIncr: Int,
         waittime: Int) {
        _stringPayloadLen = State(initialValue: String(payloadLen))
        _stringInterval = State(initialValue: String(format: "%.3f", Double(interval) / 1000.0))
        _stringEchoes = State(initialValue: String(echoes))
        _stringSweepingMin = State(initialValue: String(sweepingMin))
        _stringSweepingMax = State(initialValue: String(sweepingMax))
        _stringSweepingIncr = State(initialValue: String(sweepingIncr))
        _stringWaittime = State(initialValue: String(format: "%.3f", Double(waittime) / 1000.0))
    }
    
    var body: some View {
        List {
            Section(header: Text("PAYLOAD").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_ping_PAYLOAD").font(.system(size: 12)) : nil) {
                HStack {
                    Text("Label_Data_type")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: self.$object.pingSettingPayloadDataType) {
                        Text("Label_All_Zero").tag(SocPingEcho.payloadTypeZ)
                        Text("Label_All_0xFF").tag(SocPingEcho.payloadTypeF)
                        Text("Label_Continuous").tag(SocPingEcho.payloadTypeC)
                        Text("Label_Random").tag(SocPingEcho.payloadTypeR)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                HStack {
                    Text("Label_Size_type")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: self.$object.pingSettingPayloadSizeType) {
                        Text("Label_Default").tag(SocPingEcho.valueTypeDefault)
                        Text("Label_Users_size").tag(SocPingEcho.valueTypeUserSet)
                        Text("Label_Sweep").tag(SocPingEcho.valueTypeSweep)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                if object.pingSettingPayloadSizeType == SocPingEcho.valueTypeDefault {
                    HStack {
                        Text("Label_Data_size")
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        SocPingMenu.getBytes(SocPingPinger.payloadSizeDefault)
                    }
                }
                else if object.pingSettingPayloadSizeType == SocPingEcho.valueTypeUserSet {
                    if !self.isSetPayloadLen {
                        HStack {
                            Text("Label_Data_size")
                                .frame(width: 100, alignment: .leading)
                            TextField("0 - \(ICMP_MAXLEN)", text: $stringPayloadLen)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            Button(action: {
                                SocLogger.debug("PingSetting: Button: payloadLen OK")
                                do {
                                    object.pingSettingPayloadSize = try self.getInt(stringValue: self.stringPayloadLen, min: 0, max: ICMP_MAXLEN)
                                    self.isSetPayloadLen = true
                                }
                                catch let error as SocPingError {
                                    self.alertTitle = error.message
                                    self.isPopAlert = true
                                }
                                catch {
                                    SocLogger.error("PingSetting: \(error)")
                                    assertionFailure("PingSetting: \(error)")
                                    self.isPopAlert = true
                                }
                            }) {
                                Text("Button_OK")
                                    .foregroundColor(Color.init(UIColor.systemBlue))
                            }
                        }
                        .alert(isPresented: self.$isPopAlert) {
                            Alert(title: Text(self.alertTitle))
                        }
                    }
                    else {
                        HStack {
                            Text("Label_Data_size")
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            SocPingMenu.getBytes(object.pingSettingPayloadSize)
                        }
                    }
                }
                else {  // SocPingEcho.valueTypeSweep
                    if !self.isSetSweeping {
                        HStack {
                            VStack(spacing: 0) {
                                Text("Label_Min")
                                TextField("0 - \(UInt16.max - 1)", text: $stringSweepingMin)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: .infinity)
                            }
                            VStack(spacing: 0) {
                                Text("Label_Max")
                                TextField("1 - \(UInt16.max)", text: $stringSweepingMax)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: .infinity)
                            }
                            VStack(spacing: 0) {
                                Text("Label_Increment")
                                TextField("1 - \(UInt16.max)", text: $stringSweepingIncr)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: .infinity)
                            }
                            Button(action: {
                                SocLogger.debug("PingSetting: Button: Sweeping OK")
                                do {
                                    let ret = try self.getSweeping()
                                    object.pingSettingSweepingMin = ret.0
                                    object.pingSettingSweepingMax = ret.1
                                    object.pingSettingSweepingIncr = ret.2
                                    self.isSetSweeping = true
                                }
                                catch let error as SocPingError {
                                    self.alertTitle = error.message
                                    self.isPopAlert = true
                                }
                                catch {
                                    SocLogger.error("PingSetting: \(error)")
                                    assertionFailure("PingSetting: \(error)")
                                    self.isPopAlert = true
                                }
                            }) {
                                Text("Button_OK")
                                    .foregroundColor(Color.init(UIColor.systemBlue))
                            }
                        }
                        .alert(isPresented: self.$isPopAlert) {
                            Alert(title: Text(self.alertTitle))
                        }
                    }
                    else {
                        HStack {
                            Text("Label_Data_size")
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            Text("\(object.pingSettingSweepingMin) - \(object.pingSettingSweepingMax) (+\(object.pingSettingSweepingIncr) \(NSLocalizedString(object.pingSettingSweepingIncr == 1 ? "Label_byte" : "Label_bytes", comment: "")))")
                        }
                    }
                }
            }
            Section(header: Text("LOOP").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_ping_LOOP").font(.system(size: 12)) : nil) {
                HStack {
                    Picker("", selection: self.$object.pingSettingLoopType) {
                        Text("Label_Infinite_loop").tag(0)
                        Text("Label_Stops_after_loop").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(false)
                }
                if object.isPingInfinitely {
                    HStack {
                        Text("Label_Number_of_ECHOes")
                            .frame(width: 170, alignment: .leading)
                        Spacer()
                        Text("Label_NA")
                    }
                }
                else if object.isPingSweeping {
                    HStack {
                        Text("Label_Number_of_ECHOes")
                            .frame(width: 170, alignment: .leading)
                        Spacer()
                        SocPingMenu.getPackets(self.object.pingSweepingCount)
                    }
                }
                else {
                    if !self.isSetEchoes {
                        HStack {
                            Text("Label_Number_of_ECHOes")
                                .frame(width: 170, alignment: .leading)
                            TextField("1 - \(UInt16.max)", text: $stringEchoes)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            Button(action: {
                                SocLogger.debug("PingSetting: Button: Count OK")
                                do {
                                    object.pingSettingEchoes = try self.getInt(stringValue: self.stringEchoes, min: 1, max: Int(UInt16.max))
                                    self.isSetEchoes = true
                                }
                                catch let error as SocPingError {
                                    self.alertTitle = error.message
                                    self.isPopAlert = true
                                }
                                catch {
                                    SocLogger.error("PingSetting: \(error)")
                                    assertionFailure("PingSetting: \(error)")
                                    self.isPopAlert = true
                                }
                            }) {
                                Text("Button_OK")
                                    .foregroundColor(Color.init(UIColor.systemBlue))
                            }
                        }
                        .alert(isPresented: self.$isPopAlert) {
                            Alert(title: Text(self.alertTitle))
                        }
                    }
                    else {
                        HStack {
                            Text("Label_Number_of_ECHOes")
                                .frame(width: 170, alignment: .leading)
                            Spacer()
                            SocPingMenu.getPackets(object.pingSettingEchoes)
                        }
                    }
                }
                if !self.isSetInterval {
                    HStack {
                        Text("Label_Interval")
                            .frame(width: 170, alignment: .leading)
                        TextField("0.1 - 3600.0", text: $stringInterval)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                        Button(action: {
                            SocLogger.debug("PingSetting: Button: Interval OK")
                            do {
                                object.pingSettingInterval = try self.getMSec(stringValue: stringInterval, min: 0.1, max: 3600.0)
                                self.isSetInterval = true
                            }
                            catch let error as SocPingError {
                                self.alertTitle = error.message
                                self.isPopAlert = true
                            }
                            catch {
                                SocLogger.error("PingSetting: \(error)")
                                assertionFailure("PingSetting: \(error)")
                                self.isPopAlert = true
                            }
                        }) {
                            Text("Button_OK")
                                .foregroundColor(Color.init(UIColor.systemBlue))
                        }
                    }
                    .alert(isPresented: self.$isPopAlert) {
                        Alert(title: Text(self.alertTitle))
                    }
                }
                else {
                    HStack {
                        Text("Label_Interval")
                            .frame(width: 170, alignment: .leading)
                        Spacer()
                        SocPingMenu.getSeconds(object.pingSettingInterval)
                    }
                }
            }
            Section(header: Text("WAIT TIME").font(.system(size: 16, weight: .semibold)),
                    footer: object.appSettingDescription ? Text("Footer_ping_WAIT_TIME").font(.system(size: 12)) : nil) {
                if !self.isSetWaittime {
                    HStack {
                        TextField("0.1 - 3600.0", text: $stringWaittime)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                        Button(action: {
                            SocLogger.debug("PingSetting: Button: Waittime OK")
                            do {
                                object.pingSettingWaittime = try self.getMSec(stringValue: stringWaittime, min: 0.1, max: 3600.0)
                                self.isSetWaittime = true
                            }
                            catch let error as SocPingError {
                                self.alertTitle = error.message
                                self.isPopAlert = true
                            }
                            catch {
                                SocLogger.error("PingSetting: \(error)")
                                assertionFailure("PingSetting: \(error)")
                                self.isPopAlert = true
                            }
                        }) {
                            Text("Button_OK")
                                .foregroundColor(Color.init(UIColor.systemBlue))
                        }
                    }
                    .alert(isPresented: self.$isPopAlert) {
                        Alert(title: Text(self.alertTitle))
                    }
                }
                else {
                    HStack {
                        Spacer()
                        SocPingMenu.getSeconds(object.pingSettingWaittime)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Ping Settings", displayMode: .inline)
    }
    
    func getInt(stringValue: String, min: Int, max: Int) throws -> Int {
        if stringValue.isEmpty {
            throw SocPingError.NoValue
        }
        guard let value = Int(stringValue) else {
            throw SocPingError.InvalidValue
        }
        if value < min || value > max {
            throw SocPingError.InvalidValue
        }
        return value
    }
    
    func getMSec(stringValue: String, min: Double, max: Double) throws -> Int {
        if stringValue.isEmpty {
            throw SocPingError.NoValue
        }
        guard let value = Double(stringValue) else {
            throw SocPingError.InvalidValue
        }
        if value < min || value > max {
            throw SocPingError.InvalidValue
        }
        return Int(value * 1000.0)
    }
    
    func getSweeping() throws -> (Int, Int, Int) {
        if self.stringSweepingMin.isEmpty || self.stringSweepingMax.isEmpty || self.stringSweepingIncr.isEmpty {
            throw SocPingError.NoValue
        }
        guard let sweepingMin = Int(self.stringSweepingMin) else {
            throw SocPingError.InvalidValue
        }
        if sweepingMin < 0 || sweepingMin > UInt16.max - 1 {
            throw SocPingError.InvalidValue
        }
        guard let sweepingMax = Int(self.stringSweepingMax) else {
            throw SocPingError.InvalidValue
        }
        if sweepingMax < 1 || sweepingMax > UInt16.max {
            throw SocPingError.InvalidValue
        }
        guard let sweepingIncr = Int(self.stringSweepingIncr) else {
            throw SocPingError.InvalidValue
        }
        if sweepingIncr < 1 || sweepingIncr > UInt16.max {
            throw SocPingError.InvalidValue
        }
        if sweepingMin >= sweepingMax {
            throw SocPingError.InvalidValue
        }
        return (sweepingMin, sweepingMax, sweepingIncr)
    }
}

fileprivate struct TracerouteSettings: View {
    @EnvironmentObject var object: SocPingSharedObject
    @State private var stringBasePort: String
    @State private var stringPayloadLen: String
    @State private var stringPause: String
    @State private var stringWaittime: String
    @State private var stringTtlFirst: String
    @State private var stringTtlMax: String
    @State private var stringTos: String
    @State private var isSetBasePort: Bool = false
    @State private var isSetPayloadLen: Bool = false
    @State private var isSetPause: Bool = false
    @State private var isSetWaittime: Bool = false
    @State private var isSetTtl: Bool = false
    @State private var isSetTos: Bool = false
    @State private var alertTitle: String = "Unexpected error."
    @State private var isPopAlert: Bool = false
    
    init(basePort: Int,
         payloadLen: Int,
         pause: Int,
         waittime: Int,
         ttlFirst: Int,
         ttlMax: Int,
         tos: Int) {
        _stringBasePort = State(initialValue: String(basePort))
        _stringPayloadLen = State(initialValue: String(payloadLen))
        _stringPause = State(initialValue: String(pause / 1000))
        _stringWaittime = State(initialValue: String(format: "%.3f", Double(waittime) / 1000.0))
        _stringTtlFirst = State(initialValue: String(ttlFirst))
        _stringTtlMax = State(initialValue: String(ttlMax))
        _stringTos = State(initialValue: String(tos))
    }
    
    var body: some View {
        List {
            Group {
                Section(header: Text("PROTOCOL").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_trace_PROTOCOL").font(.system(size: 12)) : nil) {
                    HStack {
                        Text("Label_IP_protocol")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: self.$object.traceSettingIpProto) {
                            Text("Label_ICMP").tag(IPPROTO_ICMP)
                            Text("Label_UDP").tag(IPPROTO_UDP)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    if object.traceSettingIpProto == IPPROTO_UDP {
                        HStack {
                            Text("Label_Port_type")
                                .frame(width: 100, alignment: .leading)
                            Picker("", selection: self.$object.traceSettingPortType) {
                                Text("Label_Default").tag(SocPingEcho.valueTypeDefault)
                                Text("Label_Users_port").tag(SocPingEcho.valueTypeUserSet)
                                Text("Label_Random").tag(SocPingEcho.valueTypeRandom)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        if object.traceSettingPortType == SocPingEcho.valueTypeDefault {
                            HStack {
                                Text("Label_Port_number")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("\(SocPingEcho.tracePortDefault)")
                            }
                        }
                        else if object.traceSettingPortType == SocPingEcho.valueTypeUserSet {
                            if !self.isSetBasePort {
                                HStack {
                                    Text("Label_Port_number")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("1 - \(UInt16.max)", text: $stringBasePort)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: .infinity)
                                    Button(action: {
                                        SocLogger.debug("TracerouteSetting: Button: basePort OK")
                                        do {
                                            object.traceSettingUdpPort = try self.getInt(stringValue: self.stringBasePort, min: 1, max: Int(UInt16.max))
                                            self.isSetBasePort = true
                                        }
                                        catch let error as SocPingError {
                                            self.alertTitle = error.message
                                            self.isPopAlert = true
                                        }
                                        catch {
                                            SocLogger.error("TracerouteSetting: \(error)")
                                            assertionFailure("TracerouteSetting: \(error)")
                                            self.isPopAlert = true
                                        }
                                    }) {
                                        Text("Button_OK")
                                            .foregroundColor(Color.init(UIColor.systemBlue))
                                    }
                                }
                                .alert(isPresented: self.$isPopAlert) {
                                    Alert(title: Text(self.alertTitle))
                                }
                            }
                            else {
                                HStack {
                                    Text("Label_Port_number")
                                        .frame(width: 100, alignment: .leading)
                                    Spacer()
                                    Text("\(object.traceSettingUdpPort)")
                                }
                            }
                        }
                        else {  // SocPingEcho.portTypeRandom
                            HStack {
                                Text("Label_Port_number")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("\(SocPingEcho.portRangeStart) - \(UInt16.max)")
                            }
                        }
                    }
                }
                Section(header: Text("PAYLOAD").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_trace_PAYLOAD").font(.system(size: 12)) : nil) {
                    HStack {
                        Text("Label_Data_type")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: self.$object.traceSettingPayloadDataType) {
                            Text("Label_All_Zero").tag(SocPingEcho.payloadTypeZ)
                            Text("Label_All_0xFF").tag(SocPingEcho.payloadTypeF)
                            Text("Label_Continuous").tag(SocPingEcho.payloadTypeC)
                            Text("Label_Random").tag(SocPingEcho.payloadTypeR)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    HStack {
                        Text("Label_Size_type")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: self.$object.traceSettingPayloadSizeType) {
                            Text("Label_Default").tag(SocPingEcho.valueTypeDefault)
                            Text("Label_Users_size").tag(SocPingEcho.valueTypeUserSet)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    if object.traceSettingPayloadSizeType == SocPingEcho.valueTypeDefault {
                        HStack {
                            Text("Label_Data_size")
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            SocPingMenu.getBytes(SocPingTracer.payloadSizeDefault)
                        }
                    }
                    else { // SocPingEcho.valueTypeUserSet
                        if !self.isSetPayloadLen {
                            HStack {
                                Text("Label_Data_size")
                                    .frame(width: 100, alignment: .leading)
                                TextField("0 - \(ICMP_MAXLEN)", text: $stringPayloadLen)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: .infinity)
                                Button(action: {
                                    SocLogger.debug("TracerouteSetting: Button: payloadLen OK")
                                    do {
                                        object.traceSettingPayloadSize = try self.getInt(stringValue: self.stringPayloadLen, min: 0, max: ICMP_MAXLEN)
                                        self.isSetPayloadLen = true
                                    }
                                    catch let error as SocPingError {
                                        self.alertTitle = error.message
                                        self.isPopAlert = true
                                    }
                                    catch {
                                        SocLogger.error("TracerouteSetting: \(error)")
                                        assertionFailure("TracerouteSetting: \(error)")
                                        self.isPopAlert = true
                                    }
                                }) {
                                    Text("Button_OK")
                                        .foregroundColor(Color.init(UIColor.systemBlue))
                                }
                            }
                            .alert(isPresented: self.$isPopAlert) {
                                Alert(title: Text(self.alertTitle))
                            }
                        }
                        else {
                            HStack {
                                Text("Label_Data_size")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                SocPingMenu.getBytes(object.traceSettingPayloadSize)
                            }
                        }
                    }
                }
                Section(header: Text("PROBE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_trace_PROBE").font(.system(size: 12)) : nil) {
                    HStack {
                        Text("Label_Number_of_Probes")
                            .frame(width: 145, alignment: .leading)
                        Picker("", selection: self.$object.traceSettingProbes) {
                            Text("1").tag(1)
                            Text("2").tag(2)
                            Text("3").tag(3)
                            Text("4").tag(4)
                            Text("5").tag(5)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        Text("Label_times")
                    }
                    HStack {
                        Text("Label_Interval_per_Probe")
                            .frame(width: 145, alignment: .leading)
                        Picker("", selection: self.$object.traceSettingPause) {
                            Text("0.0").tag(0)
                            Text("0.1").tag(100)
                            Text("0.3").tag(300)
                            Text("0.5").tag(500)
                            Text("1.0").tag(1000)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        Text("Label_sec")
                    }
                }
                Section(header: Text("WAIT TIME").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_trace_WAIT_TIME").font(.system(size: 12)) : nil) {
                    if !self.isSetWaittime {
                        HStack {
                            TextField("1 - 3600", text: $stringWaittime)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            Button(action: {
                                SocLogger.debug("TracerouteSetting: Button: Waittime OK")
                                do {
                                    object.traceSettingWaittime = try self.getMSec(stringValue: stringWaittime, min: 1.0, max: 3600.0)
                                    self.isSetWaittime = true
                                }
                                catch let error as SocPingError {
                                    self.alertTitle = error.message
                                    self.isPopAlert = true
                                }
                                catch {
                                    SocLogger.error("TracerouteSetting: \(error)")
                                    assertionFailure("TracerouteSetting: \(error)")
                                    self.isPopAlert = true
                                }
                            }) {
                                Text("Button_OK")
                                    .foregroundColor(Color.init(UIColor.systemBlue))
                            }
                        }
                        .alert(isPresented: self.$isPopAlert) {
                            Alert(title: Text(self.alertTitle))
                        }
                    }
                    else {
                        HStack {
                            Spacer()
                            SocPingMenu.getSeconds(object.traceSettingWaittime)
                        }
                    }
                }
            }
            Group {
                Section(header: Text("TIME TO LIVE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_trace_TIME_TO_LIVE").font(.system(size: 12)) : nil) {
                    if !self.isSetTtl {
                        HStack {
                            Text("Label_Min")
                            TextField("1 - \(UInt8.max)", text: $stringTtlFirst)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                                .padding(.trailing, 10)
                            Text("Label_Max")
                            TextField("1 - \(UInt8.max)", text: $stringTtlMax)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            Button(action: {
                                SocLogger.debug("TracerouteSetting: Button: Ttl OK")
                                do {
                                    let ret = try self.getTtl()
                                    object.traceSettingTtlFirst = ret.0
                                    object.traceSettingTtlMax = ret.1
                                    self.isSetTtl = true
                                }
                                catch let error as SocPingError {
                                    self.alertTitle = error.message
                                    self.isPopAlert = true
                                }
                                catch {
                                    SocLogger.error("TracerouteSetting: \(error)")
                                    assertionFailure("TracerouteSetting: \(error)")
                                    self.isPopAlert = true
                                }
                            }) {
                                Text("Button_OK")
                                    .foregroundColor(Color.init(UIColor.systemBlue))
                            }
                        }
                        .alert(isPresented: self.$isPopAlert) {
                            Alert(title: Text(self.alertTitle))
                        }
                    }
                    else {
                        HStack {
                            Text("Label_TTL_range")
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            Text("\(object.traceSettingTtlFirst) - \(object.traceSettingTtlMax)")
                        }
                    }
                }
                Section(header: Text("TYPE OF SERVICE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_trace_TYPE_OF_SERVICE").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.traceSettingUseTos) {
                        Text("Label_Specify_TOS")
                    }
                    if object.traceSettingUseTos {
                        if !self.isSetTos {
                            HStack {
                                Text("Label_TOS_value")
                                    .frame(width: 100, alignment: .leading)
                                TextField("0 - \(UInt8.max)", text: $stringTos)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: .infinity)
                                Button(action: {
                                    SocLogger.debug("TracerouteSetting: Button: Tos OK")
                                    do {
                                        object.traceSettingTos = try self.getInt(stringValue: self.stringTos, min: 0, max: Int(UInt8.max))
                                        self.isSetTos = true
                                    }
                                    catch let error as SocPingError {
                                        self.alertTitle = error.message
                                        self.isPopAlert = true
                                    }
                                    catch {
                                        SocLogger.error("TracerouteSetting: \(error)")
                                        assertionFailure("TracerouteSetting: \(error)")
                                        self.isPopAlert = true
                                    }
                                }) {
                                    Text("Button_OK")
                                        .foregroundColor(Color.init(UIColor.systemBlue))
                                }
                            }
                            .alert(isPresented: self.$isPopAlert) {
                                Alert(title: Text(self.alertTitle))
                            }
                        }
                        else {
                            HStack {
                                Text("Label_TOS_value")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("\(object.traceSettingTos)")
                            }
                        }
                    }
                }
                Section(header: Text("ROUTING TABLE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_trace_ROUTING_TABLE").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.traceSettingDontroute) {
                        Text("Label_Bypass")
                    }
                }
                Section(header: Text("SOURCE INTERFACE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_trace_SOURCE_INTERFACE").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.traceSettingUseSrcIf) {
                        Text("Label_Specify_interface")
                    }
                    if self.object.traceSettingUseSrcIf {
                        VStack {
                            HStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "wifi")
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(object.interfaces[SocPingInterface.deviceTypeWifi].isActive ? Color.init(UIColor.label) : Color.init(UIColor.systemGray))
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(object.interfaces[SocPingInterface.deviceTypeCellurar].isActive ? Color.init(UIColor.label) : Color.init(UIColor.systemGray))
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    Image(systemName: "personalhotspot")
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(object.interfaces[SocPingInterface.deviceTypeHotspot].isActive ? Color.init(UIColor.label) : Color.init(UIColor.systemGray))
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(object.interfaces[SocPingInterface.deviceTypeLoopback].isActive ? Color.init(UIColor.label) : Color.init(UIColor.systemGray))
                                    Spacer()
                                }
                            }
                            Picker("", selection: self.$object.traceSettingInterface) {
                                Text("Label_Wi-Fi").tag(SocPingInterface.deviceTypeWifi)
                                Text("Label_Cellurar").tag(SocPingInterface.deviceTypeCellurar)
                                Text("Label_Hotspot").tag(SocPingInterface.deviceTypeHotspot)
                                Text("Label_Loopback").tag(SocPingInterface.deviceTypeLoopback)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
                Section(header: Text("LOOSE SOURCE ROUTING").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_trace_LOOSE_SOURCE_ROUTING").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.traceSettingUseLsrr) {
                        Text("Label_Enabled")
                    }
                    if object.traceSettingUseLsrr {
                        HStack {
                            VStack {
                                Text("Label_Gateways")
                                    .frame(width: 150, alignment: .leading)
                            }
                            if object.gateways.count > 0 {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(0 ..< object.gateways.count, id: \.self) { i in
                                        HStack {
                                            Image(systemName: "\(i + 1).circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 18, height: 18, alignment: .center)
                                            Text(object.gateways[i].addr)
                                        }
                                        .frame(alignment: .leading)
                                    }
                                }
                                Spacer()
                            }
                            else {
                                Spacer()
                                Text("Label_Not_specified")
                            }
                            ZStack {
                                NavigationLink(destination: SocPingGatewayManager()) {
                                    Text("")
                                }
                                Button(action: {
                                    SocLogger.debug("TracerouteSetting: Button: Gateways")
                                    for j in 0 ..< object.gwOrders.count {
                                        object.gwOrders[j] = 0
                                    }
                                    for i in 0 ..< object.gateways.count {
                                        for j in 0 ..< object.addresses.count {
                                            if object.addresses[j].addr == object.gateways[i].addr {
                                                object.gwOrders[j] = i + 1
                                                break
                                            }
                                        }
                                    }
                                }) {
                                    Text("")
                                }
                            }
                            .frame(width: 20)
                        }
                    }
                }
                Section(header: Text("RESOLVE NAME").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_trace_RESOLVE_NAME").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.traceSettingNameResolved) {
                        Text("Label_Enabled")
                    }
                }

            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Traceroute Settings", displayMode: .inline)
    }
    
    func getInt(stringValue: String, min: Int, max: Int) throws -> Int {
        if stringValue.isEmpty {
            throw SocPingError.NoValue
        }
        guard let value = Int(stringValue) else {
            throw SocPingError.InvalidValue
        }
        if value < min || value > max {
            throw SocPingError.InvalidValue
        }
        return value
    }
    
    func getMSec(stringValue: String, min: Double, max: Double) throws -> Int {
        if stringValue.isEmpty {
            throw SocPingError.NoValue
        }
        guard let value = Double(stringValue) else {
            throw SocPingError.InvalidValue
        }
        if value < min || value > max {
            throw SocPingError.InvalidValue
        }
        return Int(value * 1000.0)
    }
    
    func getTtl() throws -> (Int, Int) {
        if self.stringTtlFirst.isEmpty || self.stringTtlMax.isEmpty {
            throw SocPingError.NoValue
        }
        guard let ttlFirst = Int(self.stringTtlFirst) else {
            throw SocPingError.InvalidValue
        }
        if ttlFirst < 1 || ttlFirst > UInt8.max {
            throw SocPingError.InvalidValue
        }
        guard let ttlMax = Int(self.stringTtlMax) else {
            throw SocPingError.InvalidValue
        }
        if ttlMax < 1 || ttlMax > UInt8.max {
            throw SocPingError.InvalidValue
        }
        if ttlMax < ttlFirst {
            throw SocPingError.InvalidValue
        }
        return (ttlFirst, ttlMax)
    }
}

fileprivate struct OnePingSettings: View {
    @EnvironmentObject var object: SocPingSharedObject
    @State private var stringIcmpId: String
    @State private var stringIcmpSeq: String
    @State private var stringUdpPort: String
    @State private var stringPayloadLen: String
    @State private var stringWaittime: String
    @State private var stringTtl: String
    @State private var stringTos: String
    @State private var isSetIcmpId: Bool = false
    @State private var isSetIcmpSeq: Bool = false
    @State private var isSetUdpPort: Bool = false
    @State private var isSetPayloadLen: Bool = false
    @State private var isSetWaittime: Bool = false
    @State private var isSetTtl: Bool = false
    @State private var isSetTos: Bool = false
    @State private var alertTitle: String = "Unexpected error."
    @State private var isPopAlert: Bool = false
    
    init(icmpId: Int,
         icmpSeq: Int,
         udpPort: Int,
         payloadLen: Int,
         waittime: Int,
         ttl: Int,
         tos: Int) {
        _stringIcmpId = State(initialValue: String(icmpId))
        _stringIcmpSeq = State(initialValue: String(icmpSeq))
        _stringUdpPort = State(initialValue: String(udpPort))
        _stringPayloadLen = State(initialValue: String(payloadLen))
        _stringWaittime = State(initialValue: String(format: "%.3f", Double(waittime) / 1000.0))
        _stringTtl = State(initialValue: String(ttl))
        _stringTos = State(initialValue: String(tos))
    }
    
    var body: some View {
        List {
            Group {
                Section(header: Text("VERBOSE MODE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_VERBOSE_MODE").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.oneSettingVerbose) {
                        Text("Label_Enabled")
                    }
                }
                Section(header: Text("PROTOCOL").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_PROTOCOL").font(.system(size: 12)) : nil) {
                    HStack {
                        Text("Label_IP_protocol")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: self.$object.oneSettingIpProto) {
                            Text("Label_ICMP").tag(IPPROTO_ICMP)
                            Text("Label_UDP").tag(IPPROTO_UDP)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    if object.oneSettingIpProto == IPPROTO_ICMP {
                        HStack {
                            Text("Label_ID_type")
                                .frame(width: 100, alignment: .leading)
                            Picker("", selection: self.$object.oneSettingIdType) {
                                Text("Label_Default").tag(SocPingEcho.valueTypeDefault)
                                Text("Label_Users_id").tag(SocPingEcho.valueTypeUserSet)
                                Text("Label_Random").tag(SocPingEcho.valueTypeRandom)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        if object.oneSettingIdType == SocPingEcho.valueTypeDefault {
                            HStack {
                                Text("Label_ID_value")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("Label_Apps_PID")
                            }
                        }
                        else if object.oneSettingIdType == SocPingEcho.valueTypeUserSet {
                            if !self.isSetIcmpId {
                                HStack {
                                    Text("Label_ID_value")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("0 - \(UInt16.max)", text: $stringIcmpId)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: .infinity)
                                    Button(action: {
                                        SocLogger.debug("OnePingSetting: Button: icmpId OK")
                                        do {
                                            object.oneSettingIcmpId = try self.getInt(stringValue: self.stringIcmpId, min: 0, max: Int(UInt16.max))
                                            self.isSetIcmpId = true
                                        }
                                        catch let error as SocPingError {
                                            self.alertTitle = error.message
                                            self.isPopAlert = true
                                        }
                                        catch {
                                            SocLogger.error("OnePingSetting: \(error)")
                                            assertionFailure("OnePingSetting: \(error)")
                                            self.isPopAlert = true
                                        }
                                    }) {
                                        Text("Button_OK")
                                            .foregroundColor(Color.init(UIColor.systemBlue))
                                    }
                                }
                                .alert(isPresented: self.$isPopAlert) {
                                    Alert(title: Text(self.alertTitle))
                                }
                            }
                            else {
                                HStack {
                                    Text("Label_ID_value")
                                        .frame(width: 100, alignment: .leading)
                                    Spacer()
                                    Text("\(object.oneSettingIcmpId)")
                                }
                            }
                        }
                        else {  // SocPingEcho.idTypeRandom
                            HStack {
                                Text("Label_ID_value")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("0 - \(UInt16.max)")
                            }
                        }
                        HStack {
                            Text("Label_SEQ_type")
                                .frame(width: 100, alignment: .leading)
                            Picker("", selection: self.$object.oneSettingSeqType) {
                                Text("Label_Default").tag(SocPingEcho.valueTypeDefault)
                                Text("Label_Users_seq").tag(SocPingEcho.valueTypeUserSet)
                                Text("Label_Random").tag(SocPingEcho.valueTypeRandom)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        if object.oneSettingSeqType == SocPingEcho.valueTypeDefault {
                            HStack {
                                Text("Label_SEQ_value")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("0")
                            }
                        }
                        else if object.oneSettingSeqType == SocPingEcho.valueTypeUserSet {
                            if !self.isSetIcmpSeq {
                                HStack {
                                    Text("Label_SEQ_value")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("0 - \(UInt16.max)", text: $stringIcmpSeq)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: .infinity)
                                    Button(action: {
                                        SocLogger.debug("OnePingSetting: Button: icmpSeq OK")
                                        do {
                                            object.oneSettingIcmpSeq = try self.getInt(stringValue: self.stringIcmpSeq, min: 0, max: Int(UInt16.max))
                                            self.isSetIcmpSeq = true
                                        }
                                        catch let error as SocPingError {
                                            self.alertTitle = error.message
                                            self.isPopAlert = true
                                        }
                                        catch {
                                            SocLogger.error("OnePingSetting: \(error)")
                                            assertionFailure("OnePingSetting: \(error)")
                                            self.isPopAlert = true
                                        }
                                    }) {
                                        Text("Button_OK")
                                            .foregroundColor(Color.init(UIColor.systemBlue))
                                    }
                                }
                                .alert(isPresented: self.$isPopAlert) {
                                    Alert(title: Text(self.alertTitle))
                                }
                            }
                            else {
                                HStack {
                                    Text("Label_SEQ_value")
                                        .frame(width: 100, alignment: .leading)
                                    Spacer()
                                    Text("\(object.oneSettingIcmpSeq)")
                                }
                            }
                        }
                        else {  // SocPingEcho.idTypeRandom
                            HStack {
                                Text("Label_SEQ_value")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("0 - \(UInt16.max)")
                            }
                        }
                    }
                    else {  // UDP
                        HStack {
                            Text("Label_Port_type")
                                .frame(width: 100, alignment: .leading)
                            Picker("", selection: self.$object.oneSettingPortType) {
                                Text("Label_Default").tag(SocPingEcho.valueTypeDefault)
                                Text("Label_Users_port").tag(SocPingEcho.valueTypeUserSet)
                                Text("Label_Random").tag(SocPingEcho.valueTypeRandom)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        if object.oneSettingPortType == SocPingEcho.valueTypeDefault {
                            HStack {
                                Text("Label_Port_number")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("\(SocPingEcho.pingPortDefault)")
                            }
                        }
                        else if object.oneSettingPortType == SocPingEcho.valueTypeUserSet {
                            if !self.isSetUdpPort {
                                HStack {
                                    Text("Label_Port_number")
                                        .frame(width: 100, alignment: .leading)
                                    TextField("1 - \(UInt16.max)", text: $stringUdpPort)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(maxWidth: .infinity)
                                    Button(action: {
                                        SocLogger.debug("OnePingSetting: Button: udpPort OK")
                                        do {
                                            object.oneSettingUdpPort = try self.getInt(stringValue: self.stringUdpPort, min: 1, max: Int(UInt16.max))
                                            self.isSetUdpPort = true
                                        }
                                        catch let error as SocPingError {
                                            self.alertTitle = error.message
                                            self.isPopAlert = true
                                        }
                                        catch {
                                            SocLogger.error("OnePingSetting: \(error)")
                                            assertionFailure("OnePingSetting: \(error)")
                                            self.isPopAlert = true
                                        }
                                    }) {
                                        Text("Button_OK")
                                            .foregroundColor(Color.init(UIColor.systemBlue))
                                    }
                                }
                                .alert(isPresented: self.$isPopAlert) {
                                    Alert(title: Text(self.alertTitle))
                                }
                            }
                            else {
                                HStack {
                                    Text("Label_Port_number")
                                        .frame(width: 100, alignment: .leading)
                                    Spacer()
                                    Text("\(object.oneSettingUdpPort)")
                                }
                            }
                        }
                        else {  // SocPingEcho.portTypeRandom
                            HStack {
                                Text("Label_Port_number")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("\(SocPingEcho.portRangeStart) - \(UInt16.max)")
                            }
                        }
                    }
                }
                Section(header: Text("PAYLOAD").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_PAYLOAD").font(.system(size: 12)) : nil) {
                    HStack {
                        Text("Label_Data_type")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: self.$object.oneSettingPayloadDataType) {
                            Text("Label_All_Zero").tag(SocPingEcho.payloadTypeZ)
                            Text("Label_All_0xFF").tag(SocPingEcho.payloadTypeF)
                            Text("Label_Continuous").tag(SocPingEcho.payloadTypeC)
                            Text("Label_Random").tag(SocPingEcho.payloadTypeR)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    HStack {
                        Text("Label_Size_type")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: self.$object.oneSettingPayloadSizeType) {
                            Text("Label_Default").tag(SocPingEcho.valueTypeDefault)
                            Text("Label_Users_size").tag(SocPingEcho.valueTypeUserSet)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    if object.oneSettingPayloadSizeType == SocPingEcho.valueTypeDefault {
                        HStack {
                            Text("Label_Data_size")
                                .frame(width: 100, alignment: .leading)
                            Spacer()
                            SocPingMenu.getBytes(SocPingOnePinger.payloadSizeDefault)
                        }
                    }
                    else {  // SocPingEcho.valueTypeUserSet
                        if !self.isSetPayloadLen {
                            HStack {
                                Text("Label_Data_size")
                                    .frame(width: 100, alignment: .leading)
                                TextField("0 - \(ICMP_MAXLEN)", text: $stringPayloadLen)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: .infinity)
                                Button(action: {
                                    SocLogger.debug("OnePingSetting: Button: payloadLen OK")
                                    do {
                                        object.oneSettingPayloadSize = try self.getInt(stringValue: self.stringPayloadLen, min: 0, max: ICMP_MAXLEN)
                                        self.isSetPayloadLen = true
                                    }
                                    catch let error as SocPingError {
                                        self.alertTitle = error.message
                                        self.isPopAlert = true
                                    }
                                    catch {
                                        SocLogger.error("OnePingSetting: \(error)")
                                        assertionFailure("OnePingSetting: \(error)")
                                        self.isPopAlert = true
                                    }
                                }) {
                                    Text("Button_OK")
                                        .foregroundColor(Color.init(UIColor.systemBlue))
                                }
                            }
                            .alert(isPresented: self.$isPopAlert) {
                                Alert(title: Text(self.alertTitle))
                            }
                        }
                        else {
                            HStack {
                                Text("Label_Data_size")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                SocPingMenu.getBytes(object.oneSettingPayloadSize)
                            }
                        }
                    }
                }
                Section(header: Text("WAIT TIME").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_WAIT_TIME").font(.system(size: 12)) : nil) {
                    if !self.isSetWaittime {
                        HStack {
                            TextField("0.1 - 3600.0", text: $stringWaittime)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            Button(action: {
                                SocLogger.debug("OnePingSetting: Button: Waittime OK")
                                do {
                                    object.oneSettingWaittime = try self.getMSec(stringValue: stringWaittime, min: 0.1, max: 3600.0)
                                    self.isSetWaittime = true
                                }
                                catch let error as SocPingError {
                                    self.alertTitle = error.message
                                    self.isPopAlert = true
                                }
                                catch {
                                    SocLogger.error("OnePingSetting: \(error)")
                                    assertionFailure("OnePingSetting: \(error)")
                                    self.isPopAlert = true
                                }
                            }) {
                                Text("Button_OK")
                                    .foregroundColor(Color.init(UIColor.systemBlue))
                            }
                        }
                        .alert(isPresented: self.$isPopAlert) {
                            Alert(title: Text(self.alertTitle))
                        }
                    }
                    else {
                        HStack {
                            Spacer()
                            SocPingMenu.getSeconds(object.oneSettingWaittime)
                        }
                    }
                }
            }
            Group {
                Section(header: Text("TIME TO LIVE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_TIME_TO_LIVE").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.oneSettingUseTtl) {
                        Text("Label_Specify_TTL")
                    }
                    if object.oneSettingUseTtl {
                        if !self.isSetTtl {
                            HStack {
                                Text("Label_TTL_value")
                                    .frame(width: 100, alignment: .leading)
                                TextField("1 - \(UInt8.max)", text: $stringTtl)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: .infinity)
                                Button(action: {
                                    SocLogger.debug("OnePingSetting: Button: ttl OK")
                                    do {
                                        object.oneSettingTtl = try self.getInt(stringValue: self.stringTtl, min: 1, max: Int(UInt8.max))
                                        self.isSetTtl = true
                                    }
                                    catch let error as SocPingError {
                                        self.alertTitle = error.message
                                        self.isPopAlert = true
                                    }
                                    catch {
                                        SocLogger.error("OnePingSetting: \(error)")
                                        assertionFailure("OnePingSetting: \(error)")
                                        self.isPopAlert = true
                                    }
                                }) {
                                    Text("Button_OK")
                                        .foregroundColor(Color.init(UIColor.systemBlue))
                                }
                            }
                            .alert(isPresented: self.$isPopAlert) {
                                Alert(title: Text(self.alertTitle))
                            }
                        }
                        else {
                            HStack {
                                Text("Label_TTL_value")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("\(object.oneSettingTtl)")
                            }
                        }
                    }
                }
                Section(header: Text("TYPE OF SERVICE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_TYPE_OF_SERVICE").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.oneSettingUseTos) {
                        Text("Label_Specify_TOS")
                    }
                    if object.oneSettingUseTos {
                        if !self.isSetTos {
                            HStack {
                                Text("Label_TOS_value")
                                    .frame(width: 100, alignment: .leading)
                                TextField("0 - \(UInt8.max)", text: $stringTos)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: .infinity)
                                Button(action: {
                                    SocLogger.debug("OnePingSetting: Button: Tos OK")
                                    do {
                                        object.oneSettingTos = try self.getInt(stringValue: self.stringTos, min: 0, max: Int(UInt8.max))
                                        self.isSetTos = true
                                    }
                                    catch let error as SocPingError {
                                        self.alertTitle = error.message
                                        self.isPopAlert = true
                                    }
                                    catch {
                                        SocLogger.error("OnePingSetting: \(error)")
                                        assertionFailure("OnePingSetting: \(error)")
                                        self.isPopAlert = true
                                    }
                                }) {
                                    Text("Button_OK")
                                        .foregroundColor(Color.init(UIColor.systemBlue))
                                }
                            }
                            .alert(isPresented: self.$isPopAlert) {
                                Alert(title: Text(self.alertTitle))
                            }
                        }
                        else {
                            HStack {
                                Text("Label_TOS_value")
                                    .frame(width: 100, alignment: .leading)
                                Spacer()
                                Text("\(object.oneSettingTos)")
                            }
                        }
                    }
                }
                Section(header: Text("ROUTING TABLE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_ROUTING_TABLE").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.oneSettingDontroute) {
                        Text("Label_Bypass")
                    }
                }
                Section(header: Text("MULTICAST LOOPBACK").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_MULTICAST_LOOPBACK").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.oneSettingNoLoop) {
                        Text("Label_Suppress")
                    }
                }
                Section(header: Text("SOURCE INTERFACE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_SOURCE_INTERFACE").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.oneSettingUseSrcIf) {
                        Text("Label_Specify_interface")
                    }
                    if self.object.oneSettingUseSrcIf {
                        VStack {
                            HStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "wifi")
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(object.interfaces[SocPingInterface.deviceTypeWifi].isActive ? Color.init(UIColor.label) : Color.init(UIColor.systemGray))
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(object.interfaces[SocPingInterface.deviceTypeCellurar].isActive ? Color.init(UIColor.label) : Color.init(UIColor.systemGray))
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    Image(systemName: "personalhotspot")
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(object.interfaces[SocPingInterface.deviceTypeHotspot].isActive ? Color.init(UIColor.label) : Color.init(UIColor.systemGray))
                                    Spacer()
                                }
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(object.interfaces[SocPingInterface.deviceTypeLoopback].isActive ? Color.init(UIColor.label) : Color.init(UIColor.systemGray))
                                    Spacer()
                                }
                            }
                            Picker("", selection: self.$object.oneSettingInterface) {
                                Text("Label_Wi-Fi").tag(SocPingInterface.deviceTypeWifi)
                                Text("Label_Cellurar").tag(SocPingInterface.deviceTypeCellurar)
                                Text("Label_Hotspot").tag(SocPingInterface.deviceTypeHotspot)
                                Text("Label_Loopback").tag(SocPingInterface.deviceTypeLoopback)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
                Section(header: Text("LOOSE SOURCE ROUTING").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_LOOSE_SOURCE_ROUTING").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.oneSettingUseLsrr) {
                        Text("Label_Enabled")
                    }
                    if object.oneSettingUseLsrr {
                        HStack {
                            VStack {
                                Text("Label_Gateways")
                                    .frame(width: 150, alignment: .leading)
                            }
                            if object.gateways.count > 0 {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(0 ..< object.gateways.count, id: \.self) { i in
                                        HStack {
                                            Image(systemName: "\(i + 1).circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 18, height: 18, alignment: .center)
                                            Text(object.gateways[i].addr)
                                        }
                                        .frame(alignment: .leading)
                                    }
                                }
                                Spacer()
                            }
                            else {
                                Spacer()
                                Text("Label_Not_specified")
                            }
                            ZStack {
                                NavigationLink(destination: SocPingGatewayManager()) {
                                    Text("")
                                }
                                Button(action: {
                                    SocLogger.debug("OnePingSetting: Button: Gateways")
                                    for j in 0 ..< object.gwOrders.count {
                                        object.gwOrders[j] = 0
                                    }
                                    for i in 0 ..< object.gateways.count {
                                        for j in 0 ..< object.addresses.count {
                                            if object.addresses[j].addr == object.gateways[i].addr {
                                                object.gwOrders[j] = i + 1
                                                break
                                            }
                                        }
                                    }
                                }) {
                                    Text("")
                                }
                            }
                            .frame(width: 20)
                        }
                    }
                }
                Section(header: Text("RECORD ROUTE").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_one_RECORD_ROUTE").font(.system(size: 12)) : nil) {
                    Toggle(isOn: self.$object.oneSettingUseRr) {
                        Text("Label_Enabled")
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("One Ping Settings", displayMode: .inline)
    }
    
    func getInt(stringValue: String, min: Int, max: Int) throws -> Int {
        if stringValue.isEmpty {
            throw SocPingError.NoValue
        }
        guard let value = Int(stringValue) else {
            throw SocPingError.InvalidValue
        }
        if value < min || value > max {
            throw SocPingError.InvalidValue
        }
        return value
    }
    
    func getMSec(stringValue: String, min: Double, max: Double) throws -> Int {
        if stringValue.isEmpty {
            throw SocPingError.NoValue
        }
        guard let value = Double(stringValue) else {
            throw SocPingError.InvalidValue
        }
        if value < min || value > max {
            throw SocPingError.InvalidValue
        }
        return Int(value * 1000.0)
    }
}

fileprivate struct SocPingLogViewer: View {
    @EnvironmentObject var object: SocPingSharedObject
    @Binding var text: String
    @State private var copyMessage: String = ""
    @State private var isAlerting: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                SocPingScreen(text: self.$text)
                if object.orientation.isPortrait {
                    HStack(spacing: 0) {
                        Form {
                            Button(action: {
                                SocLogger.debug("SocPingLogViewer: Button: Reload")
                                self.text = SocLogger.getLog()
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.clockwise")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 19, height: 19, alignment: .center)
                                    Text("Button_Reload2")
                                        .padding(.leading, 5)
                                    Spacer()
                                }
                            }
                        }
                        Form {
                            Button(action: {
                                SocLogger.debug("SocPingLogViewer: Button: Copy")
                                self.text = SocLogger.getLog()
                                UIPasteboard.general.string = self.text
                                DispatchQueue.global().async {
                                    usleep(500000)
                                    isAlerting = true
                                    usleep(1500000)
                                    isAlerting = false
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "doc.on.doc")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 19, height: 19, alignment: .center)
                                    Text("Button_Copy")
                                        .padding(.leading, 5)
                                    Spacer()
                                }
                            }
                        }
                        Form {
                            Button(action: {
                                SocLogger.debug("SocPingLogViewer: Button: Clear")
                                SocLogger.clearLog()
                                self.text = SocLogger.getLog()
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "trash")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 19, height: 19, alignment: .center)
                                    Text("Button_Clear")
                                        .padding(.leading, 5)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(height: 110)
                }
            }
            .navigationBarTitle(Text("Log Viewer"), displayMode: .inline)
            .blur(radius: isAlerting ? 2 : 0)
            
            if isAlerting {
                VStack() {
                    Text("Message_Copied_to_clipboard")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(10)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        .foregroundColor(Color(object.appSettingScreenColorInverted ? .label : .systemBackground))
                        .background(Color(object.appSettingScreenColorInverted ? .systemBackground : .label).opacity(0.85))
                        .cornerRadius(20.0)
                    Spacer()
                }
                .padding(20)
            }
        }
    }
}

fileprivate struct AboutApp: View {
    @EnvironmentObject var object: SocPingSharedObject
    @State private var alertTitle: String = "Unexpected error."
    @State private var isPopAlert: Bool = false
    
    var body: some View {
        VStack {
            Image("SplashImage")
                .resizable()
                .scaledToFit()
                .frame(width: 80, alignment: .center)
            Text("SocPing")
                .font(.system(size: 26, weight: .bold))
            Text("version " + object.appVersion)
                .font(.system(size: 16))
                .padding(.bottom, 5)

            Text("This app is simple pinger with low-level POSIX socket API.")
                .font(.system(size: 11))
            Button(action: {
                SocLogger.debug("SocPingMenu: Button: webpage")
                do {
                    let url = URL(string: SocPingSharedObject.isJa ? URL_WEBPAGE_JA : URL_WEBPAGE)!
                    guard UIApplication.shared.canOpenURL(url) else {
                        throw SocPingError.CantOpenURL
                    }
                    UIApplication.shared.open(url)
                }
                catch let error as SocPingError {
                    self.alertTitle = error.message
                    self.isPopAlert = true
                }
                catch {
                    SocLogger.error("AppVersion: \(error)")
                    assertionFailure("AppVersion: \(error)")
                    self.isPopAlert = true
                }
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "safari")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("Developer Website")
                        .font(.system(size: 11))
                    Spacer()
                }
                .padding(.bottom, 5)
            }
            
            Text("Support OS: iOS 14.0 or newer")
                .font(.system(size: 11))
            Text("Localization: en, ja")
                .font(.system(size: 11))
                .padding(.bottom, 20)
            
            Text("Please feel free to contact me if you have any feedback.")
                .font(.system(size: 11))
            Button(action: {
                SocLogger.debug("SocPingMenu: Button: mailto")
                let url = URL(string: "mailto:" + MAIL_ADDRESS)!
                UIApplication.shared.open(url)
            }) {
                Text(MAIL_ADDRESS)
                    .font(.system(size: 12))
                    .padding(5)
            }
            
            Text(COPYRIGHT)
                .font(.system(size: 11))
                .foregroundColor(Color.init(UIColor.systemGray))
        }
        .navigationBarTitle("About App", displayMode: .inline)
    }
}
