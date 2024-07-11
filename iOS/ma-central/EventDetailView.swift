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
    @State private var ticketPurchase: Bool = false
    @State private var ticketPurchaseActivity: Bool = false
    @State private var ticketPurchaseStatus: TicketPurchaseStatus?
    @State private var ticket: Ticket?
    var event_id: Int
    var image: String
    var date: String
    var title: String
    var location: String
    var latitude: Double
    var longitude: Double
    var details: String
    var ticketPrice: Int
    var lastSaleDate: Int
    
    var body: some View {
        if !ticketPurchase {
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
                                ticketPurchase = true
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
        } else {
            // ticket purchasing
            if !ticketPurchaseActivity {
                VStack {
                    VStack {
                        Text("ticket purchase\n")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(.primary)
                        Text(date)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(title)
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                        Text("\(location.uppercased())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    if Int(Date().timeIntervalSince1970 * 1_000) >= lastSaleDate {
                        Spacer()
                        VStack {
                            Text("Ticket sales have ended for his event.")
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    } else {
                        Spacer()
                        VStack {
                            Text("Ticket price:")
                                .font(.headline)
                            Text("\(ticketPrice) point(s)")
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    VStack {
                        Button(action: {
                            ticketPurchaseActivity = true
                            purchaseTicket { result in
                                ticket = result
                            }
                        }) {
                            Text("Purchase Ticket")
                        }
                        .padding()
                    }
                }
            } else {
                // currently obtaining ticket
                if ticketPurchaseStatus == .none {
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if ticketPurchaseStatus == .Success {
                    VStack {
                        Spacer()
                        Text("Ticket obtained.")
                            .font(.title)
                        Text("\n\nTicket Id:\n\(ticket?.id ?? 0)")
                            .font(.caption)
                        Spacer()
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("Could not obtain ticket.")
                        switch ticketPurchaseStatus {
                        case .ErrorInternalServerError:
                            Text("Internal server error.")
                        case .ErrorBadRequest:
                            Text("Bad request.")
                        case .ErrorTicketSaleEnded:
                            Text("Ticket sale ended.")
                        case .ErrorBalanceTooLow:
                            Text("Point balance too low.")
                        case .none, .some(.Success):
                            Text("Unknown Error.")
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    func purchaseTicket(completionBlock: @escaping (Ticket?) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/tickets_create/\(event_id)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        let requestTask = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            let result = try decoder.decode(Ticket.self, from: data)
                            DispatchQueue.main.async {
                                ticketPurchaseStatus = .Success
                                completionBlock(result)
                            }
                        } catch {
                            ticketPurchaseStatus = .ErrorInternalServerError
                            completionBlock(nil)
                        }
                    } else if error != nil {
                        ticketPurchaseStatus = .ErrorInternalServerError
                        completionBlock(nil)
                    }
                } else {
                    if httpResponse.statusCode == 400 {
                        ticketPurchaseStatus = .ErrorBadRequest
                    } else if httpResponse.statusCode == 403 {
                        ticketPurchaseStatus = .ErrorBalanceTooLow
                    } else if httpResponse.statusCode == 423 {
                        ticketPurchaseStatus = .ErrorTicketSaleEnded
                    } else {
                        ticketPurchaseStatus = .ErrorInternalServerError
                    }
                }
            } else {
                ticketPurchaseStatus = .ErrorInternalServerError
            }
        }
        requestTask.resume()
    }
}

enum TicketPurchaseStatus {
    case ErrorInternalServerError, ErrorBadRequest, ErrorTicketSaleEnded, ErrorBalanceTooLow, Success
}

#Preview {
    EventDetailView(event_id: 1, image: "ImagePlaceholder", date: "Jan 1, 1970", title: "Event Title", location: "Event Location", latitude: 0.0, longitude: 0.0, details: "Details About Event", ticketPrice: 10, lastSaleDate: 1)
}
