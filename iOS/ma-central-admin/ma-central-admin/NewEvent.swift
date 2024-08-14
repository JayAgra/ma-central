//
//  NewEvent.swift
//  ma-central-admin
//
//  Created by Jayen Agrawal on 8/14/24.
//

import SwiftUI
import MapKit

struct NewEvent: View {
    @State private var eventTitle: String = ""
    @State private var eventDescription: String = ""
    @State private var eventStart: Int64 = 0
    @State private var eventEnd: Int64 = 0
    @State private var eventLocationString: String = ""
    @State private var eventLatitude: Double = 0
    @State private var eventLongitude: Double = 0
    @State private var eventImageURL: String = ""
    @State private var eventRewardPoints: Int = 0
    
    @State private var selectedStartDate = Date()
    @State private var selectedEndDate = Date()
    @State private var selectedCoordinate: MapAnnotationItem?
    @State private var showCoordinate = false
    @State private var eventPointString: String = ""
    
    @State private var status: Int? = nil
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.46258, longitude: -122.17457),
        span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
    )
    
    var body: some View {
        VStack {
            if status == nil {
                Form {
                    Section {
                        TextField("Event Title", text: $eventTitle)
                        TextField("Event Description", text: $eventDescription)
                    }
                    Section {
                        DatePicker("Event Start", selection: $selectedStartDate, displayedComponents: [.date, .hourAndMinute])
                            .onChange(of: selectedStartDate) { date in
                                eventStart = Int64(date.timeIntervalSince1970 * 1000)
                            }
                        DatePicker("Event End", selection: $selectedEndDate, in: selectedStartDate..., displayedComponents: [.date, .hourAndMinute])
                            .onChange(of: selectedEndDate) { date in
                                eventEnd = Int64(date.timeIntervalSince1970 * 1000)
                            }
                    }
                    Section {
                        TextField("Human Readable Location", text: $eventLocationString)
                        Text("Find the location on the map, zoom in close, and ensure the location is directly in the center. Tap to select a point.")
                        Map(coordinateRegion: $mapRegion, interactionModes: .all, showsUserLocation: false, annotationItems: selectedCoordinate == nil ? [] : [selectedCoordinate!]) { coordinate in
                            MapPin(coordinate: coordinate.coordinate, tint: .blue)
                        }
                        .onTapGesture {
                            let location = CLLocationCoordinate2D(latitude: mapRegion.center.latitude, longitude: mapRegion.center.longitude)
                            selectedCoordinate = MapAnnotationItem(coordinate: location)
                            showCoordinate = true
                            eventLatitude = location.latitude
                            eventLongitude = location.longitude
                        }
                        .frame(height: 300)
                    }
                    Section {
                        Text("The event image URL must be a direct URL to a publicly accessible image, either 640x320 or 1280x640.")
                        TextField("Event Image URL", text: $eventImageURL)
                    }
                    Section {
                        TextField("Point Reward", text: $eventPointString)
                            .onChange(of: eventPointString) { points in
                                if let points = Int(points) {
                                    eventRewardPoints = points
                                }
                            }
                    }
                    Button(action: {
                        self.status = 0
                        submitData { result in
                            self.status = result
                        }
                    }, label: {
                        Text("Create Event")
                    })
                }
            } else {
                if status == 0 {
                    VStack {
                        Spacer()
                        ProgressView()
                            .controlSize(.large)
                            .padding()
                        Spacer()
                    }
                } else if status == 1 {
                    VStack {
                        Spacer()
                        Label("done", systemImage: "checkmark.seal.fill")
                            .labelStyle(.iconOnly)
                            .font(.largeTitle)
                            .foregroundStyle(Color.green)
                            .padding()
                        Text("done")
                            .font(.title)
                        Spacer()
                    }
                } else {
                    VStack {
                        Spacer()
                        Label("done", systemImage: "xmark.seal.fill")
                            .labelStyle(.iconOnly)
                            .font(.largeTitle)
                            .foregroundStyle(Color.red)
                            .padding()
                        Text("error")
                            .font(.title)
                            .padding()
                        Button(action: {
                            self.status = nil
                        }, label: {
                            Label("close", systemImage: "xmark")
                                .labelStyle(.titleOnly)
                        })
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Create Event")
    }
    
    func submitData(completionBlock: @escaping (Int) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/manage/events/create") else {
            return
        }
        
        let eventData = EventDataExport(start_time: Int(eventStart), end_time: Int(eventEnd), title: eventTitle, human_location: eventLocationString, latitude: eventLatitude, longitude: eventLongitude, details: eventDescription, image: eventImageURL, point_reward: eventRewardPoints)
        do {
            let jsonData = try JSONEncoder().encode(eventData)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.httpShouldHandleCookies = true
            let requestTask = sharedSession.dataTask(with: request) {
                (data: Data?, response: URLResponse?, error: Error?) in
                if data != nil {
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            completionBlock(1)
                        } else {
                            completionBlock(2)
                        }
                    } else {
                        completionBlock(2)
                    }
                } else {
                    completionBlock(2)
                }
            }
            requestTask.resume()
        } catch {
            completionBlock(2)
        }
    }
}

#Preview {
    NewEvent()
}

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct EventDataExport: Codable {
    let start_time: Int
    let end_time: Int
    let title: String
    let human_location: String
    let latitude: Double
    let longitude: Double
    let details: String
    let image: String
    let point_reward: Int
}
