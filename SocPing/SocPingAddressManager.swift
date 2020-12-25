//
//  SocPingAddressManager.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import SwiftUI
import Foundation

struct SocPingAddressManager: View {
    @EnvironmentObject var object: SocPingSharedObject
    @State private var alertTitle: String = "Unexpected error."
    @State private var alertMessage: String = ""
    @State private var isPopAlert: Bool = false
    
    static let maxRegistNumber: Int = 32
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Header_ADDRESS_LIST").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_ADDRESS_LIST").font(.system(size: 12)) : nil) {
                    ForEach(0 ..< self.object.addresses.count, id: \.self) { i in
                        AddressRaw(address: self.object.addresses[i])
                    }
                    .onDelete { indexSet in
                        SocLogger.debug("SocPingAddressManager: onDelete: \(indexSet)")
                        indexSet.forEach { i in
                            do {
                                if object.addresses[i].isAny {
                                    throw SocPingError.DontDeleteAny
                                }
                                for j in 0 ..< object.gateways.count {
                                    if object.gateways[j].addr == object.addresses[i].addr {
                                        object.gateways.remove(at: j)
                                        break
                                    }
                                }
                                object.addresses.remove(at: i)
                            }
                            catch let error as SocPingError {
                                self.alertTitle = error.message
                                self.alertMessage = ""
                                self.isPopAlert = true
                            }
                            catch {
                                SocLogger.error("SocPingAddressManager: \(error)")
                                assertionFailure("SocPingAddressManager: \(error)")
                                self.isPopAlert = true
                            }
                        }
                        SocPingSharedObject.saveGateways(gateways: self.object.gateways)
                        SocPingSharedObject.saveAddresses(addresses: self.object.addresses)
                    }
                    .onMove(perform: { (fromIndex, toIndex) in
                        SocLogger.debug("SocPingAddressManager: onMove: \(fromIndex) <---> \(toIndex)")
                        object.addresses.move(fromOffsets: fromIndex, toOffset: toIndex)
                        SocPingSharedObject.saveAddresses(addresses: self.object.addresses)
                    })
                    .alert(isPresented: self.$isPopAlert) {
                        Alert(title: Text(self.alertTitle), message: Text(self.alertMessage))
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarItems(trailing: EditButton())
            
            Form {
                NavigationLink(destination: AddressRegister()) {
                    HStack {
                        Spacer()
                        Text("New Address")
                        Spacer()
                    }
                }
                NavigationLink(destination: SocPingInterfaceManager()) {
                    HStack {
                        Spacer()
                        Text("Interface Address")
                        Spacer()
                    }
                }
                NavigationLink(destination: SocPingGatewayManager()) {
                    HStack {
                        Spacer()
                        Text("Gateway Address")
                        Spacer()
                    }
                }
            }
            .listStyle(PlainListStyle())
            .frame(height: 200)
        }
        .navigationBarTitle("Address Manager", displayMode: .inline)
    }
}

fileprivate struct AddressRaw: View {
    @EnvironmentObject var object: SocPingSharedObject
    let address: SocAddress
        
    var body: some View {
        HStack {
            Image(systemName: address.isAny ? "multiply.circle.fill" : "globe")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22, alignment: .center)
                .foregroundColor(address.isAny ? Color.init(UIColor.systemGray) : Color.init(UIColor.label))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(self.address.addr)
                        .font(.system(size: 19))
                        .foregroundColor(address.isAny ? Color.init(UIColor.systemGray) : Color.init(UIColor.label))
                    Spacer()
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
            return nil
        }
    }
}

fileprivate struct AddressRegister: View {
    @EnvironmentObject var object: SocPingSharedObject
    @Environment(\.presentationMode) var presentationMode
    @State private var hostString: String = ""
    @State private var addressTypeIndex: Int = 0
    @State private var alertTitle: String = "Unexpected error."
    @State private var alertMessage: String = ""
    @State private var isPopAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text(self.addressTypeIndex == 0 ? "Header_IP_ADDRESS" : "Header_HOST_NAME").font(.system(size: 16, weight: .semibold)),
                        footer: object.appSettingDescription ? Text("Footer_ADDRESS_HOST").font(.system(size: 12)) : nil) {
                    TextField(self.addressTypeIndex == 0 ? "8.8.8.8" : "dns.google", text: $hostString)
                        .keyboardType(self.addressTypeIndex == 0 ? .decimalPad : .URL)
                }
                Picker("", selection: self.$addressTypeIndex) {
                    Text("Label_IPv4_address").tag(0)
                    Text("Label_FQDN").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .listStyle(PlainListStyle())
            
            Form {
                Button(action: {
                    SocLogger.debug("AddressRegister: Button: Register")
                    do {
                        let address = try self.getAddress()
                        self.object.addresses.append(address)
                        SocPingSharedObject.saveAddresses(addresses: self.object.addresses)
                        self.presentationMode.wrappedValue.dismiss()
                    }
                    catch let error as SocError {
                        self.alertTitle = error.message
                        self.alertMessage = error.detail
                        self.isPopAlert = true
                    }
                    catch let error as SocPingError {
                        self.alertTitle = error.message
                        self.alertMessage = ""
                        self.isPopAlert = true
                    }
                    catch {
                        SocLogger.error("AddressRegister: \(error)")
                        assertionFailure("AddressRegister: \(error)")
                        self.isPopAlert = true
                    }
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
                .alert(isPresented: self.$isPopAlert) {
                    Alert(title: Text(self.alertTitle), message: Text(self.alertMessage))
                }
            }
            .frame(height: 110)
        }
        .navigationBarTitle("New Address", displayMode: .inline)
    }
    
    func getAddress() throws -> SocAddress {
        if self.hostString.isEmpty {
            SocLogger.debug("AddressRegister.getAddress: no host")
            throw SocPingError.NoHostValue
        }
        var newAddress: SocAddress
        if self.addressTypeIndex == 0 {
            newAddress = SocAddress(family: AF_INET, addr: hostString)
            try newAddress.resolveHostName()
        }
        else {
            newAddress = try SocAddress.getAddressByName(name: hostString)
        }
        for address in self.object.addresses {
            if address.addr == newAddress.addr {
                SocLogger.debug("AddressRegister.getAddress: \(address.addr) exists")
                throw SocPingError.AlreadyAddressExist
            }
        }
        var ngList: [String] = ["0.0.0.0", "255.255.255.255"]
        for i in 0 ..< object.interfaces.count {
            if object.interfaces[i].isActive {
                ngList.append(object.interfaces[i].inet.addr)
            }
            if object.interfaces[i].hasNetmask {
                ngList.append(object.interfaces[i].netmask.addr)
            }
            if object.interfaces[i].hasBroadcast {
                ngList.append(object.interfaces[i].broadcast.addr)
            }
        }
        if ngList.contains(newAddress.addr) {
            SocLogger.debug("AddressRegister.getAddress: \(newAddress.addr) is reserved address")
            throw SocPingError.ReservedAddress
        }
        if self.object.addresses.count >= SocPingAddressManager.maxRegistNumber {
            SocLogger.debug("AddressRegister.getAddress: Can't register anymore")
            throw SocPingError.AddressExceeded
        }
        SocLogger.debug("AddressRegister.getAddress: address registerd - \(newAddress.addr):\(newAddress.hostName)")
        return newAddress
    }
}

