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
    var image: String
    var date: String
    var title: String
    var location: String
    var latitude: Double
    var longitude: Double
    var details: String
    
    var body: some View {
        VStack {
            KFImage(URL(string: image == "" ? "https://jayagra.com/static-ish/IMG_6901.png?v=101" : image)!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea(.container)
            VStack {
                Text(date)
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
/*
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
     .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.25)
     .cornerRadius(10)
     .padding(.vertical)
 } else {
     // Fallback on earlier versions
 }
 */
                Spacer()
                if let user = appState.currentUser.first {
                    if user.id == 0 {
                        GuestAccessRestricted(message: "an account is required to register")
                    } else {
                        Button(action: {
                            
                        }, label: {
                            Label("Sign Up", systemImage: "plus")
                        })
                        .padding()
                    }
                } else {
                    LoadingDataView(message: "loading account data")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer()
        }
    }
}

#Preview {
    EventDetailView(image: "ImagePlaceholder", date: "Jan 1, 1970", title: "Event Title", location: "Event Location", latitude: 0.0, longitude: 0.0, details: "Details About Event")
}
