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
                VStack {
                    HStack {
                        Text("Jayen")
                            .font(.largeTitle)
                            .padding(.leading)
                        Spacer()
                    }
                    HStack {
                        Text("129")
                            .font(.title2)
                        Text("points")
                        Spacer()
                        Text("fancy points bar here")
                    }
                    .padding()
                }
                .padding()
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
                /*
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
                */
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
    }
}

#Preview {
    HomeView()
}
