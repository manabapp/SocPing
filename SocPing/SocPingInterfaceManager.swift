//
//  SocPingInterfaceManager.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import SwiftUI

struct SocPingInterfaceManager: View {
    @EnvironmentObject var object: SocPingSharedObject
    
    static let ifFlags: [UInt32] = [0x1, 0x2, 0x4, 0x8, 0x10, 0x20, 0x40, 0x80, 0x100, 0x200, 0x400, 0x800, 0x1000, 0x2000, 0x4000, 0x8000]
    static let ifFlagNames = ["UP", "BROADCAST", "DEBUG", "LOOPBACK", "POINTOPOINT", "SMART", "RUNNING", "NOARP", "PROMISC", "ALLMULTI", "OACTIVE", "SIMPLEX", "LINK0", "LINK1", "LINK2", "MULTICAST"]
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Header_INTERFACE_LIST").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_INTERFACE_LIST").font(.system(size: 12)) : nil) {
                    ForEach(0 ..< object.interfaces.count, id: \.self) { i in
                        LocalDeviceRow(device: self.$object.interfaces[i])
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            Form {
                Button(action: {
                    SocLogger.debug("SocPingInterfaceManager: Button: Renew")
                    for i in 0 ..< object.interfaces.count {
                        object.interfaces[i].ifconfig()
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 19, height: 19, alignment: .center)
                        Text("Button_Reload")
                            .padding(.leading, 10)
                            .padding(.trailing, 20)
                        Spacer()
                    }
                }
            }
            .frame(height: 110)
        }
        .navigationBarTitle("Interface Address", displayMode: .inline)
    }
}


fileprivate struct LocalDeviceRow: View {
    @EnvironmentObject var object: SocPingSharedObject
    @Binding var device: SocPingInterface
    
    var body: some View {
        HStack {
            self.image
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                if object.appSettingDescription {
                    self.deviceLabel
                        .font(.system(size: 14))
                        .foregroundColor(Color.init(UIColor.systemGray))
                }
                if self.device.index > 0 {
                    Text("index \(self.device.index)")
                        .font(.system(size: 12))
                }
                HStack {
                    self.name
                        .font(.system(size: 19, weight: .bold))
                        .padding(.trailing, -5)
                    Spacer()
                    Text(self.device.name)
                        .font(.system(size: 14))
                        .foregroundColor(Color.init(UIColor.systemGray))
                }
                if self.device.hasNetmask {
                    Text("netmask \(self.device.netmask.addr)")
                        .font(.system(size: 14))
                }
                if self.device.hasBroadcast {
                    Text("broadcast \(self.device.broadcast.addr)")
                        .font(.system(size: 14))
                }
                if self.device.hasEther {
                    Text("ether \(self.device.ether)")
                        .font(.system(size: 14))
                }
                if let status = self.getStatus(flags: self.device.flags) {
                    Text(status)
                        .font(.system(size: 14))
                }
                if object.appSettingDescription {
                    self.detail
                        .font(.system(size: 12))
                        .foregroundColor(Color.init(UIColor.systemGray))
                }
            }
            .padding(.leading)
        }
        .foregroundColor(self.device.isExist && self.device.isActive ? Color.init(UIColor.label) : Color.init(UIColor.systemGray))
    }
    
    var image: Image {
        switch self.device.deviceType {
        case SocPingInterface.deviceTypeWifi:
            return Image(systemName: "wifi")
        case SocPingInterface.deviceTypeCellurar:
            return Image(systemName: "antenna.radiowaves.left.and.right")
        case SocPingInterface.deviceTypeHotspot:
            return Image(systemName: "personalhotspot")
        default: // SocPingInterface.deviceTypeLoopback:
            return Image(systemName: "arrow.triangle.2.circlepath")
        }
    }
    
    var name: Text {
        if self.device.isExist {
            if self.device.isActive {
                return Text(self.device.inet.addr)
            }
            return Text("Down")
        }
        return Text("Not found")
    }
    
    var deviceLabel: Text {
        switch self.device.deviceType {
        case SocPingInterface.deviceTypeWifi:
            return Text("Description_Wi-Fi")
        case SocPingInterface.deviceTypeCellurar:
            return Text("Description_Cellurar")
        case SocPingInterface.deviceTypeHotspot:
            return Text("Description_Personal_Hotspot")
        default: // SocPingInterface.deviceTypeLoopback:
            return Text("Description_Loopback")
        }
    }
    
    func getStatus(flags: UInt32) -> String? {
        var status = ""
        for i in 0 ..< SocPingInterfaceManager.ifFlags.count {
            if (flags & SocPingInterfaceManager.ifFlags[i]) == SocPingInterfaceManager.ifFlags[i] {
                if !status.isEmpty {
                    status += ","
                }
                status += SocPingInterfaceManager.ifFlagNames[i]
            }
        }
        if status.isEmpty {
            return nil
        }
        return status
    }
    
    var detail: Text {
        if self.device.isExist {
            if self.device.isActive {
                if self.device.inet.hasHostName {
                    return Text(self.device.inet.hostName)
                }
                if self.device.inet.isAny {
                    return Text("Description_ANY_address")
                }
                if self.device.inet.isPrivate {
                    return Text("Description_Private_address")
                }
                return Text("Description_Unknown_host")
            }
            return Text("Description_IP_address_not_assigned")
        }
        return Text("Description_No_such_interface_found")
    }
}
