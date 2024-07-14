//
//  LoginView.swift
//  ma-central-admin
//
//  Created by Jayen Agrawal on 7/14/24.
//

import SwiftUI

struct LoginView: View {
    @State private var showAlert = false
    @State private var authData: [String] = ["", "", "", ""]
    @State private var alertMessage = ""
    @State private var loading = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Text("M-A Central")
                .font(.title)
            if !loading {
                    Text("log in")
                        .font(.title3)
                        .padding(.top)
                    TextField("username", text: $authData[0])
                        .padding([.leading, .trailing, .bottom])
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .textContentType(.username)
                    SecureField("password", text: $authData[1])
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .textContentType(.password)
                    Button("login") {
                        authAction(data: ["username": authData[0], "password": authData[1]])
                    }
                    .padding()
                    .font(.title3)
                    .buttonStyle(.bordered)
            } else {
                Spacer()
                ProgressView()
                    .controlSize(.large)
                    .padding()
                Spacer()
            }
        }
        .padding()
        .alert(
            isPresented: $showAlert,
            content: {
                Alert(
                    title: Text("Auth Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("ok"))
                )
            })
    }
    
    private func authAction(data: [String: String]) {
        loading = true
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/auth/login/admin") else { return }
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
                            appState.sessionOk = true
                            loading = false
                        } else {
                            loading = false
                            showAlert = true
                            alertMessage = "bad credentials, or you do not have administrator access"
                        }
                    }
                } else {
                    loading = false
                    showAlert = true
                    alertMessage = "network error"
                }
            }
            .resume()
        } catch {
            loading = false
            showAlert = true
            alertMessage = "failed to serialize auth object"
        }
    }
}

#Preview {
    LoginView()
}
