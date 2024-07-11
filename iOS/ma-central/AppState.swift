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
    @Published public var sessionOk: Bool = false
    @Published public var futureEvents: [Event] = []
    @Published public var userTickets: [Ticket] = []
    @Published public var currentUser: [UserPoints] = []
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        $selectedTab
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            .store(in: &cancellables)
        
        self.loadCurrentUserJson { user in
            self.currentUser = user
        }
    }
    
    func loadEventsJson(type: String, completionBlock: @escaping ([Event]) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/events/\(type)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        let requestTask = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
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
    
    func loadCurrentUserJson(completionBlock: @escaping ([UserPoints]) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/auth/whoami") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        let requestTask = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.sessionOk = true
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            let result = try decoder.decode([UserPoints].self, from: data)
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
                } else {
                    self.sessionOk = false
                }
            } else {
                self.sessionOk = false
            }
        }
        requestTask.resume()
    }
    
    func refreshUserJson() {
        self.loadCurrentUserJson { (output) in
            self.currentUser = output
        }
    }
    
    func loadTicketsJson(completionBlock: @escaping ([Ticket]) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/tickets/user_valid/0") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        let requestTask = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode([Ticket].self, from: data)
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
    
    func refreshUserTickets() {
        self.loadTicketsJson() { (output) in
            self.userTickets = output
        }
    }
}

struct Event: Codable {
    let id, start_time, end_time: Int
    let title, human_location: String
    let latitude, longitude: Double
    let details: String
    let image: String
    let ticket_price, last_sale_date: Int
}

struct Ticket: Codable {
    let id, event_id, holder_id, single_entry, expended, creation_date: Int
}

struct UserPoints: Codable {
    let id: Int
    let username: String
    let lifetime, score: Int
}
