//
//  EventView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 8/14/24.
//

import SwiftUI

struct EventView: View {
    @EnvironmentObject var appState: AppState
    var dateFormatter = DateFormatter()
    @State private var searchText: String = "" 
    
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(searchResults, id: \.id) { event in
                    NavigationLink(destination: {
                        EventDetailView(event_id: event.id, image: event.image, date: String(dateFormatter.string(from: Date(timeIntervalSince1970: Double(event.start_time) / 1000))), title: event.title, location: event.human_location, latitude: event.latitude, longitude: event.longitude, details: event.details, pointReward: event.point_reward)
                    }, label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.title)
                                    .lineLimit(1)
                                Text(dateFormatter.string(from: Date(timeIntervalSince1970: Double(event.start_time) / 1000)))
                            }
                        }
                    })
                }
            }
            .navigationTitle("Events")
        }
        .searchable(text: $searchText)
    }
    
    var searchResults: [Event] {
        if searchText.isEmpty {
            return appState.futureEvents
        } else {
            return appState.futureEvents.filter { $0.title.lowercased().contains(searchText.lowercased()) || dateFormatter.string(from: Date(timeIntervalSince1970: Double($0.start_time) / 1000)).lowercased().contains(searchText.lowercased()) || $0.human_location.lowercased().contains(searchText.lowercased()) }
        }
    }
}

#Preview {
    EventView()
}
