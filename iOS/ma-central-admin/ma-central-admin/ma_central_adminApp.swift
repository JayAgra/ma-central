//
//  ma_central_adminApp.swift
//  ma-central-admin
//
//  Created by Jayen Agrawal on 7/14/24.
//

import SwiftUI

@main
struct ma_central_adminApp: App {
    @StateObject public var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.sessionOk {
                TabView(selection: $appState.selectedTab) {
                    EventsView()
                        .environmentObject(appState)
                        .tabItem {
                            Label("events", systemImage: "calendar")
                        }
                        .tag(Tab.events)
                    ScanView()
                        .environmentObject(appState)
                        .tabItem {
                            Label("scan", systemImage: "barcode.viewfinder")
                        }
                        .tag(Tab.scan)
                }
                .preferredColorScheme(.dark)
                .environmentObject(appState)
            } else {
                LoginView()
                    .environmentObject(appState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
