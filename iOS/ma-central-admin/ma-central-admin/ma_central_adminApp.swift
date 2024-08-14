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
                EventsView()
                    .environmentObject(appState)
                    .preferredColorScheme(.dark)
            } else {
                LoginView()
                    .environmentObject(appState)
                    .preferredColorScheme(.dark)
            }
        }
    }
}
