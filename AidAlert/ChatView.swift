//
//  ChatView.swift
//  AidAlert
//
//  Created by Melvin Santos on 9/28/24.
//

import SwiftUI

struct ChatView: View {
    @Binding var searchText: String
    @Binding var chatResponses: [String]

    @State private var isSending = false

    var body: some View {
        VStack {
            // Chat messages displayed in a scrollable view
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(chatResponses.indices, id: \.self) { index in
                            Text(chatResponses[index])
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .id(index) // Assign an ID for scrolling
                        }
                    }
                    .padding(.top)
                }
                .onChange(of: chatResponses.count) { _ in
                    // Scroll to the latest message when a new one is added
                    withAnimation {
                        scrollViewProxy.scrollTo(chatResponses.count - 1, anchor: .bottom)
                    }
                }
            }

            // Input field at the bottom
            HStack {
                TextField("Type your message...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isSending) // Disable input while sending

                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.leading, 5)
                } else {
                    Button(action: {
                        submitQuery()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(45))
                    }
                    .disabled(searchText.isEmpty)
                    .padding(.leading, 5)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .edgesIgnoringSafeArea(.bottom)
    }

    private func submitQuery() {
        guard !searchText.isEmpty else { return }
        isSending = true
        let userMessage = searchText
        chatResponses.append("You: \(userMessage)")
        searchText = ""
        ChatService.shared.sendMessage(query: userMessage) { response in
            chatResponses.append("Assistant: \(response)")
            isSending = false
        }
    }
}

