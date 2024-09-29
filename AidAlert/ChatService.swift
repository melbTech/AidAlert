//
//  ChatService.swift
//  AidAlert
//
//  Created by Melvin Santos on 9/28/24.
//

import Foundation

class ChatService {
    static let shared = ChatService()
    private let apiKey: String
    private let session = URLSession.shared
    private let urlString = "https://api.openai.com/v1/chat/completions"

    private init() {
        // Load API key from Secrets.plist
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = dict["OPENAI_API_KEY"] as? String {
            self.apiKey = key
        } else {
            fatalError("API Key not found")
        }
    }

    func sendMessage(query: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: urlString) else {
            completion("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let messages: [[String: String]] = [
            ["role": "user", "content": query]
        ]

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "max_tokens": 150
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion("Error serializing JSON: \(error.localizedDescription)")
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            // Handle errors
            if let error = error {
                DispatchQueue.main.async {
                    completion("Error: \(error.localizedDescription)")
                }
                return
            }

            // Check HTTP status code
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion("Invalid response")
                }
                return
            }

            guard httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    completion("HTTP Error: \(httpResponse.statusCode)")
                }
                return
            }

            // Parse the response
            guard let data = data else {
                DispatchQueue.main.async {
                    completion("No data received")
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                let chatResponse = try decoder.decode(ChatResponse.self, from: data)
                if let content = chatResponse.choices.first?.message.content {
                    DispatchQueue.main.async {
                        completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion("Failed to get content from response")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion("Error parsing response: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }
}

// Define the response models
struct ChatResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let role: String
    let content: String
}

