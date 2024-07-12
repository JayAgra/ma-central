//
//  HomeViewMeCarousel.swift
//  ma-central
//
//  Created by Jayen Agrawal on 7/8/24.
//

import SwiftUI
import PassKit

struct HomeViewMeCarousel: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            ForEach(appState.userTickets, id: \.id) { ticket in
                CardView(image: "", date: String(ticket.id), title: "Ticket", location: String(ticket.creation_date), dimensions: CGPoint(x: 275, y: 325))
                    .onLongPressGesture {
                        addPass(passId: ticket.id)
                    }
            }
        }
        .onAppear() {
            appState.refreshUserTickets()
        }
    }
    
    func addPass(passId: Int) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/ticketing/pkpass/\(passId)") else {
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let error = error {
                print("Failed to download PKPass: \(error)")
                return
            }

            guard let localURL = localURL else {
                print("Failed to download PKPass: No local URL returned")
                return
            }

            do {
                let passData = try Data(contentsOf: localURL)
                let passController = PKAddPassesViewController(pass: try PKPass(data: passData))
                if let window = UIApplication.shared.windows.first {
                    window.rootViewController?.present(passController!, animated: true, completion: nil)
                }
            } catch {
                print("Failed to read PKPass file: \(error)")
            }
        }

        task.resume()
    }
}

#Preview {
    HomeViewMeCarousel()
}
