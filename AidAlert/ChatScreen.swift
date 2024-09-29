//
//  ChatScreen.swift
//  AidAlert
//
//  Created by Melvin Santos on 9/28/24.
//

import SwiftUI
import Combine

struct ChatScreen: View {
    @State private var searchText = ""
    @State private var chatResponses = [String]()
    @State private var selectedExpertise: String?

    @ObservedObject private var keyboard = KeyboardResponder()

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar with Title and Location
            VStack {
                Text("AidAlert")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Miami, FL")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()

            // Shortcut Icons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ExpertiseButton(
                        iconName: "drop.fill",
                        label: "Flood",
                        expertise: "Flood",
                        color: Color.blue,
                        selectedExpertise: $selectedExpertise,
                        chatResponses: $chatResponses
                    )
                    ExpertiseButton(
                        iconName: "tropicalstorm",
                        label: "Hurricane",
                        expertise: "Hurricane",
                        color: Color.orange,
                        selectedExpertise: $selectedExpertise,
                        chatResponses: $chatResponses
                    )
                    ExpertiseButton(
                        iconName: "tornado",
                        label: "Tornado",
                        expertise: "Tornado",
                        color: Color.gray,
                        selectedExpertise: $selectedExpertise,
                        chatResponses: $chatResponses
                    )
                    ExpertiseButton(
                        iconName: "flame.fill",
                        label: "Wildfire",
                        expertise: "Wildfire",
                        color: Color.red,
                        selectedExpertise: $selectedExpertise,
                        chatResponses: $chatResponses
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom)

            // Chat Responses
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(chatResponses.indices, id: \.self) { index in
                            Text(chatResponses[index])
                                .padding()
                                .background(chatResponses[index].starts(with: "You:") ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .id(index)
                        }
                    }
                    .padding(.top)
                }
                .onChange(of: chatResponses.count) { _ in
                    withAnimation {
                        scrollViewProxy.scrollTo(chatResponses.count - 1, anchor: .bottom)
                    }
                }
            }
        }
        .padding(.bottom, keyboard.currentHeight)
        .animation(.easeOut(duration: 0.16))
        .safeAreaInset(edge: .bottom) {
            // Search Bar
            HStack {
                TextField("Ask something...", text: $searchText)
                    .padding(.leading)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)

                Button(action: {
                    submitQuery()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(45))
                }
                .disabled(searchText.isEmpty)
                .padding(.trailing)
            }
            .background(Color(.systemBackground))
            .cornerRadius(10, corners: [.topLeft, .topRight])
            .overlay(
                // Thinner and lighter top border
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.4)),
                alignment: .top
            )
            .frame(maxWidth: .infinity)
            .edgesIgnoringSafeArea(.horizontal)
        }
    }

    private func submitQuery() {
        guard !searchText.isEmpty else { return }
        let userMessage = searchText
        chatResponses.append("You: \(userMessage)")
        searchText = ""

        // Include expertise in the query if selected
        let query: String
        if let expertise = selectedExpertise {
            query = "As an expert in \(expertise), \(userMessage)"
        } else {
            query = userMessage
        }

        ChatService.shared.sendMessage(query: query) { response in
            chatResponses.append("Assistant: \(response)")
        }
    }
}

struct ExpertiseButton: View {
    let iconName: String
    let label: String
    let expertise: String
    let color: Color
    @Binding var selectedExpertise: String?
    @Binding var chatResponses: [String]

    var body: some View {
        Button(action: {
            if selectedExpertise != expertise {
                // Expertise has changed
                selectedExpertise = expertise
                // Clear chat responses
                chatResponses.removeAll()
                // Generate assistant response
                let response = "I am a \(expertise.lowercased()) expert. How can I assist you?"
                chatResponses.append("Assistant: \(response)")
            }
        }) {
            VStack {
                Image(systemName: iconName)
                    .font(.title)
                    .foregroundColor(color) // Solid color for icon
                Text(label)
                    .font(.caption)
                    .foregroundColor(color) // Solid color for label
            }
            .padding()
            .background(
                selectedExpertise == expertise ?
                color.opacity(0.2) : // Slightly darker when selected
                color.opacity(0.1)   // Background with opacity 0.1
            )
            .cornerRadius(10)
        }
    }
}

// Custom corner radius modifier
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize( width: radius, height: radius )
        )
        return Path(path.cgPath)
    }
}

// Keyboard handling
final class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    private var cancellable: AnyCancellable?

    init() {
        let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    return frame.height - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)
                }
                return 0
            }

        let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }

        cancellable = Publishers.Merge(keyboardWillShow, keyboardWillHide)
            .assign(to: \.currentHeight, on: self)
    }

    deinit {
        cancellable?.cancel()
    }
}

