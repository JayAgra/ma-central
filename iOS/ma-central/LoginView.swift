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
        GeometryReader { geo in
            ZStack {
                Image("ImagePlaceholder")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    .scaledToFill()
                    .blur(radius: 10)
                    .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("M-A Central")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    if !loading {
                        Picker("Log In/Create Account", selection: $create) {
                            Text("Log In").tag(false)
                            Text("Create Account").tag(true)
                        }
                        .pickerStyle(.segmented)
                        Spacer()
                        if !create {
                            LoginTextField(text: $authData[0], placeholder: "Username")
                                .textContentType(.username)
                            LoginTextFieldSecure(text: $authData[1], placeholder: "Password")
                                .textContentType(.password)
                            Button("Log In") {
                                authAction(type: "login", data: ["username": authData[0], "password": authData[1]])
                            }
                            .padding()
                            .font(.title3)
                            .buttonStyle(.bordered)
                            Button("Continue As Guest") {
                                appState.currentUser = [UserPoints(id: 0, username: "Guest", lifetime: 0, score: 0)]
                                appState.sessionOk = true
                            }
                            .padding(.horizontal)
                        } else {
                            LoginTextField(text: $authData[3], placeholder: "Student ID")
                                .keyboardType(.numberPad)
                                .onChange(of: authData[3]) { _ in
                                    authData[3] = String(authData[3].prefix(6))
                                }
                            LoginTextField(text: $authData[2], placeholder: "Full Name")
                                .textContentType(.name)
                            LoginTextField(text: $authData[0], placeholder: "Username")
                                .textContentType(.username)
                            LoginTextFieldSecure(text: $authData[1], placeholder: "Password")
                                .textContentType(.newPassword)
                            Button("Create") {
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
                        }
                        Spacer()
                        Text("Use of inappropriate usernames and/or inaccurate full names will result in administrative action and account deletion. Contact dev@jayagra.com for login help.")
                            .padding()
                            .font(.caption)
                    } else {
                        Spacer()
                        ProgressView()
                            .controlSize(.large)
                            .padding()
                        Spacer()
                    }
                }
                .padding()
                .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
            }
        }
        .alert(
            isPresented: $showAlert,
            content: {
                Alert(
                    title: Text("Auth Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("ok"))
                )
            })
        .environment(\.colorScheme, .dark)
    }
    
    struct LoginTextField: View {
        @Binding var text: String
        var placeholder: String
        
        var body: some View {
            TextField(placeholder, text: $text)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.black.opacity(0.5))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .frame(maxWidth: .infinity)
                .environment(\.colorScheme, .dark)
        }
    }
    
    struct LoginTextFieldSecure: View {
        @Binding var text: String
        var placeholder: String
        
        var body: some View {
            SecureField(placeholder, text: $text)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.black.opacity(0.5))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.1), lineWidth: 1))
                )
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .frame(maxWidth: .infinity)
                .environment(\.colorScheme, .dark)
        }
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
                            if type == "login" {
                                appState.sessionOk = true
                                loading = false
                            } else {
                                authAction(type: "login", data: ["username": authData[0], "password": authData[1]])
                            }
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
                                } else if httpResponse.statusCode == 451 {
                                    alertMessage = "an account already exists for the supplied student id. to delete your old account, send an email to dev@jayagra.com."
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
    LoginView().preferredColorScheme(.dark)
}
