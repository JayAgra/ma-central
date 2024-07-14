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
    @State private var eventId: Int?
    @State private var ticketOk: Bool?
    
    var body: some View {
        if eventId == nil {
            Button("Use 1 as an example event ID") {
                eventId = 1
            }
        } else {
            ZStack {
                ScannerView(scannedValue: $scannedValue)
                    .edgesIgnoringSafeArea(.all)
                
                if scannedValue != nil {
                    if ticketOk == nil {
                        VStack {
                            Spacer()
                            Text("Validating ticket...")
                            ProgressView()
                            Spacer()
                            Spacer()
                            Button("Cancel") {
                                scannedValue = nil
                            }
                            Spacer()
                        }
                        .edgesIgnoringSafeArea(.all)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    } else if ticketOk == true {
                        VStack {
                            Spacer()
                            Text("Ticket is valid")
                            Spacer()
                            Spacer()
                            Button("Continue") {
                                scannedValue = nil
                            }
                            Spacer()
                        }
                        .edgesIgnoringSafeArea(.all)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green)
                        .onAppear() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                scannedValue = nil
                            }
                        }
                    } else {
                        VStack {
                            Spacer()
                            Text("Ticket invalid")
                            Spacer()
                            Spacer()
                            Button("Continue") {
                                scannedValue = nil
                            }
                            Spacer()
                        }
                        .edgesIgnoringSafeArea(.all)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.red)
                    }
                }
            }
        }
    }
    
    func consumeTicket(ticket: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/admin/consume_ticket/\(String(eventId ?? 0))/\(ticket)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        let requestTask: Void = sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
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
        consumeTicket(ticket: ticket) { (success) in
            ticketOk = true
        }
    }
}

#Preview {
    ScanView()
}
