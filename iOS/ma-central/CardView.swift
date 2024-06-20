//
//  CardView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/11/24.
//

import SwiftUI

struct CardView: View {
    var image: String
    var date: String
    var title: String
    var location: String
    var dimensions: CGPoint
    
    var body: some View {
        if dimensions.x > dimensions.y {
            ZStack {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                    .frame(width: dimensions.x, height: dimensions.y)
                    .padding()
                VStack(alignment: .leading) {
                    Text(date)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .shadow(color: .black, radius: 4, x: 0, y: 2)
                    Text(title)
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .shadow(color: .black, radius: 4, x: 0, y: 2)
                    Text(location.uppercased())
                        .font(.caption)
                        .foregroundColor(.primary)
                        .shadow(color: .black, radius: 4, x: 0, y: 2)
                }
                .frame(width: dimensions.x, height: dimensions.y, alignment: .leading)
                .padding(.leading, dimensions.x * 0.1)
            }
        } else {
            VStack {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                HStack {
                    VStack(alignment: .leading) {
                        Text(date)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(title)
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                        Text(location.uppercased())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .layoutPriority(100)
                    Spacer()
                }
                .padding()
            }
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray)
            )
            .padding(.horizontal)
            .frame(width: dimensions.x, height: dimensions.y)
        }
    }
}

#Preview {
    CardView(image: "ImagePlaceholder", date: "Jan 1, 1970", title: "Event Title", location: "Event Location", dimensions: CGPoint(x: 325, y: 275))
}
