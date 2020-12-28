//
//  ContentView.swift
//  SocPing
//
//  Created by Hirose Manabu on 2021/01/01.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State var isPresented: Bool = true
    @State private var selection = SocPingEcho.actionTypePing
    
    private let tabImages = ["circle", "arrow.triangle.swap", "1.circle", "globe", "gearshape.2"]
    
    init() {
        if UserDefaults.standard.bool(forKey: "isAgreed") {
            _isPresented = State(initialValue: false)
        }
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ForEach(0 ..< 3, id: \.self) { i in
                NavigationView {
                    SocPingList(actionType: i)
                        .navigationBarTitle(SocPingEcho.actionNames[i], displayMode: .inline)
                }
                .tabItem {
                    VStack {
                        Image(systemName: tabImages[i])
                        Text(SocPingEcho.actionNames[i])
                    }
                }
                .tag(i)
                .navigationViewStyle(StackNavigationViewStyle())
            }
            
            NavigationView {
                SocPingAddressManager()
            }
            .tabItem {
                VStack {
                    Image(systemName: tabImages[3])
                    Text("Address")
                }
            }
            .tag(3)
            .navigationViewStyle(StackNavigationViewStyle())
            
            NavigationView {
                SocPingMenu()
            }
            .tabItem {
                VStack {
                    Image(systemName: tabImages[4])
                    Text("Menu")
                }
            }
            .tag(4)
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(isPresented: self.$isPresented) {
            VStack(spacing: 0) {
                ZStack {
                    Color(red: 0.000, green: 0.478, blue: 1.000, opacity: 1.0)
                        .edgesIgnoringSafeArea(.all)
                    HStack(alignment: .center) {
                        Spacer()
                        Text("ToS_Title")
                            .foregroundColor(Color.white)
                            .font(.system(size: 20, weight: .semibold))
                        Spacer()
                    }
                }
                .frame(height: 50)

                WebView(url: self.getTermsURL())
                
                ZStack {
                    Color(red: 0.918, green: 0.918, blue: 0.937, opacity: 1.0)
                        .edgesIgnoringSafeArea(.all)
                    Button(action: {
                        SocLogger.debug("ContentView: Button: Agree")
                        UserDefaults.standard.set(true, forKey: "isAgreed")
                        UserDefaults.standard.set(Date(), forKey: "agreementDate")
                        self.isPresented = false
                    }) {
                        HStack {
                            Spacer()
                            Text("ToS_Agree")
                                .font(.system(size: 20))
                            Spacer()
                        }
                    }
                }
                .frame(height: 60)
            }
        }
    }
    
    private func getTermsURL() -> URL {
        let url = Bundle.main.url(forResource: SocPingSharedObject.isJa ? "TermsOfService_ja" : "TermsOfService", withExtension: "html")
        assert(url != nil, "Bundle.main.url failed")
        return url!
    }
}

fileprivate struct WebView: UIViewRepresentable {
    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
