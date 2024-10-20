//
//  ChatbotView.swift
//  ma-central
//
//  Created by Jayen Agrawal on 10/20/24.
//

import SwiftUI

struct ChatbotView: View {
    @EnvironmentObject var appState: AppState
    @State private var answerStatus: Int = 0 // 0 = no question, 1 = awaiting response, 2 = answered
    @State private var promptText = ""
    @State private var responseText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if answerStatus == 0 {
                    Text("Welcome to M-A's mental health resources chatbot! Enter your question below, and we'll do our best to help you find the right resources. All questions are anonymous and are never stored")
                } else {
                    VStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            Text(promptText)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding()
                        }
                        .background(Color.gray.opacity(0.25))
                        .cornerRadius(10)
                        .padding()
                        VStack {
                            if answerStatus == 1 {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                Text("")
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .padding()
                            }
                        }
                        .background(Color.accentColor.opacity(0.075))
                        .cornerRadius(10)
                        .padding()
                        Spacer()
                        VStack {
                            Button(action: {
                                self.answerStatus = 0
                            }, label: {
                                Label("Ask a new question", systemImage: "questionmark")
                                    .labelStyle(.titleOnly)
                            })
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .navigationTitle("Resources Chatbot")
        }
    }
}

#Preview {
    ChatbotView()
}
