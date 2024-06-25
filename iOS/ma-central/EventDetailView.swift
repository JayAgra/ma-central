//
//  EventDetailView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/12/24.
//

import SwiftUI

struct EventDetailView: View {
    var image: String
    var date: String
    var title: String
    var location: String
    var details: String
    
    var body: some View {
        VStack {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea(.container)
            VStack {
                Text(date)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                Text("\(location.uppercased())\n\n")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(details)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    
                }, label: {
                    Label("Sign Up", systemImage: "plus")
                })
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer()
        }
    }
}

#Preview {
    EventDetailView(image: "ImagePlaceholder", date: "Jan 1, 1970", title: "Event Title", location: "Event Location", details: "Details About Event")
}
