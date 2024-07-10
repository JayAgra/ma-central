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
#if targetEnvironment(macCatalyst)
                NavigationView {
                    List(selection: $appState.selectedTab) {
                        Label("home", systemImage: "house")
                            .tag(Tab.home)
                        Label("events", systemImage: "calendar")
                            .tag(Tab.events)
                        Label("settings", systemImage: "gear")
                            .tag(Tab.settings)
                    }
                    .navigationTitle("bearTracks")
                    switch appState.selectedTab {
                    case .home:
                        HomeView()
                            .environmentObject(appState)
                    case .events:
                        EventsView()
                            .environmentObject(appState)
                    case .settings:
                        SettingsView()
                            .environmentObject(appState)
                    case nil:
                        LoginView()
                            .environmentObject(appState)
                    }
                }
                .preferredColorScheme(.dark)
                .environmentObject(appState)
#else
                TabView(selection: $appState.selectedTab) {
                    HomeView()
                        .environmentObject(appState)
                        .tabItem {
                            Label("home", systemImage: "house")
                        }
                        .tag(Tab.home)
                    EventsView()
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
                .preferredColorScheme(.dark)
                .environmentObject(appState)
#endif
            } else {
                LoginView()
                    .environmentObject(appState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
