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
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let user = appState.currentUser.first {
                    VStack {
                        HStack {
                            Text(user.username)
                                .font(.largeTitle)
                                .padding(.leading)
                            Spacer()
                        }
                        HStack {
                            Text(String(user.score))
                                .font(.title2)
                            Text("points")
                            Spacer()
                            Text("fancy points bar here")
                        }
                        .padding()
                    }
                    .padding()
                } else {
                    LoadingDataView(message: "loading account data")
                }
                VStack(alignment: .leading) {
                    Text("Upcoming Events")
                        .font(.title2)
                        .padding(.leading)
                    ScrollView(.horizontal) {
                        HomeViewUpcomingCarousel()
                            .environmentObject(appState)
                    }
                    .background(Color.secondary.opacity(0.1))
                }
                .padding(.vertical)
                if let user = appState.currentUser.first {
                    if user.id == 0 {
                        GuestAccessRestricted(message: "an account is required to access this feature")
                    } else {
                        VStack(alignment: .leading) {
                            Text("Your Events")
                                .font(.title2)
                                .padding(.leading)
                            ScrollView(.horizontal) {
                                HomeViewMeCarousel()
                                    .environmentObject(appState)
                            }
                            .background(Color.secondary.opacity(0.1))
                        }
                         .padding(.vertical)
                    }
                } else {
                    LoadingDataView(message: "loading account data")
                }
            }
            .navigationTitle("App Name")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear() {
            if !firstLoad {
                appState.refreshFutureEvents()
                firstLoad = true
            }
        }
        .refreshable {
            appState.refreshUserJson()
            appState.refreshFutureEvents()
        }
    }
}

#Preview {
    HomeView()
}
