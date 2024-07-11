//
//  HomeViewUpcomingCarousel.swift
//  ma-central
//
//  Created by Jayen Agrawal on 7/8/24.
//

import SwiftUI

struct HomeViewUpcomingCarousel: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            ForEach(appState.futureEvents, id: \.id) { event in
                NavigationLink(destination: {
                    EventDetailView(image: event.image, date: String(event.start_time), title: event.title, location: event.human_location, latitude: event.latitude, longitude: event.longitude, details: event.details)
                        .environmentObject(appState)
                }, label: {
                    CardView(image: event.image, date: String(event.start_time), title: event.title, location: event.human_location, dimensions: CGPoint(x: 275, y: 325))
                })
            }
        }
    }
}

#Preview {
    HomeViewUpcomingCarousel()
}
