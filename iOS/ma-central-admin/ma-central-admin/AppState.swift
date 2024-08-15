//
//  AppState.swift
//  ma-central-admin
//
//  Created by Jayen Agrawal on 7/14/24.
//

import Foundation

class AppState: ObservableObject {
    @Published public var sessionOk: Bool = false
    @Published public var futureEvents: [Event] = []
    
    init() {
        self.checkLoginState()
        self.refreshFutureEvents()
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
    
    func loadEventsJson(type: String, completionBlock: @escaping ([Event]) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/events/\(type)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let requestTask = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode([Event].self, from: data)
                    DispatchQueue.main.async {
                        completionBlock(result.sorted { $0.start_time < $1.start_time })
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
    let point_reward: Int
}
