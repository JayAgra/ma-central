//
//  SettingsManager.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/5/24.
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    
    private init() {
        let defaults: [String: Any] = [
            "darkMode": true,
        ]
        UserDefaults().register(defaults: defaults)
    }
}
