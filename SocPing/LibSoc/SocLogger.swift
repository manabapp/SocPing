//
//  SocLogger.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//

import Darwin
import Foundation

class SocLogger {
    static var logBuffer: String = ""
    static var logCount: Int = 0
    static var isStopLog: Bool = true
    static var dateFormatter = DateFormatter()
    static var timeFormatter = DateFormatter()
    static var response: Double = 0.0
    static var isDebug: Bool = false    // output with debug()
    static var traceLevel: Int = traceLevelNone
    
    static let traceLevelNone: Int = 0  // Not output
    static let traceLevelCall: Int = 1  // output with trace()
    static let traceLevelDump: Int = 2  // output with trace() and dataDump()
    
    static let logMaxLines = 10000
    static let dumpMaxSize = 512
    static let logDumpMaxLen = 16
    static let protocolFamilies = [PF_INET]
    static let protocolFamilyNames = ["PF_INET"]
    static let socketTypes = [SOCK_DGRAM]
    static let socketTypeNames = ["SOCK_DGRAM"]
    static let protocols = [0, IPPROTO_ICMP, IPPROTO_UDP]
    static let protocolNames = ["0", "IPPROTO_ICMP", "IPPROTO_UDP"]
    static let eventBits = [POLLIN, POLLPRI, POLLOUT, POLLERR, POLLHUP, POLLNVAL]
    static let eventBitNames = ["POLLIN", "POLLPRI", "POLLOUT", "POLLERR", "POLLHUP", "POLLNVAL"]
    static let optvals = [IPOPT_EOL, IPOPT_NOP, IPOPT_RR, IPOPT_TS, IPOPT_SECURITY, IPOPT_LSRR, IPOPT_SATID, IPOPT_SSRR, IPOPT_RA]
    static let optvalNames = ["IPOPT_EOL", "IPOPT_NOP", "IPOPT_RR", "IPOPT_TS", "IPOPT_SECURITY", "IPOPT_LSRR", "IPOPT_SATID", "IPOPT_SSRR", "IPOPT_RA"]
    static let printableLetters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~ "
    
    // Can be executed only from SocSocket.initSoc().
    static func startLog() {
        timeFormatter.calendar = Calendar(identifier: .gregorian)
        timeFormatter.locale = Locale(identifier: "C")
        timeFormatter.timeZone = .current
        timeFormatter.dateFormat = "HH:mm:ss.SSS"
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "C")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = " (MMM dd, YYYY) "
        SocLogger.logBuffer = ""
        SocLogger.logCount = 0
        isStopLog = false
    }
    
    static func enableDebug() {
        SocLogger.isDebug = true
    }
    
    static func disableDebug() {
        SocLogger.isDebug = false
    }
    
    static func setTraceLevel(_ level: Int) {
        if traceLevel < SocLogger.traceLevelNone || traceLevel > SocLogger.traceLevelDump {
            SocLogger.traceLevel = SocLogger.traceLevelNone
        }
        SocLogger.traceLevel = level
    }
    
    static func getLog() -> String {
        return SocLogger.logBuffer
    }
    
    static func resetLog() {
        SocLogger.logBuffer = ""
        SocLogger.logCount = 0
        SocLogger.isStopLog = false
        SocLogger.push("Reset")
    }
    
    static func getCount() -> Int {
        return SocLogger.logCount
    }
    
    static func getHdrAscii(data: Data, length: Int) -> String {
        if data.count == 0 {
            return "\"\""
        }
        if SocLogger.traceLevel == SocLogger.traceLevelDump {
            return "<DATA>"
        }
        
        var index: Int = 0
        var dumpString: String = "\""
        let bytes = data.uint8array!
        while index < data.count && index < length {
            if index > SocLogger.logDumpMaxLen {
                dumpString += "\"..."
                return dumpString
            }
            dumpString += SocLogger.printableLetters.contains(bytes[index].char) ? String(format: "%c", bytes[index]) : "."
            index += 1
        }
        dumpString += "\""
        return dumpString
    }
    
    static func getEventsMask(_ events: Int32) -> String {
        var maskString: String = ""
        var isAnySet: Bool = false
        
        for i in 0 ..< SocLogger.eventBits.count {
            if (events & SocLogger.eventBits[i]) == SocLogger.eventBits[i] {
                if isAnySet {
                    maskString += "|"
                }
                maskString += SocLogger.eventBitNames[i]
                isAnySet = true
            }
        }
        if maskString.isEmpty {
            return "0"
        }
        return maskString
    }
    
    static func setResponse(_ start: Date) {
        let now = Date()
        SocLogger.response = now.timeIntervalSince(start)
    }
    
    static func getResponse() -> Double {
        return SocLogger.response
    }
    
    // Internal log for LibSoc
    static func push(_ text: String) {
#if DEBUG
        print(text)
#endif
        SocLogger.logBuffer += SocLogger.timeFormatter.string(from: Date())
        SocLogger.logBuffer += SocLogger.dateFormatter.string(from: Date())
        SocLogger.logBuffer += text
        SocLogger.logBuffer += "\n"
        SocLogger.logCount += 1
    }
    
    // Always outputs important information
    static func error(_ text: String) {
#if DEBUG
        print("[ERROR] \(text)")
#endif
        SocLogger.logBuffer += SocLogger.timeFormatter.string(from: Date())
        SocLogger.logBuffer += " [ERROR___] "
        SocLogger.logBuffer += text
        SocLogger.logBuffer += "\n"
        SocLogger.logCount += 1
        if SocLogger.logCount >= SocLogger.logMaxLines {
            SocLogger.push("Reached the limit of log lines")
            SocLogger.isStopLog = true
        }
    }
    
    // If only debug enabled, outputs important information
    static func debug(_ text: String) {
#if DEBUG
        print("[DEBUG] \(text)")
#endif
        if SocLogger.isStopLog || !SocLogger.isDebug {
            return
        }
        SocLogger.logBuffer += SocLogger.timeFormatter.string(from: Date())
        SocLogger.logBuffer += " [--------] "
        SocLogger.logBuffer += text
        SocLogger.logBuffer += "\n"
        SocLogger.logCount += 1
        if SocLogger.logCount >= SocLogger.logMaxLines {
            SocLogger.push("Reached the limit of log lines")
            SocLogger.isStopLog = true
        }
    }
    
    static func trace(funcName: String, argsText: String, retval: Int32) {
        var text: String = ""
        text += "\(funcName)(\(argsText)) = \(retval)"
        if retval < 0 {
            text += "  Err#\(errno) \(errnoNames[Int(errno)])"
        }
#if DEBUG
        print(text)
#endif
        if SocLogger.isStopLog || SocLogger.traceLevel < SocLogger.traceLevelCall {
            return
        }
        SocLogger.logBuffer += SocLogger.timeFormatter.string(from: Date())
        SocLogger.logBuffer += String(format: " [%.6f] ", SocLogger.response)
        SocLogger.logBuffer += text
        SocLogger.logBuffer += "\n"
        SocLogger.logCount += 1
        if SocLogger.logCount >= SocLogger.logMaxLines {
            SocLogger.push("Reached the limit of log lines")
            SocLogger.isStopLog = true
        }
    }
    
    // Not output into console
    static func dataDump(data: Data, length: Int, label: String = "") {
        if length == 0 || SocLogger.isStopLog || SocLogger.traceLevel < SocLogger.traceLevelDump {
            return
        }
        if !label.isEmpty {
            SocLogger.logBuffer += label
            SocLogger.logBuffer += "\n"
            SocLogger.logCount += 1
        }
        var index: Int = 0
        var num: Int = 0
        var dumpString: String = ""
        var detailString: String = ""
        let bytes = data.uint8array!
        while index < bytes.count && index < length {
            dumpString = String(format: " %04d:  ", index)
            if index >= SocLogger.dumpMaxSize {
                dumpString += "=== MORE ===\n"
                SocLogger.logBuffer += dumpString
                SocLogger.logCount += 1
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
            dumpString += "\n"
            SocLogger.logBuffer += dumpString
            SocLogger.logCount += 1
        }
    }
}
