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
    @State private var responseAttrStr: AttributedString?
    
    var body: some View {
        NavigationView {
            ScrollView {
                if answerStatus == 0 {
                    Text("Welcome to M-A's mental health resources chatbot! All questions are anonymous and are never saved.")
                    Spacer()
                    VStack {
                        if #available(iOS 16.0, *) {
                            TextField("Enter your question...", text: $promptText, axis: .vertical)
                                .onSubmit { askQuestion() }
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .lineLimit(1...10)
                                .padding()
                        } else {
                            TextField("Enter your question...", text: $promptText)
                                .onSubmit { askQuestion() }
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .padding()
                        }
                    }
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .padding()
                    Spacer()
                    Button(action: {
                        askQuestion()
                    }, label: {
                        Label("Continue", systemImage: "arrow.forward.circle.fill")
                            .labelStyle(.titleOnly)
                    })
                    .buttonStyle(.bordered)
                    .padding()
                } else {
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
                            if let responseAttrStr = responseAttrStr {
                                Text(responseAttrStr)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .padding()
                            } else {
                                Text(responseText)
                                    .frame(maxWidth: .infinity, alignment: .topLeading)
                                    .padding()
                            }
                        }
                    }
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(10)
                    .padding()
                    Spacer()
                    VStack {
                        Button(action: {
                            self.promptText = ""
                            self.responseText = ""
                            self.answerStatus = 0
                        }, label: {
                            Label("Ask a new question", systemImage: "questionmark")
                                .labelStyle(.titleOnly)
                        })
                        .buttonStyle(.bordered)
                        .padding()
                    }
                }
            }
            .navigationTitle("Chatbot")
        }
    }
    
    func askQuestion() {
        answerStatus = 1
        guard let url = URL(string: "https://macsvc.jayagra.com/api/chatgpt") else { return }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: ["prompt": promptText])
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpShouldHandleCookies = true
            request.httpBody = jsonData
            sharedSession.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(GptApiResponse.self, from: data)
                        DispatchQueue.main.async {
                            responseText = result.choices.first?.message.content.replacingOccurrences(of: "\n", with: "\n\n") ?? "The chatbot sent an invalid response, which may have been empty."
                            responseAttrStr = try? AttributedString(markdown: responseText)
                            answerStatus = 2
                        }
                    } catch {
                        responseText = "There was an error decoding the chatbot's response.\n\n\(error)"
                        answerStatus = 2
                    }
                } else {
                    responseText = "There was an error with the chatbot's response."
                    answerStatus = 2
                }
            }
            .resume()
        } catch {
            responseText = "There was an error encoding your response.\n\n\(error)"
            answerStatus = 2
        }
    }
}

#Preview {
    ChatbotView()
}

struct GptApiResponse: Codable {
    let choices: [GpiApiResponseChoice]
    let created: Int
    let id: String
    let model: String
    let system_fingerprint: String
    let usage: GptApiResponseUsage
}

struct GpiApiResponseChoice: Codable {
    let finish_reason: String
    let index: Int
    let logprobs: String?
    let message: GptApiResponseChoiceMessage
}

struct GptApiResponseChoiceMessage: Codable {
    let content: String
    let refusal: String?
    let role: String
}

struct GptApiResponseUsage: Codable {
    let completion_tokens: Int
    let completion_tokens_details: GptApiResponseUsageCompletion
    let prompt_tokens: Int
    let prompt_tokens_details: GptApiResponseUsagePrompt
    let total_tokens: Int
}

struct GptApiResponseUsageCompletion: Codable {
    let reasoning_tokens: Int
}

struct GptApiResponseUsagePrompt: Codable {
    let cached_tokens: Int
}
