//
//  SocLogger.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//  Changed by Hirose Manabu on 2021/02/12. (version 1.1)
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
    static var traceLevel: Int = traceLevelNoData
    
    static let traceLevelNoData: Int = 0  // Level 1: No data in send/recv system call
    static let traceLevelInLine: Int = 1  // Level 2: Includes first 16 bytes into the line of send/recv system call
    static let traceLevelHexDump: Int = 2 // Level 3: Hex dump in addtion to send/recv system call
    
    static let logMaxLines = 10000
    static let dumpMaxSize = 512
    static let logDumpMaxLen = 16
    static let protocolFamilies = [PF_INET, PF_UNIX]
    static let protocolFamilyNames = ["PF_INET", "PF_UNIX"]
    static let socketTypes = [SOCK_STREAM, SOCK_DGRAM]
    static let socketTypeNames = ["SOCK_STREAM", "SOCK_DGRAM"]
    static let protocols = [0, IPPROTO_TCP, IPPROTO_UDP, IPPROTO_ICMP]
    static let protocolNames = ["0", "IPPROTO_TCP", "IPPROTO_UDP", "IPPROTO_ICMP"]
    static let eventBits = [POLLIN, POLLPRI, POLLOUT, POLLERR, POLLHUP, POLLNVAL]
    static let eventBitNames = ["POLLIN", "POLLPRI", "POLLOUT", "POLLERR", "POLLHUP", "POLLNVAL"]
    static let msgFlagBits = [MSG_OOB, MSG_PEEK, MSG_DONTROUTE, MSG_EOR, MSG_TRUNC, MSG_CTRUNC, MSG_WAITALL, MSG_DONTWAIT, MSG_EOF, MSG_WAITSTREAM, MSG_FLUSH, MSG_HOLD, MSG_SEND, MSG_HAVEMORE, MSG_RCVMORE, MSG_NEEDSA, MSG_NOSIGNAL]
    static let msgFlagBitNames = ["MSG_OOB", "MSG_PEEK", "MSG_DONTROUTE", "MSG_EOR", "MSG_TRUNC", "MSG_CTRUNC", "MSG_WAITALL", "MSG_DONTWAIT", "MSG_EOF", "MSG_WAITSTREAM", "MSG_FLUSH", "MSG_HOLD", "MSG_SEND", "MSG_HAVEMORE", "MSG_RCVMORE", "MSG_NEEDSA", "MSG_NOSIGNAL"]
    static let fileFlagBits = [O_RDONLY, O_WRONLY, O_RDWR, O_ACCMODE, O_NONBLOCK, O_APPEND, O_SHLOCK, O_EXLOCK, O_ASYNC, O_FSYNC, O_NOFOLLOW, O_CREAT, O_TRUNC, O_EXCL, O_EVTONLY, O_NOCTTY, O_DIRECTORY, O_SYMLINK, O_CLOEXEC]
    static let fileFlagBitNames = ["O_RDONLY", "O_WRONLY", "O_RDWR", "O_ACCMODE", "O_NONBLOCK", "O_APPEND", "O_SHLOCK", "O_EXLOCK", "O_ASYNC", "O_FSYNC", "O_NOFOLLOW", "O_CREAT", "O_TRUNC", "O_EXCL", "O_EVTONLY", "O_NOCTTY", "O_DIRECTORY", "O_SYMLINK", "O_CLOEXEC"]
    static let optvals = [IPOPT_EOL, IPOPT_NOP, IPOPT_RR, IPOPT_TS, IPOPT_SECURITY, IPOPT_LSRR, IPOPT_SATID, IPOPT_SSRR, IPOPT_RA]
    static let optvalNames = ["IPOPT_EOL", "IPOPT_NOP", "IPOPT_RR", "IPOPT_TS", "IPOPT_SECURITY", "IPOPT_LSRR", "IPOPT_SATID", "IPOPT_SSRR", "IPOPT_RA"]
    static let howNames = ["SHUT_RD", "SHUT_WR", "SHUT_RDWR"]
    static let tcpStateNames = ["CLOSED", "LISTEN", "SYN_SENT", "SYN_RECEIVED", "ESTABLISHED", "CLOSE_WAIT", "FIN_WAIT_1", "CLOSING", "LAST_ACK", "FIN_WAIT_2", "TIME_WAIT"]
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
        dateFormatter.dateFormat = "MMM dd, yyyy"
        Self.logBuffer = ""
        Self.logCount = 0
        isStopLog = false
    }
    
    static func enableDebug() {
        Self.isDebug = true
    }
    
    static func disableDebug() {
        Self.isDebug = false
    }
    
    static func setTraceLevel(_ level: Int) {
        if traceLevel >= Self.traceLevelNoData && traceLevel <= Self.traceLevelHexDump {
            Self.traceLevel = level
        }
    }
    
    static func getLog() -> String {
        return Self.logBuffer
    }
    
    static func clearLog() {
        Self.logBuffer = ""
        Self.logCount = 0
        Self.isStopLog = false
        Self.push()
    }
    
    static func getCount() -> Int {
        return Self.logCount
    }
    
    static func upCount() {
        Self.logCount += 1
        if !Self.isStopLog && Self.logCount >= Self.logMaxLines {
            Self.push("Reached the limit of log lines")
            Self.logCount += 1
            Self.isStopLog = true
        }
    }

    static func getHdrAscii(data: Data, length: Int) -> String {
        if data.count == 0 {
            return "\"\""
        }
        if Self.traceLevel != Self.traceLevelInLine {
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
            dumpString += Self.printableLetters.contains(bytes[index].char) ? String(format: "%c", bytes[index]) : "."
            index += 1
        }
        dumpString += "\""
        return dumpString
    }
    
    static func getEventsMask(_ events: Int32) -> String {
        var maskString: String = ""
        var isAnySet: Bool = false
        
        for i in 0 ..< Self.eventBits.count {
            if (events & Self.eventBits[i]) == Self.eventBits[i] {
                if isAnySet {
                    maskString += "|"
                }
                maskString += Self.eventBitNames[i]
                isAnySet = true
            }
        }
        if maskString.isEmpty {
            return "0"
        }
        return maskString
    }
    
    static func getMsgFlagsMask(_ msgFlags: Int32) -> String {
        var maskString: String = ""
        for i in 0 ..< Self.msgFlagBits.count {
            if (msgFlags & Self.msgFlagBits[i]) == Self.msgFlagBits[i] {
                if !maskString.isEmpty {
                    maskString += "|"
                }
                maskString += Self.msgFlagBitNames[i]
            }
        }
        return maskString.isEmpty ? "0" : maskString
    }
    
    static func getFileFlagsMask(fileFlags: Int32, isCheckRdOnly: Bool = false) -> String {
        var maskString: String = ""
        for i in 1 ..< Self.fileFlagBits.count {
            if (fileFlags & Self.fileFlagBits[i]) == Self.fileFlagBits[i] {
                if !maskString.isEmpty {
                    maskString += "|"
                }
                maskString += Self.fileFlagBitNames[i]
            }
        }
        if isCheckRdOnly {
            return maskString.isEmpty ? fileFlagBitNames[0] : maskString
        }
        return maskString.isEmpty ? "0" : maskString
    }
    
    static func setResponse(_ start: Date) {
        let now = Date()
        Self.response = now.timeIntervalSince(start)
    }
    
    static func getResponse() -> Double {
        return Self.response
    }
    
    // Internal log for LibSoc
    static func push(_ text: String = "") {
#if DEBUG
        if !text.isEmpty {
            print(text)
        }
#endif
        Self.logBuffer += Self.timeFormatter.string(from: Date())
        Self.logBuffer += " "
        Self.logBuffer += Self.dateFormatter.string(from: Date())
        Self.logBuffer += " - \(TimeZone.current)\n"
        Self.upCount()
        if !text.isEmpty {
            Self.logBuffer += Self.timeFormatter.string(from: Date())
            Self.logBuffer += " "
            Self.logBuffer += text
            Self.logBuffer += "\n"
            Self.upCount()
        }
    }
    
    // Always outputs important information
    static func error(_ text: String) {
#if DEBUG
        print("[ERROR] \(text)")
#endif
        Self.logBuffer += Self.timeFormatter.string(from: Date())
        Self.logBuffer += " [ERROR___] "
        Self.logBuffer += text
        Self.logBuffer += "\n"
        Self.upCount()
    }
    
    // If only debug enabled, outputs important information
    static func debug(_ text: String) {
#if DEBUG
        print("[DEBUG] \(text)")
#endif
        if Self.isStopLog || !Self.isDebug {
            return
        }
        Self.logBuffer += Self.timeFormatter.string(from: Date())
        Self.logBuffer += " [--------] "
        Self.logBuffer += text
        Self.logBuffer += "\n"
        Self.upCount()
    }
    
    static func trace(funcName: String, argsText: String, retval: Int32) {
        var text: String = ""
        text += "\(funcName)(\(argsText)) = \(retval)"
        if retval < 0 {
            text += "  Err#\(errno) \(ERRNO_NAMES[Int(errno)])"
        }
#if DEBUG
        print(text)
#endif
        if Self.isStopLog {
            return
        }
        Self.logBuffer += Self.timeFormatter.string(from: Date())
        Self.logBuffer += String(format: " [%.6f] ", Self.response)
        Self.logBuffer += text
        Self.logBuffer += "\n"
        Self.upCount()
    }
    
    // Not output into console
    static func dataDump(data: Data, length: Int, label: String = "") {
        if length == 0 || Self.isStopLog || Self.traceLevel < Self.traceLevelHexDump {
            return
        }
        if !label.isEmpty {
            Self.logBuffer += label
            Self.logBuffer += "\n"
            Self.upCount()
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
                Self.logBuffer += dumpString
                Self.upCount()
                return
            }
            detailString = "    "
            while index < bytes.count && index < length {
                dumpString += String(format: "%02x", bytes[index])
                detailString += Self.printableLetters.contains(bytes[index].char) ? String(format: "%c", bytes[index]) : "."
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
            Self.logBuffer += dumpString
            Self.upCount()
        }
    }
}
