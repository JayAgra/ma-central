//
//  ScanView.swift
//  ma-central-admin
//
//  Created by Jayen Agrawal on 7/14/24.
//

import SwiftUI

struct ScanView: View {
    @State private var showOverlay = false
    
    var body: some View {
        ZStack {
            ScannerView()
                .edgesIgnoringSafeArea(.all)
            
            if showOverlay {
                
            }
        }
    }
}

#Preview {
    ScanView()
}
