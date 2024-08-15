//
//  ScanView.swift
//  ma-central-admin
//
//  Created by Jayen Agrawal on 7/14/24.
//

import SwiftUI

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    @State private var scannedValue: String?
    @State private var resetScan: Bool = true
    var eventId: Int
    var eventTitle: String
    @State private var ticketOk: Bool? = nil
    
    init(eventId: Int, eventTitle: String) {
        self.eventId = eventId
        self.eventTitle = eventTitle
    }
    
    var body: some View {
        ZStack {
            ScannerView(scannedValue: $scannedValue, resetScan: $resetScan)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Scanning for \(eventTitle)")
                Spacer()
            }
            
            if scannedValue != nil {
                if ticketOk == nil {
                    VStack {
                        Spacer()
                        Spacer()
                        Text("Validating ticket...")
                        ProgressView()
                        Spacer()
                        Button("Cancel") {
                            scannedValue = nil
                            resetScan = true
                            ticketOk = nil
                        }
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .onAppear() {
                        runTicket(ticket: scannedValue ?? "")
                        scannedValue = nil
                    }
                } else if ticketOk == true {
                    VStack {
                        Spacer()
                        Spacer()
                        Text("Ticket is valid")
                        Spacer()
                        Button("Continue") {
                            scannedValue = nil
                            resetScan = true
                            ticketOk = nil
                        }
                        .foregroundColor(Color.white)
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.green)
                    .onAppear() {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            scannedValue = nil
                            resetScan = true
                            ticketOk = nil
                        }
                    }
                } else {
                    VStack {
                        Spacer()
                        Spacer()
                        Text("Ticket invalid")
                        Spacer()
                        Button("Continue") {
                            scannedValue = nil
                            resetScan = true
                            ticketOk = nil
                        }
                        .foregroundColor(Color.white)
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.red)
                    .onAppear() {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                }
            }
        }
    }
    
    func consumeTicket(attendee_id: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/tickets_create/\(attendee_id)/\(String(eventId))") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        let _: Void = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
        .resume()
    }
    
    func runTicket(ticket: String) {
        consumeTicket(attendee_id: ticket) { (success) in
            ticketOk = success
        }
    }
}

#Preview {
    ScanView(eventId: 1, eventTitle: "Test")
}
