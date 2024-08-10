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
    @State private var eventId: Int?
    @State private var ticketOk: Bool? = nil
    
    var body: some View {
        if eventId == nil {
            Button("Use 2 as an example event ID") {
                eventId = 2
            }
        } else {
            ZStack {
                ScannerView(scannedValue: $scannedValue, resetScan: $resetScan)
                    .edgesIgnoringSafeArea(.all)
                
                if scannedValue != nil {
                    if ticketOk == nil {
                        VStack {
                            Spacer()
                            Spacer()
                            Text("Validating ticket...")
                            ProgressView()
                            Spacer()
                            Button("Cancel") {
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
                        }
                    } else if ticketOk == true {
                        VStack {
                            Spacer()
                            Spacer()
                            Text("Ticket is valid")
                            Spacer()
                            Button("Continue") {
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
    }
    
    func consumeTicket(attendee_id: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/tickets_create/\(attendee_id)/\(String(eventId ?? 0))") else { return }
        
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
    ScanView()
}
