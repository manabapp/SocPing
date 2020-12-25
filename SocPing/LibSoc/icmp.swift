//
//  icmp.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//

import Darwin

struct icmp {
    let icmp_type: UInt8
    let icmp_code: UInt8
    var icmp_cksum: UInt16 = 0
    var icmp_id: UInt16 = 0
    var icmp_seq: UInt16 = 0
    
    var icmp_pptr: UInt8 { return UInt8(self.icmp_id >> 8) }
    var icmp_gwaddr: in_addr { return in_addr(s_addr: UInt32(self.icmp_id) << 16 + UInt32(self.icmp_seq)) }
    var icmp_void: Int32 { return Int32(UInt32(self.icmp_id) << 16 + UInt32(self.icmp_seq)) }
    var icmp_pmvoid: UInt16 { return self.icmp_id }
    var icmp_nextmtu: UInt16 { return self.icmp_seq }
    var icmp_num_addrs: UInt8 { return UInt8(self.icmp_id >> 8) }
    var icmp_wpa: UInt8 { return UInt8(self.icmp_id & 0x00ff) }
    var icmp_lifetime: UInt16 { return self.icmp_seq }
    var icmp_len: UInt8 { return UInt8(self.icmp_id & 0x00ff) }
    
    init(type: UInt8, code: UInt8) {
        self.icmp_type = type
        self.icmp_code = code
    }
    
    var hasIpHdr: Bool {
        switch Int32(self.icmp_type) {
        case ICMP_UNREACH:
            return true
        case ICMP_SOURCEQUENCH:
            return true
        case ICMP_REDIRECT:
            return true
        case ICMP_TIMXCEED:
            return true
        case ICMP_PARAMPROB:
            return true
        default:
            return false
        }
    }
    
    var message: String {
        switch Int32(self.icmp_type) {
        case ICMP_UNREACH:
            return self.codeMessage
        case ICMP_TIMXCEED:
            return self.codeMessage
        case ICMP_REDIRECT:
            return self.codeMessage + "\nNew addr: " + String.init(cString: inet_ntoa(self.icmp_gwaddr))
        case ICMP_PARAMPROB:
            return self.typeMessage + "\npointer = " + String(format: "0x%02x", self.icmp_pptr)
        default:
            return self.typeMessage
        }
    }
    
    var typeMessage: String {
        switch Int32(self.icmp_type) {
        case ICMP_ECHOREPLY:
            return "Echo Reply"
        case ICMP_UNREACH:
            return "Dest Unreachable"
        case ICMP_SOURCEQUENCH:
            return "Source Quench"
        case ICMP_REDIRECT:
            return "Redirect"
        case ICMP_ALTHOSTADDR:
            return "ICMP_ALTHOSTADDR"
        case ICMP_ECHO:
            return "Echo Request"
        case ICMP_ROUTERADVERT:
            return "Router Advertisement"
        case ICMP_ROUTERSOLICIT:
            return "Router Solicitation"
        case ICMP_TIMXCEED:
            return "Time exceeded"
        case ICMP_PARAMPROB:
            return "Parameter problem"
        case ICMP_TSTAMP:
            return "Timestamp"
        case ICMP_TSTAMPREPLY:
            return "Timestamp Reply"
        case ICMP_IREQ:
            return "Information Request"
        case ICMP_IREQREPLY:
            return "Information Reply"
        case ICMP_MASKREQ:
            return "Address Mask Request"
        case ICMP_MASKREPLY:
            return "Address Mask Reply"
        case ICMP_TRACEROUTE:
            return "ICMP_TRACEROUTE"
        case ICMP_DATACONVERR:
            return "ICMP_DATACONVERR"
        case ICMP_MOBILE_REDIRECT:
            return "ICMP_MOBILE_REDIRECT"
        case ICMP_IPV6_WHEREAREYOU:
            return "ICMP_IPV6_WHEREAREYOU"
        case ICMP_IPV6_IAMHERE:
            return "ICMP_IPV6_IAMHERE"
        case ICMP_MOBILE_REGREQUEST:
            return "ICMP_MOBILE_REGREQUEST"
        case ICMP_MOBILE_REGREPLY:
            return "ICMP_MOBILE_REGREPLY"
        case ICMP_SKIP:
            return "ICMP_SKIP"
        case ICMP_PHOTURIS:
            return "ICMP_PHOTURIS"
        default:
            return "Bad ICMP type"
        }
    }
    
    var codeMessage: String {
        switch Int32(self.icmp_type) {
        case ICMP_UNREACH:
            switch Int32(self.icmp_code) {
            case ICMP_UNREACH_NET:
                return "Destination Net Unreachable"
            case ICMP_UNREACH_HOST:
                return "Destination Host Unreachable"
            case ICMP_UNREACH_PROTOCOL:
                return "Destination Protocol Unreachable"
            case ICMP_UNREACH_PORT:
                return "Destination Port Unreachable"
            case ICMP_UNREACH_NEEDFRAG:
                return "frag needed and DF set (MTU \(self.icmp_nextmtu))"
            case ICMP_UNREACH_SRCFAIL:
                return "Source Route Failed"
            case ICMP_UNREACH_FILTER_PROHIB:
                return "Communication prohibited by filter"
            default:
                return "Bad Code"
            }
            
        case ICMP_REDIRECT:
            switch Int32(self.icmp_code) {
            case ICMP_REDIRECT_NET:
                return "Redirect Network"
            case ICMP_REDIRECT_HOST:
                return "Redirect Host"
            case ICMP_REDIRECT_TOSNET:
                return "Redirect Type of Service and Network"
            case ICMP_REDIRECT_TOSHOST:
                return "Redirect Type of Service and Host"
            default:
                return "Bad Code"
            }
            
        case ICMP_TIMXCEED:
            switch Int32(self.icmp_code) {
            case ICMP_TIMXCEED_INTRANS:
                return "Time to live exceeded"
            case ICMP_TIMXCEED_REASS:
                return "Frag reassembly time exceeded"
            default:
                return "Bad Code"
            }
        
        default:
            return ""
        }
    }
}
