//
//  LoadingDataView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 7/10/24.
//

import SwiftUI

struct LoadingDataView: View {
    let message: String
    
    var body: some View {
        VStack {
            HStack {
                Text(message)
                    .padding(.leading)
                Spacer()
                ProgressView()
                    .padding(.trailing)
            }
        }
        .padding()
    }
}

#Preview {
    LoadingDataView(message: "loading account data...")
}
