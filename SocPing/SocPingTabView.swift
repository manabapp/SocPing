//
//  SocPingTabView.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import SwiftUI

struct SocPingTabView: View {
    @State private var selection = 2  // Ping
    
    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                SocPingAddressManager()
            }
            .tabItem {
                VStack {
                    Image(systemName: "globe")
                    Text("Address")
                }
            }
            .tag(0)
            .navigationViewStyle(StackNavigationViewStyle())
            
            NavigationView {
                SocPingList(actionType: SocPingList.actionTypeOnePing)
            }
            .tabItem {
                VStack {
                    Image(systemName: "1.circle")
                    Text("One Ping")
                }
            }
            .tag(1)
            .navigationViewStyle(StackNavigationViewStyle())
            
            NavigationView {
                SocPingList(actionType: SocPingList.actionTypePing)
            }
            .tabItem {
                VStack {
                    Image(systemName: "circle")
                    Text("Ping")
                }
            }
            .tag(2)
            .navigationViewStyle(StackNavigationViewStyle())
            
            NavigationView {
                SocPingList(actionType: SocPingList.actionTypeTraceroute)
            }
            .tabItem {
                VStack {
                    Image(systemName: "arrow.triangle.swap")
                    Text("Traceroute")
                }
            }
            .tag(3)
            .navigationViewStyle(StackNavigationViewStyle())
            
            NavigationView {
                SocPingMenu()
            }
            .tabItem {
                VStack {
                    Image(systemName: "gearshape.2")
                    Text("Menu")
                }
            }
            .tag(4)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
