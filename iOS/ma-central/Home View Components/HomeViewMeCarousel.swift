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
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            ForEach(appState.userTickets, id: \.id) { ticket in
                VStack {
                    HStack {
                        VStack {
                            Text(String(ticket.id))
                                .font(.headline)
                                .foregroundColor(.secondary)
                            ZStack {
                                AddToWalletButton(isLoading: $isLoading, passId: ticket.id)
                                    .frame(width: 200, height: 50)
                                if isLoading {
                                    ProgressView()
                                        .padding(.top)
                                }
                            }
                        }
                        .layoutPriority(100)
                        Spacer()
                    }
                    .padding()
                }
                .padding(.horizontal)
                .frame(width: 275, height: 100)
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
