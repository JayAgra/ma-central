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
    @Published public var futureEvents: [Event] = []
    @Published public var eventsLoading: Bool = false
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        $selectedTab
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            .store(in: &cancellables)
        
        checkLoginState { isLoggedIn in
            self.sessionOk = isLoggedIn
        }
    }
    
    func loadEventsJson(type: String, completionBlock: @escaping ([Event]) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/events/\(type)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        eventsLoading = true
        
        let requestTask = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            self.eventsLoading = false
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode([Event].self, from: data)
                    DispatchQueue.main.async {
                        completionBlock(result)
                    }
                } catch {
                    print("parse error")
                    completionBlock([])
                }
            } else if let error = error {
                print("fetch error: \(error)")
                completionBlock([])
            }
        }
        requestTask.resume()
    }
    
    func refreshFutureEvents() {
        self.loadEventsJson(type: "future") { (output) in
            self.futureEvents = output
        }
    }
}

struct Event: Codable {
    let id, start_time, end_time: Int
    let title, human_location: String
    let latitude, longitude: Double
    let details: String
    let image: String
}
