//
//  EventsView.swift
//  ma-central-admin
//
//  Created by Jayen Agrawal on 7/14/24.
//

import SwiftUI

struct EventsView: View {
    @EnvironmentObject var appState: AppState
    @State private var lastDeletedIndex: Int?
    @State private var lastDeletedId: String = "-1"
    @State private var showConfirmDialog: Bool = false
    var dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(appState.futureEvents, id: \.id) { event in
                    NavigationLink(destination: {
                        ScanView(eventId: event.id, eventTitle: event.title)
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
                .onDelete { indexSet in
                    lastDeletedIndex = Array(indexSet).max()
                    lastDeletedId = String(appState.futureEvents[lastDeletedIndex ?? 0].id)
                    showConfirmDialog = true
                }
            }
            .navigationTitle("Events")
            .alert(isPresented: $showConfirmDialog) {
                Alert(
                    title: Text("Delete Event \(self.lastDeletedId)"),
                    message: Text(
                        "are you sure you would like to delete this event? this action is irreversable."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteEvent(id: lastDeletedId)
                    },
                    secondaryButton: .cancel()
                )
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: {
                        NewEvent()
                    }, label: {
                        Label("new event", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    })
                }
            }
            .onAppear {
                URLCache.shared.removeAllCachedResponses()
                appState.refreshFutureEvents()
            }
            .refreshable {
                URLCache.shared.removeAllCachedResponses()
                appState.refreshFutureEvents()
            }
        }
    }
}

func deleteEvent(id: String) {
    guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/manage/events/delete/\(id)") else {
        return
    }
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.httpShouldHandleCookies = true
    let requestTask = sharedSession.dataTask(with: request) {
        (data: Data?, response: URLResponse?, error: Error?) in
        if let data = data {
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        } else if let error = error {
            print("fetch error: \(error)")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    requestTask.resume()
}

#Preview {
    EventsView()
}
