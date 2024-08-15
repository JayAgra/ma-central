//
//  ManageOptions.swift
//  ma-central
//
//  Created by Jayen Agrawal on 8/14/24.
//

import SwiftUI

struct ManageOptions: View {
    @State private var isAdmin: Bool? = nil
    
    var body: some View {
        if isAdmin == nil {
            VStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .onAppear {
                checkAdminStatus { result in
                    self.isAdmin = result
                }
            }
        } else {
            if !(isAdmin ?? false) {
                VStack {
                    Spacer()
                    Text("There are no more options for your account at this time. Please email dev@jayagra.com for assistance with account related questions.")
                        .padding()
                    Spacer()
                }
                .onAppear {
                    checkAdminStatus { result in
                        self.isAdmin = result
                    }
                }
            } else {
                EventsView()
            }
        }
    }
    
    func checkAdminStatus(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/auth/admin") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = sharedSession.dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
        task.resume()
    }
}

#Preview {
    ManageOptions()
}
