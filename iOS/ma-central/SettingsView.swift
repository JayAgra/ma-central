//
//  SettingsView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/5/24.
//

import SwiftUI

struct SettingsView: View {
    @State private var showConfirm = false
    @State private var deletionData: (String, String) = ("", "")
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        Button("Clear Cache") {
                            URLCache.shared.removeAllCachedResponses()
                        }
                        Button("Log Out") {
                            if let cookies = HTTPCookieStorage.shared.cookies(
                                for: sharedSession.configuration.urlCache?.cachedResponse(
                                    for: URLRequest(url: URL(string: "https://macsvc.jayagra.com")!))?.response.url ?? URL(
                                        string: "https://macsvc.jayagra.com")!)
                            {
                                for cookie in cookies {
                                    sharedSession.configuration.httpCookieStorage?.deleteCookie(cookie)
                                }
                                appState.sessionOk = false
                            }
                        }
                        .foregroundColor(Color.pink)
                    }
                    Section {
                        Button("Delete Account") {
                            showConfirm = true
                        }
                        .foregroundStyle(Color.pink)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .alert(
            "Confirm Deletion", isPresented: $showConfirm,
            actions: {
                TextField("Username", text: $deletionData.0)
                SecureField("Password", text: $deletionData.1)
                Button(
                    "Cancel", role: .cancel,
                    action: {
                        showConfirm = false
                    })
                Button(
                    "Delete", role: .destructive,
                    action: {
                        deleteAccount(data: ["username": deletionData.0, "password": deletionData.1])
                        appState.sessionOk = false
                        showConfirm = false
                    })
            },
            message: {
                Text("this action is irreversable")
            })
    }
    
    private func deleteAccount(data: [String: String]) {
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/auth/delete") else { return }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.httpShouldHandleCookies = true
            sharedSession.dataTask(with: request) { data, response, error in
                if data != nil {
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    }
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }.resume()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

#Preview {
    SettingsView()
}
