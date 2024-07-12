//
//  EventsView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/5/24.
//

import SwiftUI

struct EventsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack {
                        ForEach(appState.futureEvents, id: \.id) { event in
                            NavigationLink(destination: {
                                EventDetailView(event_id: event.id, image: event.image, date: String(event.start_time), title: event.title, location: event.human_location, latitude: event.latitude, longitude: event.longitude, details: event.details, ticketPrice: event.ticket_price, lastSaleDate: event.last_sale_date)
                                    .environmentObject(appState)
                            }, label: {
                                CardView(image: event.image, date: String(event.start_time), title: event.title, location: event.human_location, dimensions: CGPoint(x: geometry.size.width * 0.9, y: geometry.size.width * 0.45))
                            })
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .navigationTitle("Events")
            }
        }
        .onAppear {
            appState.refreshFutureEvents()
        }
        .refreshable {
            appState.refreshFutureEvents()
        }
    }
}

#Preview {
    EventsView()
}
