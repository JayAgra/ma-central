//
//  HomeViewMeCarousel.swift
//  ma-central
//
//  Created by Jayen Agrawal on 7/8/24.
//

import SwiftUI

struct HomeViewMeCarousel: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            ForEach(appState.futureEvents, id: \.id) { event in
                NavigationLink(destination: {
                    EventDetailView(image: event.image, date: String(event.start_time), title: event.title, location: event.human_location, latitude: event.latitude, longitude: event.longitude, details: event.details)
                }, label: {
                    CardView(image: event.image, date: String(event.start_time), title: event.title, location: event.human_location, dimensions: CGPoint(x: 275, y: 325))
                })
            }
        }
    }
}

#Preview {
    HomeViewMeCarousel()
}
