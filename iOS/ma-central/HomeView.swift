//
//  ContentView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 5/28/24.
//

import SwiftUI

struct HomeView: View {
    @State private var firstLoad = false
    @EnvironmentObject var appState: AppState
    var dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    if let user = appState.currentUser.first {
                        VStack {
                            HStack {
                                Text(user.username)
                                    .font(.largeTitle)
                                Spacer()
                                Text(String(user.score))
                                    .font(.title2)
                                Text("pts")
                            }
                            NavigationLink(destination: {
                                LeaderboardView()
                                    .navigationTitle("Leaderboard")
                            }, label: {
                                HStack {
                                    Spacer()
                                    Text("Leaderboard")
                                }
                            })
                        }
                        .padding()
                    } else {
                        LoadingDataView(message: "loading account data")
                    }
                    VStack {
                        ForEach(appState.futureEvents.prefix(2), id: \.id) { event in
                            NavigationLink(destination: {
                                EventDetailView(event_id: event.id, image: event.image, date: dateFormatter.string(from: Date(timeIntervalSince1970: Double(event.start_time) / 1000)), title: event.title, location: event.human_location, latitude: event.latitude, longitude: event.longitude, details: event.details, pointReward: event.point_reward)
                            }, label: {
                                CardView(image: event.image, date: String(event.start_time), title: event.title, location: event.human_location, dimensions: CGPoint(x: geometry.size.width * 0.9, y: geometry.size.width * 0.45))
                            })
                        }
                    }
                }
                .navigationTitle("M-A Central")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear() {
            if !firstLoad {
                appState.refreshFutureEvents()
                if !appState.currentUser.isEmpty && appState.currentUser[0].id != 0 { appState.refreshUserJson() }
                firstLoad = true
            }
        }
        .refreshable {
            if !appState.currentUser.isEmpty && appState.currentUser[0].id != 0 { appState.refreshUserJson() }
            appState.refreshFutureEvents()
        }
    }
}

#Preview {
    HomeView()
}
