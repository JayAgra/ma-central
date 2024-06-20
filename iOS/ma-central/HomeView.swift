//
//  ContentView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 5/28/24.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    Text("Jayen")
                        .font(.title)
                    HStack {
                        Text("129")
                            .font(.title2)
                        Text("points")
                        Spacer()
                        Text("fancy points bar here")
                    }
                    .padding()
                }
                .padding()
                VStack(alignment: .leading) {
                    Text("Upcoming Events")
                        .font(.title2)
                        .padding(.leading)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(0...3, id: \.self) { id in
                                CardView(image: "ImagePlaceholder", date: "Jan \(id + 1), 1970", title: "Event Number \(id)", location: "Event Location", dimensions: CGPoint(x: 275, y: 325))
                            }
                        }
                    }
                    .background(Color.secondary.opacity(0.1))
                }
                .padding(.vertical)
                VStack(alignment: .leading) {
                    Text("Your Events")
                        .font(.title2)
                        .padding(.leading)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(0...2, id: \.self) { id in
                                CardView(image: "ImagePlaceholder", date: "Jan \(id + 1), 1970", title: "Event Number \(id)", location: "Event Location", dimensions: CGPoint(x: 275, y: 325))
                            }
                        }
                    }
                    .background(Color.secondary.opacity(0.1))
                }
                .padding(.vertical)
            }
        }
    }
}

#Preview {
    HomeView()
}
