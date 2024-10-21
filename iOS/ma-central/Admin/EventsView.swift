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
    @State private var lastDeletedName: String = ""
    @State private var showConfirmDialog: Bool = false
    @State public var allEvents: [Event] = []
    var dateFormatter = DateFormatter()
    
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allEvents, id: \.id) { event in
                    NavigationLink(destination: {
                        ScanView(eventId: event.id, eventTitle: event.title)
                    }, label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.title)
                                    .lineLimit(1)
                                Text(dateFormatter.string(from: Date(timeIntervalSince1970: Double(event.start_time) / 1000)))
                                    .foregroundStyle(Date().timeIntervalSince1970 * 1000 >= Double(event.end_time) ? .red : .primary)
                            }
                        }
                    })
                    .disabled(Date().timeIntervalSince1970 * 1000 >= Double(event.end_time))
                }
                .onDelete { indexSet in
                    lastDeletedIndex = Array(indexSet).max()
                    lastDeletedId = String(allEvents[lastDeletedIndex ?? 0].id)
                    lastDeletedName = String(allEvents[lastDeletedIndex ?? 0].title)
                    showConfirmDialog = true
                }
                Section {
                    Text("Account Management")
                }
            }
            .navigationTitle("Admin Panel")
            .alert(isPresented: $showConfirmDialog) {
                Alert(
                    title: Text("Delete Event \(self.lastDeletedName) (ID \(self.lastDeletedId))"),
                    message: Text(
                        "are you sure you would like to delete this event? this action is irreversible."),
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
                refreshAllEventsJson()
            }
            .refreshable {
                URLCache.shared.removeAllCachedResponses()
                refreshAllEventsJson()
            }
        }
    }
    
    func refreshAllEventsJson() {
        loadAllEventsJson { (output) in
            self.allEvents = output
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

func loadAllEventsJson(completionBlock: @escaping ([Event]) -> Void) {
    guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/events/all") else { return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.httpShouldHandleCookies = true
    
    let requestTask = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
        if let data = data {
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode([Event].self, from: data)
                DispatchQueue.main.async {
                    completionBlock(result.sorted { $0.start_time < $1.start_time })
                }
            } catch {
                print("parse error")
                completionBlock([])
            }
        } else if let error = error {
            print("fetch error: \(error)")
            completionBlock([])
        }
    }
    requestTask.resume()
}


#Preview {
    EventsView()
}
