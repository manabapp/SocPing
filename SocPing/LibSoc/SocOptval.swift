//
//  SocOptval.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//

import Darwin
import Foundation

struct SocOptval {
    let boolValue: Bool
    let intValue: Int
    let addrValue: String
    let dataValue: Data?
    
    static let typeBool: Int = 0
    static let typeBool8: Int = 1
    static let typeInt: Int = 2
    static let typeInt8: Int = 3
    static let typeInAddr: Int = 4
    static let typeIpOption: Int = 5
    
    static let levels = [SOL_SOCKET, IPPROTO_IP]
    static let levelNames = ["SOL_SOCKET", "IPPROTO_IP"]
    static let solOptions = [
        (SO_DONTROUTE,      SocOptval.typeBool,     "SO_DONTROUTE"),
        (SO_BROADCAST,      SocOptval.typeBool,     "SO_BROADCAST"),
        (SO_TIMESTAMP,      SocOptval.typeBool,     "SO_TIMESTAMP"),
        (SO_SNDBUF,         SocOptval.typeInt,      "SO_SNDBUF"),
        (SO_RCVBUF,         SocOptval.typeInt,      "SO_RCVBUF")
    ]
    static let ipOptions = [
        (IP_OPTIONS,        SocOptval.typeIpOption, "IP_OPTIONS"),
        (IP_TOS,            SocOptval.typeInt,      "IP_TOS"),
        (IP_TTL,            SocOptval.typeInt,      "IP_TTL"),
        (IP_MULTICAST_IF,   SocOptval.typeInAddr,   "IP_MULTICAST_IF"),
        (IP_MULTICAST_TTL,  SocOptval.typeInt8,     "IP_MULTICAST_TTL"),
        (IP_MULTICAST_LOOP, SocOptval.typeBool8,    "IP_MULTICAST_LOOP"),
        (IP_RECVIF,         SocOptval.typeBool,     "IP_RECVIF"),
        (IP_BOUND_IF,       SocOptval.typeInt,      "IP_BOUND_IF")
    ]
    
    init(bool: Bool = false, int: Int = 0, addr: String = "", data: Data? = nil) {
        self.boolValue = bool
        self.intValue = int
        self.addrValue = addr
        self.dataValue = data
    }
}
