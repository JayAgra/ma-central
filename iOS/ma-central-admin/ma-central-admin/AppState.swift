//
//  AppState.swift
//  ma-central-admin
//
//  Created by Jayen Agrawal on 7/14/24.
//

import Foundation
import Combine

enum Tab {
    case events, tickets, users, scan
}

class AppState: ObservableObject {
    @Published public var selectedTab: Tab = .events
    @Published public var sessionOk: Bool = false
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        $selectedTab
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            .store(in: &cancellables)

        self.checkLoginState()
    }
    
    func checkLoginState() {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/auth/admin") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        let requestTask = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.sessionOk = true
                } else {
                    self.sessionOk = false
                }
            } else {
                self.sessionOk = false
            }
        }
        requestTask.resume()
    }
}
