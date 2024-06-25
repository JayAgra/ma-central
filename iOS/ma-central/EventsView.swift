//
//  EventsView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/5/24.
//

import SwiftUI

struct EventsView: View {
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack {
                        ForEach(0...10, id: \.self) { id in
                            NavigationLink(destination: {
                                EventDetailView(image: "ImagePlaceholder", date: "Jan \(id + 1), 1970", title: "Event Number \(id)", location: "Event Location", details: "Event \(id) details")
                            }, label: {
                                CardView(image: "ImagePlaceholder", date: "Jan \(id + 1), 1970", title: "Event Number \(id)", location: "Event Location", dimensions: CGPoint(x: geometry.size.width * 0.9, y: geometry.size.width * 0.45))
                            })
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .navigationTitle("Events")
            }
        }
    }
}

#Preview {
    EventsView()
}
