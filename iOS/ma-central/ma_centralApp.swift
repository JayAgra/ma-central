//
//  ma_centralApp.swift
//  ma-central
//
//  Created by Jayen Agrawal on 5/28/24.
//

import SwiftUI

@main
struct ma_centralApp: App {
    let settingsManager = SettingsManager.shared
    @StateObject public var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.sessionOk {
                TabView(selection: $appState.selectedTab) {
                    HomeView()
                        .environmentObject(appState)
                        .tabItem {
                            Label("home", systemImage: "house")
                        }
                        .tag(Tab.home)
                    EventView()
                        .environmentObject(appState)
                        .tabItem {
                            Label("events", systemImage: "calendar")
                        }
                        .tag(Tab.events)
                    SettingsView()
                        .environmentObject(appState)
                        .tabItem {
                            Label("settings", systemImage: "gear")
                        }
                        .tag(Tab.settings)
                }
                .environmentObject(appState)
            } else {
                LoginView()
                    .environmentObject(appState)
            }
        }
    }
}
