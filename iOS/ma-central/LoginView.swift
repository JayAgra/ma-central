//
//  LoginView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 6/5/24.
//

import SwiftUI

struct LoginView: View {
    @State private var showAlert = false
    @State private var authData: [String] = ["", "", "", ""]
    @State private var alertMessage = ""
    @State private var loading = false
    @State private var create = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            Text("M-A Central")
                .font(.title)
            if !loading {
                if !create {
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
                        authAction(type: "login", data: ["username": authData[0], "password": authData[1]])
                    }
                    .padding()
                    .font(.title3)
                    .buttonStyle(.bordered)
                    Button("create") {
                        self.create = true
                    }
                    Button("continue as guest") {
                        appState.currentUser = [UserPoints(id: 0, username: "Guest", lifetime: 0, score: 0)]
                        appState.sessionOk = true
                    }
                    .padding()
                } else {
                    Text("create account")
                        .font(.title3)
                        .padding(.top)
                    TextField("student id", text: $authData[3])
                        .padding([.leading, .trailing])
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: authData[3]) { _ in
                            authData[3] = String(authData[3].prefix(6))
                        }
                    TextField("full name", text: $authData[2])
                        .padding([.leading, .trailing])
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.name)
                    TextField("username", text: $authData[0])
                        .padding([.leading, .trailing])
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .textContentType(.username)
                    SecureField("password", text: $authData[1])
                        .padding([.leading, .trailing])
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .textContentType(.newPassword)
                    Button("create") {
                        authAction(
                            type: "create",
                            data: [
                                "student_id": authData[3], "full_name": authData[2], "username": authData[0],
                                "password": authData[1],
                            ])
                    }
                    .padding()
                    .font(.title3)
                    .buttonStyle(.bordered)
                    Button("login") {
                        self.create = false
                    }
                    .padding(.bottom)
                    Text("Use of inappropriate usernames and/or inaccurate full names will result in administrative action and account deletion.")
                        .padding(.all)
                        .font(.caption)
                }
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
    
    private func authAction(type: String, data: [String: String]) {
        loading = true
        guard let url = URL(string: "https://macsvc.jayagra.com/api/v1/auth/\(type)") else { return }
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
                            appState.refreshUserJson()
                            appState.sessionOk = true
                            loading = false
                        } else {
                            loading = false
                            showAlert = true
                            if type == "login" {
                                alertMessage = "bad credentials"
                            } else {
                                if httpResponse.statusCode == 400 {
                                    alertMessage =
                                    "your username, full name, and/or password contained characters other than a-z 0-9 A-Z - ~ ! @ # $ % ^ & * ( ) = + / \\ _ [ _ ] { } | ? . ,"
                                } else if httpResponse.statusCode == 409 {
                                    alertMessage = "username taken"
                                } else if httpResponse.statusCode == 403 {
                                    alertMessage = "bad student id"
                                } else if httpResponse.statusCode == 413 {
                                    alertMessage =
                                    "your username, full name, and/or password were not between 3 and 64 characters (8 min for password)"
                                } else {
                                    alertMessage = "creation failed"
                                }
                            }
                        }
                    }
                } else {
                    loading = false
                    showAlert = true
                    alertMessage = "network error"
                }
            }.resume()
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
