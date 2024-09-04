//
//  LeaderboardView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 7/17/24.
//

import SwiftUI

struct LeaderboardView: View {
    @State var leaderboard: [UserPoints] = []
    
    var body: some View {
        List {
            if leaderboard.count > 2 {
                Section {
                    HStack {
                        Label("1", systemImage: "trophy.fill").labelStyle(.iconOnly).foregroundStyle(Color.yellow).padding(.trailing)
                        Text(String(leaderboard[0].username))
                        Spacer()
                        Text(String(leaderboard[0].lifetime))
                    }
                    HStack {
                        Label("2", systemImage: "trophy.fill").labelStyle(.iconOnly).foregroundStyle(Color.gray).padding(.trailing)
                        Text(String(leaderboard[1].username))
                        Spacer()
                        Text(String(leaderboard[1].lifetime))
                    }
                    HStack {
                        Label("3", systemImage: "trophy.fill").labelStyle(.iconOnly).foregroundStyle(Color(red: 0.6392, green: 0.2824, blue: 0.1529)).padding(.trailing)
                        Text(String(leaderboard[2].username))
                        Spacer()
                        Text(String(leaderboard[2].lifetime))
                    }
                }
            }
            Section {
                ForEach(leaderboard, id: \.id) { user in
                    HStack {
                        Text(String(user.username))
                        Spacer()
                        Text(String(user.lifetime))
                    }
                }
            }
        }
        .onAppear {
            reloadLeaderboard()
        }
        .refreshable {
            reloadLeaderboard()
        }
    }
    
    func loadLeaderboardTask(completion: @escaping ([UserPoints]) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/board/lifetime/top") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        let requestTask = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode([UserPoints].self, from: data)
                    DispatchQueue.main.async {
                        completion(result)
                    }
                } catch {
                    print("parse error")
                    completion([])
                }
            } else if let error = error {
                print("fetch error: \(error)")
                completion([])
            }
        }
        requestTask.resume()
    }
    
    func reloadLeaderboard() {
        loadLeaderboardTask { board in
            leaderboard = board
        }
    }
}

#Preview {
    LeaderboardView()
}

