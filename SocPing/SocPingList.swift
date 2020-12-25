//
//  SocPingList.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import SwiftUI

struct SocPingList: View {
    @EnvironmentObject var object: SocPingSharedObject
    var actionType: Int
    @State var limitedBroadcast = SocAddress(family: AF_INET, addr: "255.255.255.255", port: 0, hostName: "broadcasthost", isBroadcast: true)
    
    static let actionTypeOnePing: Int = 0
    static let actionTypePing: Int = 1
    static let actionTypeTraceroute: Int = 2
    static let actionNames = ["One Ping", "Ping", "Traceroute"]
    
    var body: some View {
        List {
            if actionType == SocPingList.actionTypeOnePing {
                Section(header: Text("Header_LOCAL_ADDRESS")) {
                    ForEach(0 ..< object.interfaces.count, id: \.self) { i in
                        if self.object.interfaces[i].isActive {
                            NavigationLink(destination: SocPingOnePinger(address: self.object.interfaces[i].inet)) {
                                AddressRaw(address: self.$object.interfaces[i].inet,
                                           deviceType: self.object.interfaces[i].deviceType)
                            }
                        }
                    }
                }
                Section(header: Text("Header_BROADCAST_ADDRESS")) {
                    ForEach(0 ..< object.interfaces.count, id: \.self) { i in
                        if self.object.interfaces[i].hasBroadcast {
                            NavigationLink(destination: SocPingOnePinger(address: self.object.interfaces[i].broadcast)) {
                                AddressRaw(address: self.$object.interfaces[i].broadcast,
                                           deviceType: self.object.interfaces[i].deviceType)
                            }
                        }
                    }
                    NavigationLink(destination: SocPingOnePinger(address: self.limitedBroadcast)) {
                        AddressRaw(address: self.$limitedBroadcast)
                    }
                }
                Section(header: Text("Header_MULTICAST_ADDRESS")) {
                    ForEach(0 ..< self.object.addresses.count, id: \.self) { i in
                        if self.object.addresses[i].isMulticast {
                            NavigationLink(destination: SocPingOnePinger(address: self.object.addresses[i])) {
                                AddressRaw(address: self.$object.addresses[i])
                            }
                        }
                    }
                }
            }
            if actionType == SocPingList.actionTypePing {
                Section(header: Text("Header_MULTICAST_ADDRESS")) {
                    ForEach(0 ..< self.object.addresses.count, id: \.self) { i in
                        if self.object.addresses[i].isMulticast {
                            NavigationLink(destination: SocPingPinger(address: self.object.addresses[i])) {
                                AddressRaw(address: self.$object.addresses[i])
                            }
                        }
                    }
                }
            }
            Section(header: Text("Header_UNICAST_ADDRESS")) {
                ForEach(0 ..< self.object.addresses.count, id: \.self) { i in
                    if !self.object.addresses[i].isMulticast && !self.object.addresses[i].isAny {
                        if actionType == SocPingList.actionTypeOnePing {
                            NavigationLink(destination: SocPingOnePinger(address: self.object.addresses[i])) {
                                AddressRaw(address: self.$object.addresses[i])
                            }
                        }
                        else if actionType == SocPingList.actionTypePing {
                            NavigationLink(destination: SocPingPinger(address: self.object.addresses[i])) {
                                AddressRaw(address: self.$object.addresses[i])
                            }
                        }
                        else {
                            NavigationLink(destination: SocPingTracer(address: self.object.addresses[i])) {
                                AddressRaw(address: self.$object.addresses[i])
                            }
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle(SocPingList.actionNames[actionType], displayMode: .inline)
    }
}

fileprivate struct AddressRaw: View {
    @EnvironmentObject var object: SocPingSharedObject
    @Binding var address: SocAddress
    var deviceType: Int = -1  // default is remote address (not SocPingInterface's address)
    
    var body: some View {
        HStack {
            self.image
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(self.address.addr)
                        .font(.system(size: 19))
                    Spacer()
                    Text(self.address.classLabel)
                        .font(.system(size: 12))
                        .foregroundColor(Color.init(UIColor.systemGray))
                }
                if let detailText = self.detail {
                    HStack {
                        detailText
                            .font(.system(size: 12))
                            .foregroundColor(Color.init(UIColor.systemGray))
                        Spacer()
                    }
                }
            }
            .padding(.leading)
        }
    }
    
    var image: Image {
        switch self.deviceType {
        case SocPingInterface.deviceTypeWifi:
            return Image(systemName: "wifi")
        case SocPingInterface.deviceTypeCellurar:
            return Image(systemName: "antenna.radiowaves.left.and.right")
        case SocPingInterface.deviceTypeHotspot:
            return Image(systemName: "personalhotspot")
        case SocPingInterface.deviceTypeLoopback:
            return Image(systemName: "arrow.triangle.2.circlepath")
        default:  // default is remote address
            return Image(systemName: "globe")
        }
    }
    
    var detail: Text? {
        if object.appSettingDescription {
            if self.address.family != AF_INET {
                return Text("Description_Unexpected_address")
            }
            if self.address.hasHostName {
                return Text(self.address.hostName)
            }
            if self.address.isAny {
                return Text("Description_ANY_address")
            }
            if self.address.isPrivate {
                return Text("Description_Private_address")
            }
            return Text("Description_Unknown_host")
        }
        else {
            if self.address.family == AF_INET && self.address.hasHostName {
                return Text(self.address.hostName)
            }
            else {
                return nil
            }
        }
    }
}
