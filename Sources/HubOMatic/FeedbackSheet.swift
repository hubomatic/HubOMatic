//
//  File.swift
//  
//
//  Created by Michał Kasprzyk on 07/03/2021.
//

import SwiftUI
import Combine

struct Issue: Codable {
    let title: String
    let body: String?
    let milestone: String?
    let labels: [String]?
    let assignees: [String]?

    init(title: String, body: String? = nil, milestone: String? = nil, labels: [String]? = nil, assignees: [String]? = nil) {
        self.title = title
        self.body = body
        self.milestone = milestone
        self.labels = labels
        self.assignees = assignees
    }
}

class FeedbackViewModel {
    private var cancellables = Set<AnyCancellable>()

    private let session: URLSession
    private let token: String

    init(session: URLSession = .shared, token: String) {
        self.session = session
        self.token = token
    }
    
    func send(title: String, body: String) {
        let url = URL(string: "https://api.github.com/repos/kasprzykmichal/MicroVector/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let issue = Issue(title: title, body: body)
        request.httpBody = try? encoder.encode(issue)
        
        session
            .dataTaskPublisher(for: request)
            .tryMap { (element) -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return element.data
            }
            .sink { _ in
                print("COMPLETION")
            } receiveValue: { (data) in
                print("DATA")
            }
            .store(in: &cancellables)
    }
}

struct FeedbackSheet: View {
    @State var titleText: String = ""
    @State var bodyText: String = ""
    
    @Environment(\.presentationMode) var presentationMode

    private let viewModel: FeedbackViewModel

    init(viewModel: FeedbackViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Form {
            TextField("Title", text: $titleText)
            TextField("Body", text: $bodyText)
        }
        .toolbar {
            ToolbarItem(id: "Cancel", placement: .cancellationAction, showsByDefault: true) {
                Button("Cancel", action: self.cancelAction)
            }
            ToolbarItem(id: "Send", placement: .confirmationAction, showsByDefault: true) {
                Button("Send", action: self.sendAction)
            }
        }
        .padding()
        .frame(width: 600)
    }

    private func cancelAction() {
        self.presentationMode.wrappedValue.dismiss()
    }

    private func sendAction() {
        viewModel.send(title: titleText, body: bodyText)
        self.presentationMode.wrappedValue.dismiss()
    }
}
