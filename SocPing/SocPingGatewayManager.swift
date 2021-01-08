//
//  SocPingGatewayManager.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import SwiftUI

struct SocPingGatewayManager: View {
    @EnvironmentObject var object: SocPingSharedObject
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Header_ORDER_OF_GATEWAYS").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_ORDER_OF_GATEWAYS").font(.system(size: 12)) : nil) {
                    ForEach(0 ..< self.object.addresses.count, id: \.self) { i in
                        GwAddressRaw(index: i, address: self.object.addresses[i])
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if self.object.addresses[i].isAny {
                                    SocLogger.debug("SocPingGatewayManager: onTapGesture: \(i) - Can't select ANY address")
                                    return
                                }
                                if self.object.addresses[i].isMulticast {
                                    SocLogger.debug("SocPingGatewayManager: onTapGesture: \(i) - Can't select multicast")
                                    return
                                }
                                SocLogger.debug("SocPingGatewayManager: onTapGesture: \(i) - \(self.object.addresses[i])")
                                self.selectGw(index: i, address: self.object.addresses[i])
                            }
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            if self.hasUnicast() {
                Form {
                    Button(action: {
                        SocLogger.debug("SocPingGatewayManager: Button: Register")
                        self.registerGw()
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 19, height: 19, alignment: .center)
                            Text("Button_Register")
                                .padding(.leading, 10)
                                .padding(.trailing, 20)
                            Spacer()
                        }
                    }
                }
                .frame(height: 110)
            }
        }
        .navigationBarTitle("Gateway Address", displayMode: .inline)
    }
    
    func hasUnicast() -> Bool {
        for i in 0 ..< self.object.addresses.count {
            if !self.object.addresses[i].isAny && !self.object.addresses[i].isMulticast {
                return true
            }
        }
        return false
    }
    
    func selectGw(index: Int, address: SocAddress) {
        let order = object.gwOrders[index]
        let last: Int = object.gwOrders.max()!
        if order == 0 {
            if last < MAX_IPOPTGWS {
                object.gwOrders[index] = last + 1
                SocLogger.debug("SocPingGatewayManager.selectGw: select")
            }
            else {
                SocLogger.debug("SocPingGatewayManager.selectGw: Can't select anymore")
            }
        }
        else {
            object.gwOrders[index] = 0
            SocLogger.debug("SocPingGatewayManager.selectGw: unselect")
            for i in 0 ..< object.gwOrders.count {
                if object.gwOrders[i] > order {
                    object.gwOrders[i] -= 1
                }
            }
        }
    }
    
    func registerGw() {
        object.gateways = []
        for i in 1 ... MAX_IPOPTGWS {
            if let index = object.gwOrders.firstIndex(of: i) {
                if index < object.addresses.count {
                    object.gateways.append(object.addresses[index])
                }
            }
            else {
                break
            }
        }
        SocPingSharedObject.saveGateways(gateways: self.object.gateways)
    }
}

fileprivate struct GwAddressRaw: View {
    @EnvironmentObject var object: SocPingSharedObject
    let index: Int
    let address: SocAddress
    
    var body: some View {
        HStack {
            self.image
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22, alignment: .center)
                .foregroundColor(Color.init(object.gwOrders[self.index] > 0 ? UIColor.systemBlue : UIColor.systemGray))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(self.address.addr)
                        .font(.system(size: 19))
                        .foregroundColor(Color.init(self.address.isMulticast || self.address.isAny ? UIColor.systemGray : UIColor.label))
                    Spacer()
                }
                if self.detail != nil {
                    HStack {
                        self.detail!
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
        if object.gwOrders[self.index] > 0 {
            return Image(systemName: "\(object.gwOrders[self.index]).circle.fill")
        }
        else if self.address.isMulticast || self.address.isAny {
            return Image(systemName: "multiply.circle.fill")
        }
        else {
            return Image(systemName: "circle")
        }
    }

    var detail: Text? {
        if self.address.hasHostName {
            return Text(self.address.hostName)
        }
        if !object.appSettingDescription {
            return nil
        }
        if self.address.isAny {
            return Text("Description_ANY_address")
        }
        if self.address.isPrivate {
            return Text("Description_Private_address")
        }
        return Text("Description_Unknown_host")
    }
}
