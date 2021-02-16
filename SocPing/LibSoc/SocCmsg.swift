//
//  SocCmsg.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//  Changed by Hirose Manabu on 2021/02/12. (version 1.1)
//

import Darwin
import Foundation

struct SocCmsg {
    let hdr: cmsghdr
    var data: Data
    
    var levelName: String {
        var levelName = String(hdr.cmsg_level)
        for i in 0 ..< Self.cmsgLevels.count {
            if Self.cmsgLevels[i] == hdr.cmsg_level {
                levelName = Self.cmsgLevelNames[i]
                break
            }
        }
        return levelName
    }
    
    var typeName: String {
        var typeName = String(hdr.cmsg_type)
        switch hdr.cmsg_level {
        case SOL_SOCKET:
            for i in 0 ..< Self.solCmsgTypes.count {
                if Self.solCmsgTypes[i] == hdr.cmsg_type {
                    typeName = Self.solCmsgTypeNames[i]
                    break
                }
            }
        case IPPROTO_IP:
            for i in 0 ..< Self.ipCmsgTypes.count {
                if Self.ipCmsgTypes[i] == hdr.cmsg_type {
                    typeName = Self.ipCmsgTypeNames[i]
                    break
                }
            }
        default:
            break
        }
        return typeName
    }
    
    var uint8array: [UInt8] {
        var bytes: [UInt8] = []
        var cmsgHdr = self.hdr
        bytes += Data(bytes: &cmsgHdr, count: MemoryLayout<cmsghdr>.size).uint8array!
        bytes += self.data.uint8array!
        let cmsgLen = MemoryLayout<cmsghdr>.size + self.data.count
        let cmsgSpace = ((cmsgLen + 3) / 4) * 4  //CMSG_SPACE
        bytes += [UInt8](repeating: 0, count: cmsgSpace - cmsgLen)
        return bytes
    }
    
    static let cmsgLevels = [SOL_SOCKET, IPPROTO_IP]
    static let cmsgLevelNames = ["SOL_SOCKET", "IPPROTO_IP"]
    static let solCmsgTypes = [SCM_RIGHTS, SCM_TIMESTAMP, SCM_CREDS, SCM_TIMESTAMP_MONOTONIC]
    static let solCmsgTypeNames = ["SCM_RIGHTS", "SCM_TIMESTAMP", "SCM_CREDS", "SCM_TIMESTAMP_MONOTONIC"]
    static let ipCmsgTypes = [IP_RECVOPTS, IP_RECVRETOPTS, IP_RECVDSTADDR, IP_RETOPTS, IP_RECVIF, IP_RECVTTL, IP_PKTINFO, IP_RECVTOS]
    static let ipCmsgTypeNames = ["IP_RECVOPTS", "IP_RECVRETOPTS", "IP_RECVDSTADDR", "IP_RETOPTS", "IP_RECVIF", "IP_RECVTTL", "IP_PKTINFO", "IP_RECVTOS"]
    
    static func loadCmsgs(control: Data, length: Int) -> [SocCmsg] {
        var cmsgs: [SocCmsg] = []
        var offset: Int = 0
        
        while length >= offset + 12 {
            let cmsgHdr = Data(control[offset ..< offset + MemoryLayout<cmsghdr>.size]).withUnsafeBytes { $0.load(as: cmsghdr.self) }
            let dataBase = offset + MemoryLayout<cmsghdr>.size
            let dataLen = Int(cmsgHdr.cmsg_len) - MemoryLayout<cmsghdr>.size
            if dataLen > 0 {
                let data = Data(control[dataBase ..< dataBase + dataLen])
                let cmsg = SocCmsg(hdr: cmsgHdr, data: data)
                cmsgs.append(cmsg)
            }
            offset += Int((cmsgHdr.cmsg_len + 3) & ~3)
        }
        return cmsgs
    }
    
    static func createRightsCmsg(fds: [Int32]) throws -> SocCmsg {
        var val = fds
        guard fds.count > 0 else {
            throw SocError.InvalidParameter
        }
        let cmsgLen = socklen_t(MemoryLayout<cmsghdr>.size + MemoryLayout<Int32>.size * fds.count)  //CMSG_LEN(sizeof(int) * len(fds))
        let cmsgHdr = cmsghdr(cmsg_len: cmsgLen, cmsg_level: SOL_SOCKET, cmsg_type: SCM_RIGHTS)
        let data = Data(bytes: &val, count: MemoryLayout<Int32>.size * fds.count)
        let cmsg = SocCmsg(hdr: cmsgHdr, data: data)
        return cmsg
    }
    
    static func createCredsCmsg() -> SocCmsg {
        let cmsgLen = socklen_t(MemoryLayout<cmsghdr>.size + 82)  //CMSG_LEN(sizeof(struct cmsgcred))
        let cmsgHdr = cmsghdr(cmsg_len: cmsgLen, cmsg_level: SOL_SOCKET, cmsg_type: SCM_CREDS)
        let data = Data([UInt8](repeating: 0, count: 82))
        let cmsg = SocCmsg(hdr: cmsgHdr, data: data)
        return cmsg
    }
    
    static func createRetoptsCmsg(opts: ip_opts) -> SocCmsg {
        let cmsgLen = socklen_t(MemoryLayout<cmsghdr>.size + MemoryLayout<ip_opts>.size)  //CMSG_LEN(sizeof(struct ip_opts))
        let cmsgHdr = cmsghdr(cmsg_len: cmsgLen, cmsg_level: IPPROTO_IP, cmsg_type: IP_RETOPTS)
        var val = opts
        let data = Data(bytes: &val, count: MemoryLayout<ip_opts>.size)
        let cmsg = SocCmsg(hdr: cmsgHdr, data: data)
        return cmsg
    }
    
    static func createPktinfoCmsg(pktinfo: in_pktinfo) -> SocCmsg {
        let cmsgLen = socklen_t(MemoryLayout<cmsghdr>.size + MemoryLayout<in_pktinfo>.size)  //CMSG_LEN(sizeof(struct pktinfo))
        let cmsgHdr = cmsghdr(cmsg_len: cmsgLen, cmsg_level: IPPROTO_IP, cmsg_type: IP_PKTINFO)
        var val = pktinfo
        let data = Data(bytes: &val, count: MemoryLayout<in_pktinfo>.size)
        let cmsg = SocCmsg(hdr: cmsgHdr, data: data)
        return cmsg
    }
}
