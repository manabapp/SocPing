//
//  SocCmsg.swift
//  LibSoc - Swifty POSIX Socket Library
//
//  Created by Hirose Manabu on 2021/01/01.
//

import Darwin
import Foundation

struct SocCmsg {
    let hdr: cmsghdr
    var tv: timeval = timeval()
    var integer: Int = 0
    var name: String = ""
    var ether: String = ""
    var data: Data = Data()
    
    init(_ hdr: cmsghdr) {
        self.hdr = hdr
    }
    
    static let typeData: Int = 0  // Default
    static let typeTv: Int = 1
    static let typeDl: Int = 2

    static let cmsgLevels = [SOL_SOCKET, IPPROTO_IP]
    static let cmsgLevelNames = ["SOL_SOCKET", "IPPROTO_IP"]
    static let solCmsgTypes = [
        (SCM_RIGHTS,              SocCmsg.typeData, "SCM_RIGHTS"),
        (SCM_TIMESTAMP,           SocCmsg.typeTv,   "SCM_TIMESTAMP"),
        (SCM_CREDS,               SocCmsg.typeData, "SCM_CREDS"),
        (SCM_TIMESTAMP_MONOTONIC, SocCmsg.typeData, "SCM_TIMESTAMP_MONOTONIC")
    ]
    static let ipCmsgTypes = [
        (IP_RECVIF, SocCmsg.typeDl, "IP_RECVIF")
    ]

    static func createCmsgs(control: Data, length: Int) -> [SocCmsg] {
        var cmsgs: [SocCmsg] = []
        var offset: Int = 0
        
        while length >= offset + 12 {
            let cmsgHdr = Data(control[offset ..< offset + 12]).withUnsafeBytes { $0.load(as: cmsghdr.self) }
            var cmsg = SocCmsg(cmsgHdr)
            var valType = SocCmsg.typeData
            if cmsg.hdr.cmsg_level == SOL_SOCKET {
                for i in 0 ..< SocCmsg.solCmsgTypes.count {
                    if SocCmsg.solCmsgTypes[i].0 == cmsg.hdr.cmsg_type {
                        valType = SocCmsg.solCmsgTypes[i].1
                        break
                    }
                }
            }
            if cmsg.hdr.cmsg_level == IPPROTO_IP {
                for i in 0 ..< SocCmsg.ipCmsgTypes.count {
                    if SocCmsg.ipCmsgTypes[i].0 == cmsg.hdr.cmsg_type {
                        valType = SocCmsg.ipCmsgTypes[i].1
                        break
                    }
                }
            }
            switch valType {
            case SocCmsg.typeTv:
                cmsg.tv = Data(control[offset + 12 ..< offset + Int(cmsg.hdr.cmsg_len)]).withUnsafeBytes { $0.load(as: timeval.self) }
            
            case SocCmsg.typeDl:
                let sdl = Data(control[offset + 12 ..< offset + Int(cmsg.hdr.cmsg_len)]).withUnsafeBytes { $0.load(as: sockaddr_dl.self) }
                cmsg.integer = Int(sdl.sdl_index)
                
                var sdlData = sdl.sdl_data
                withUnsafeMutablePointer(to: &sdlData) { sdlPtr in
                    sdlPtr.withMemoryRebound(to: UInt8.self, capacity: Int(sdl.sdl_nlen + sdl.sdl_alen)) {
                        let sdlNamePtr = UnsafeBufferPointer(start: $0, count: Int(sdl.sdl_nlen))
                        let uint8array = [UInt8](UnsafeBufferPointer(start: sdlNamePtr.baseAddress!, count: Int(sdl.sdl_nlen)))
                        cmsg.name = String(bytes: uint8array, encoding: .utf8)!

                        let sdlAddrPtr = UnsafeBufferPointer(start: $0 + Int(sdl.sdl_nlen), count: Int(sdl.sdl_alen))
                        if sdlAddrPtr.count == 6 {
                            cmsg.ether = sdlAddrPtr.map { String(format:"%02hhx", $0)}.joined(separator: ":")
                        }
                    }
                }
                
            default:  // SocCmsg.typeData
                cmsg.data = Data(control[offset + 12 ..< offset + Int(cmsg.hdr.cmsg_len)])
            }
            cmsgs.append(cmsg)
            offset += Int((cmsg.hdr.cmsg_len + 3) & ~3)
        }
        return cmsgs
    }
    
    static func createData(cmsgs: [SocCmsg]) -> Data {
        return Data()
    }
}
