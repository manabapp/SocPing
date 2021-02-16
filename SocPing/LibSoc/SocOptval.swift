//
//  SocOptval.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//  Changed by Hirose Manabu on 2021/02/12. (version 1.1)
//

import Darwin
import Foundation

struct SocOptval {
    var bool: Bool
    var int: Int
    var double: Double
    var addr: String
    var addr2: String
    var connInfo: tcp_connection_info
    var data: Data?
    var text: String
    
    static let typeBool: Int = 0         // bool:        SOL_SOCKET, TCP, IP
    static let typeBool8: Int = 1        // bool:        IP
    static let typeInt: Int = 2          // int:         SOL_SOCKET, TCP, IP
    static let typeInt8: Int = 3         // int:         IP
    static let typeUsec: Int = 4         // double:      SOL_SOCKET, TCP
    static let typeLinger: Int = 5       // bool, int:   SOL_SOCKET
    static let typeNWService: Int = 6    // int:         SOL_SOCKET
    static let typePortRange: Int = 7    // int:         IP
    static let typeInAddr: Int = 8       // addr:        IP
    static let typeIpMreq: Int = 9       // addr, addr2: IP (set only)
    static let typeTcpConnInfo: Int = 10  // connInfo:    TCP (get only)
    static let typeIpOptions: Int = 11   // data:        IP

    static let levels = [SOL_SOCKET, IPPROTO_TCP, IPPROTO_UDP, IPPROTO_IP]
    static let levelNames = ["SOL_SOCKET", "IPPROTO_TCP", "IPPROTO_UDP", "IPPROTO_IP"]
    static let solOptions = [
        (SO_DEBUG,                SocOptval.typeBool,        "SO_DEBUG"),
        (SO_ACCEPTCONN,           SocOptval.typeBool,        "SO_ACCEPTCONN"),
        (SO_REUSEADDR,            SocOptval.typeBool,        "SO_REUSEADDR"),
        (SO_KEEPALIVE,            SocOptval.typeBool,        "SO_KEEPALIVE"),
        (SO_DONTROUTE,            SocOptval.typeBool,        "SO_DONTROUTE"),
        (SO_BROADCAST,            SocOptval.typeBool,        "SO_BROADCAST"),
        (SO_USELOOPBACK,          SocOptval.typeBool,        "SO_USELOOPBACK"),
        (SO_LINGER,               SocOptval.typeLinger,      "SO_LINGER"),
        (SO_OOBINLINE,            SocOptval.typeBool,        "SO_OOBINLINE"),
        (SO_REUSEPORT,            SocOptval.typeBool,        "SO_REUSEPORT"),
        (SO_TIMESTAMP,            SocOptval.typeBool,        "SO_TIMESTAMP"),
        (SO_TIMESTAMP_MONOTONIC,  SocOptval.typeBool,        "SO_TIMESTAMP_MONOTONIC"),
        (SO_SNDBUF,               SocOptval.typeInt,         "SO_SNDBUF"),
        (SO_RCVBUF,               SocOptval.typeInt,         "SO_RCVBUF"),
        (SO_SNDLOWAT,             SocOptval.typeInt,         "SO_SNDLOWAT"),
        (SO_RCVLOWAT,             SocOptval.typeInt,         "SO_RCVLOWAT"),
        (SO_SNDTIMEO,             SocOptval.typeUsec,        "SO_SNDTIMEO"),
        (SO_RCVTIMEO,             SocOptval.typeUsec,        "SO_RCVTIMEO"),
        (SO_ERROR,                SocOptval.typeInt,         "SO_ERROR"),
        (SO_TYPE,                 SocOptval.typeInt,         "SO_TYPE"),
        (SO_NUMRCVPKT,            SocOptval.typeInt,         "SO_NUMRCVPKT"),
        (SO_NET_SERVICE_TYPE,     SocOptval.typeNWService,   "SO_NET_SERVICE_TYPE"),
        (SO_NETSVC_MARKING_LEVEL, SocOptval.typeInt,         "SO_NETSVC_MARKING_LEVEL")
    ]
    
    static let tcpOptions = [
        //refer:/System/Volumes/Data/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/usr/include/netinet/tcp.h
        (TCP_NODELAY,             SocOptval.typeBool,        "TCP_NODELAY"),
        (TCP_MAXSEG,              SocOptval.typeInt,         "TCP_MAXSEG"),
        (TCP_NOPUSH,              SocOptval.typeBool,        "TCP_NOPUSH"),
        (TCP_NOOPT,               SocOptval.typeBool,        "TCP_NOOPT"),
        (TCP_KEEPALIVE,           SocOptval.typeInt,         "TCP_KEEPALIVE"),
        (TCP_CONNECTIONTIMEOUT,   SocOptval.typeUsec,        "TCP_CONNECTIONTIMEOUT"),
        (TCP_RXT_CONNDROPTIME,    SocOptval.typeInt,         "TCP_RXT_CONNDROPTIME"),
        (TCP_RXT_FINDROP,         SocOptval.typeBool,        "TCP_RXT_FINDROP"),
        (TCP_KEEPINTVL,           SocOptval.typeInt,         "TCP_KEEPINTVL"),
        (TCP_KEEPCNT,             SocOptval.typeInt,         "TCP_KEEPCNT"),
        (TCP_SENDMOREACKS,        SocOptval.typeBool,        "TCP_SENDMOREACKS"),
        (TCP_ENABLE_ECN,          SocOptval.typeBool,        "TCP_ENABLE_ECN"),
        (TCP_FASTOPEN,            SocOptval.typeBool,        "TCP_FASTOPEN"),
        (TCP_CONNECTION_INFO,     SocOptval.typeTcpConnInfo, "TCP_CONNECTION_INFO"),
        (TCP_NOTSENT_LOWAT,       SocOptval.typeInt,         "TCP_NOTSENT_LOWAT")
    ]
    static let udpOptions = [
        (UDP_NOCKSUM,             SocOptval.typeBool,        "UDP_NOCKSUM")
    ]
    static let ipOptions = [
        (IP_OPTIONS,              SocOptval.typeIpOptions,   "IP_OPTIONS"),
        (IP_HDRINCL,              SocOptval.typeBool,        "IP_HDRINCL"),
        (IP_TOS,                  SocOptval.typeInt,         "IP_TOS"),
        (IP_TTL,                  SocOptval.typeInt,         "IP_TTL"),
        (IP_RECVOPTS,             SocOptval.typeBool,        "IP_RECVOPTS"),
        (IP_RECVRETOPTS,          SocOptval.typeBool,        "IP_RECVRETOPTS"),
        (IP_RECVDSTADDR,          SocOptval.typeBool,        "IP_RECVDSTADDR"),
        (IP_RETOPTS,              SocOptval.typeBool,        "IP_RETOPTS"),
        (IP_MULTICAST_IF,         SocOptval.typeInAddr,      "IP_MULTICAST_IF"),
        (IP_MULTICAST_TTL,        SocOptval.typeInt8,        "IP_MULTICAST_TTL"),
        (IP_MULTICAST_LOOP,       SocOptval.typeBool8,       "IP_MULTICAST_LOOP"),
        (IP_ADD_MEMBERSHIP,       SocOptval.typeIpMreq,      "IP_ADD_MEMBERSHIP"),
        (IP_DROP_MEMBERSHIP,      SocOptval.typeIpMreq,      "IP_DROP_MEMBERSHIP"),
        (IP_PORTRANGE,            SocOptval.typePortRange,   "IP_PORTRANGE"),
        (IP_RECVIF,               SocOptval.typeBool,        "IP_RECVIF"),
        (IP_STRIPHDR,             SocOptval.typeBool,        "IP_STRIPHDR"),
        (IP_RECVTTL,              SocOptval.typeBool,        "IP_RECVTTL"),
        (IP_BOUND_IF,             SocOptval.typeInt,         "IP_BOUND_IF"),
        (IP_PKTINFO,              SocOptval.typeBool,        "IP_PKTINFO"),
        (IP_RECVTOS,              SocOptval.typeBool,        "IP_RECVTOS"),
        (IP_DONTFRAG,             SocOptval.typeBool,        "IP_DONTFRAG")
    ]
    
    static func isGetOnly(level: Int32, option: Int32) -> Bool {
        switch level {
        case SOL_SOCKET:
            switch option {
            case SO_ACCEPTCONN:
                return true
            case SO_ERROR:
                return true
            case SO_TYPE:
                return true
            case SO_NUMRCVPKT:
                return true
            case SO_NETSVC_MARKING_LEVEL:
                return true
            default:
                return false
            }
        case IPPROTO_TCP:
            switch option {
            case TCP_CONNECTION_INFO:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    
    static func isSetOnly(level: Int32, option: Int32) -> Bool {
        switch level {
        case IPPROTO_IP:
            switch option {
            case IP_ADD_MEMBERSHIP:
                return true
            case IP_DROP_MEMBERSHIP:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    
    static func getOptionType(level: Int32, option: Int32) -> Int? {
        var optType: Int? = nil
        
        switch level {
        case SOL_SOCKET:
            for i in 0 ..< Self.solOptions.count {
                if Self.solOptions[i].0 == option {
                    optType = Self.solOptions[i].1
                    break
                }
            }
        case IPPROTO_TCP:
            for i in 0 ..< Self.tcpOptions.count {
                if Self.tcpOptions[i].0 == option {
                    optType = Self.tcpOptions[i].1
                    break
                }
            }
        case IPPROTO_UDP:
            for i in 0 ..< Self.udpOptions.count {
                if Self.udpOptions[i].0 == option {
                    optType = Self.udpOptions[i].1
                    break
                }
            }
        case IPPROTO_IP:
            for i in 0 ..< Self.ipOptions.count {
                if Self.ipOptions[i].0 == option {
                    optType = Self.ipOptions[i].1
                    break
                }
            }
        default:
            break
        }
        return optType
    }
    
    static func getLevelName(level: Int32) -> String {
        var levelName = String(level)
        
        for i in 0 ..< Self.levels.count {
            if Self.levels[i] == level {
                levelName = Self.levelNames[i]
                break
            }
        }
        return levelName
    }
    
    static func getOptionName(level: Int32, option: Int32) -> String {
        var optName = String(option)
        
        switch level {
        case SOL_SOCKET:
            for i in 0 ..< Self.solOptions.count {
                if Self.solOptions[i].0 == option {
                    optName = Self.solOptions[i].2
                    break
                }
            }
        case IPPROTO_TCP:
            for i in 0 ..< Self.tcpOptions.count {
                if Self.tcpOptions[i].0 == option {
                    optName = Self.tcpOptions[i].2
                    break
                }
            }
        case IPPROTO_UDP:
            for i in 0 ..< Self.udpOptions.count {
                if Self.udpOptions[i].0 == option {
                    optName = Self.udpOptions[i].2
                    break
                }
            }
        case IPPROTO_IP:
            for i in 0 ..< Self.ipOptions.count {
                if Self.ipOptions[i].0 == option {
                    optName = Self.ipOptions[i].2
                    break
                }
            }
        default:
            break
        }
        return optName
    }
    
    init(bool: Bool = false,
         int: Int = 0,
         double: Double = 0.0,
         addr: String = "",
         addr2: String = "",
         connInfo: tcp_connection_info = tcp_connection_info(),
         data: Data? = nil,
         text: String = "") {
        self.bool = bool
        self.int = int
        self.double = double
        self.addr = addr
        self.addr2 = addr2
        self.connInfo = connInfo
        self.data = data
        self.text = text
    }
}
