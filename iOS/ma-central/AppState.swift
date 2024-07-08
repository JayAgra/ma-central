//
//  AppState.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/5/24.
//

import Foundation
import Combine

enum Tab {
    case home, events, settings
}

struct UserData {
    let id: Int
    let username, full_name: String
    let lifetime, score: Int
    let data: String
}

class AppState: ObservableObject {
#if targetEnvironment(macCatalyst)
    @Published public var selectedTab: Tab? = .home
#else
    @Published public var selectedTab: Tab = .home
#endif
    @Published public var sessionOk: Bool = true
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        $selectedTab
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            .store(in: &cancellables)
    }
}
