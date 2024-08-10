//
//  EventDetailView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/12/24.
//

import SwiftUI
import Kingfisher
import MapKit

struct EventDetailView: View {
    @EnvironmentObject var appState: AppState
    var event_id: Int
    var image: String
    var date: String
    var title: String
    var location: String
    var latitude: Double
    var longitude: Double
    var details: String
    var pointReward: Int
    var humanDate: String
    
    init(event_id: Int, image: String, date: String, title: String, location: String, latitude: Double, longitude: Double, details: String, pointReward: Int) {
        self.event_id = event_id
        self.image = image
        self.date = date
        self.title = title
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.details = details
        self.pointReward = pointReward
        
        if let unixTimestampMillis = Double(date) {
            let unixTimestampSeconds = unixTimestampMillis / 1000
            let date = Date(timeIntervalSince1970: unixTimestampSeconds)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            dateFormatter.locale = Locale.current
            humanDate = dateFormatter.string(from: date)
        } else {
            humanDate = "Date Conversion Failure"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
        VStack {
            KFImage(URL(string: image == "" ? "https://jayagra.com/static-ish/IMG_6901.png?v=101" : image)!)
                .resizable()
                .aspectRatio(contentMode: .fit)
            VStack {
                ScrollView {
                    Text(humanDate)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(title)
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                    Text("\(location.uppercased())\n\n")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(details)
                        .foregroundColor(.primary)
                    if #available(iOS 17.0, *) {
                        Spacer()
                        Map(initialPosition:
                                MapCameraPosition.region(
                                    MKCoordinateRegion(
                                        center:
                                            CLLocationCoordinate2D(
                                                latitude: latitude,
                                                longitude: longitude
                                            ),
                                        span:
                                            MKCoordinateSpan(
                                                latitudeDelta: 0.05,
                                                longitudeDelta: 0.05
                                            )
                                    )
                                )
                        ) {
                            Marker(title, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        }
                        .mapStyle(.standard)
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.4)
                        .cornerRadius(10)
                        .padding(.vertical)
                    } else {
                        // Fallback on earlier versions
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer()
        }
    }
    }
    
}

#Preview {
    EventDetailView(event_id: 1, image: "ImagePlaceholder", date: "Jan 1, 1970", title: "Event Title", location: "Event Location", latitude: 0.0, longitude: 0.0, details: "Details About Event", pointReward: 10)
}
