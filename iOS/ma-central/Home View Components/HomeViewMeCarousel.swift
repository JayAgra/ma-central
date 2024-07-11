//
//  HomeViewMeCarousel.swift
//  ma-central
//
//  Created by Jayen Agrawal on 7/8/24.
//

import SwiftUI

struct HomeViewMeCarousel: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            ForEach(appState.userTickets, id: \.id) { ticket in
                CardView(image: "", date: String(ticket.id), title: "Ticket", location: String(ticket.creation_date), dimensions: CGPoint(x: 275, y: 325))
            }
            if appState.userTickets.isEmpty {
                Text("You have no tickets.")
            }
        }
        .onAppear() {
            appState.refreshUserTickets()
        }
    }
}

#Preview {
    HomeViewMeCarousel()
}
