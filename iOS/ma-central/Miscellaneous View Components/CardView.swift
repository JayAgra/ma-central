//
//  CardView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/11/24.
//

import SwiftUI
import Kingfisher

struct CardView: View {
    var image: String
    var date: String
    var title: String
    var location: String
    var dimensions: CGPoint
    var humanDate: String
    
    init(image: String, date: String, title: String, location: String, dimensions: CGPoint) {
        self.image = image
        self.date = date
        self.title = title
        self.location = location
        self.dimensions = dimensions
        
        if let unixTimestampMillis = Double(date) {
            let unixTimestampSeconds = unixTimestampMillis / 1000
            let date = Date(timeIntervalSince1970: unixTimestampSeconds)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            dateFormatter.locale = Locale.current
            humanDate = dateFormatter.string(from: date)
        } else {
            humanDate = "Date Conversion Failure"
        }
    }
    
    var body: some View {
        if dimensions.x > dimensions.y {
            ZStack {
                KFImage(URL(string: image == "" ? "https://jayagra.com/static-ish/IMG_6901.png?v=101" : image)!)
                    .alternativeSources([.network(URL(string: "https://jayagra.com/static-ish/IMG_6901.png?v=101")!)])
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(10)
                    .frame(width: dimensions.x, height: dimensions.y)
                    .padding()
                VStack(alignment: .leading) {
                    Text(humanDate)
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .secondary, radius: 4, x: 0, y: 2)
                    Text(title)
                        .font(.title)
                        .fontWeight(.black)
                        .lineLimit(3)
                        .foregroundColor(.white)
                        .shadow(color: .secondary, radius: 4, x: 0, y: 2)
                    Text(location.uppercased())
                        .font(.caption)
                        .foregroundColor(.white)
                        .shadow(color: .secondary, radius: 4, x: 0, y: 2)
                }
                .frame(width: dimensions.x, height: dimensions.y, alignment: .leading)
                .padding(.leading, dimensions.x * 0.1)
            }
        } else {
            VStack {
                KFImage(URL(string: image == "" ? "https://jayagra.com/static-ish/IMG_6901.png?v=101" : image)!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                HStack {
                    VStack(alignment: .leading) {
                        Text(humanDate)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(title)
                            .font(.title)
                            .fontWeight(.black)
                            .lineLimit(3)
                            .foregroundColor(.white)
                        Text(location.uppercased())
                            .font(.caption)
                            .foregroundColor(.white)
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
