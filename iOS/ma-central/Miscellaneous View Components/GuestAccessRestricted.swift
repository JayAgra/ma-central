//
//  GuestAccessRestricted.swift
//  ma-central
//
//  Created by Jayen Agrawal on 7/10/24.
//

import SwiftUI

struct GuestAccessRestricted: View {
    let message: String
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(message)
                Spacer()
            }
        }
        .padding()
    }
}

#Preview {
    GuestAccessRestricted(message: "an account is required")
}
