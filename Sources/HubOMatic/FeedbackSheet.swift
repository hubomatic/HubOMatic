//
//  File.swift
//  
//
//  Created by Michał Kasprzyk on 07/03/2021.
//

import SwiftUI
import Combine
import AppKit

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

class FeedbackViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    private let session: URLSession
    private let token: String

    @Published var screenshot: NSImage?
    
    @Published var titleText: String = ""
    @Published var bodyText: String = ""
    @Published var emailText: String = ""
    
    @Published var includeScreenshot: Bool = true
    @Published var includeDocument: Bool = true
    @Published var includeEmail: Bool = true

    init(session: URLSession = .shared, token: String) {
        self.session = session
        self.token = token
    
        self.screenshot = NSApplication.shared.keyWindow?.takeSnapshot()
    }
    
    func send() {
        let url = URL(string: "https://api.github.com/repos/kasprzykmichal/MicroVector/issues")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.addValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let issue = Issue(title: titleText, body: bodyText)
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
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: FeedbackViewModel

    init(viewModel: FeedbackViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Form {
            titleItem()
            bodyItem()
            screenshotItem()
            documentItem()
            emailItem()
            privacyItem()
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

    private func titleItem() -> some View {
        feedbackItem(number: Image(systemName: "01.circle.fill"), title: Text("Issue Title")) {
            TextField("Negative Feedback", text: $viewModel.titleText)
        }
    }

    private func bodyItem() -> some View {
        feedbackItem(number: Image(systemName: "02.circle.fill"), title: Text("Issue Body")) {
            TextEditor(text: $viewModel.bodyText)
                .font(Font.body.monospacedDigit())
                .frame(height: 150)
        }
    }

    private func screenshotItem() -> some View {
        feedbackItem(number: Image(systemName: "03.circle.fill"), title: Toggle("Include screenshot", isOn: $viewModel.includeScreenshot)) {
            GroupBox {
                self.viewModel.screenshot.flatMap { (image) in
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(viewModel.includeScreenshot ? 1.0 : 0.4)
                        .padding()
                }
            }
            .frame(height: 250)
        }
    }

    private func documentItem() -> some View {
        feedbackItem(number: Image(systemName: "04.circle.fill"), title: Toggle("Include document", isOn: $viewModel.includeScreenshot)) {
            GroupBox {
                Text("Drop file here")
            }
            .frame(height: 250)
        }
    }

    private func emailItem() -> some View {
        feedbackItem(number: Image(systemName: "05.circle.fill"), title: Toggle("Include email", isOn: $viewModel.includeEmail)) {
            TextField("Email address", text: $viewModel.emailText)
        }
    }

    private func privacyItem() -> some View {
        VStack(alignment: .center) {
            Spacer()
            Divider()
            Spacer()
            Text("We'll only send this data when you have an internet connection. We may not be able to respond to you personally, but we do review every comment.")
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Link("Privacy Statement >", destination: URL(string: "https://google.com")!)
        }
    }

    private func feedbackItem<N: View, T: View, C: View>(number: N, title: T, @ViewBuilder content: () -> C) -> some View {
        HStack {
            number
            VStack(alignment: .leading, spacing: nil) {
                title
                    .alignmentGuide(VerticalAlignment.topViewCenter) { d in
                        d[VerticalAlignment.center]
                    }
                content()
            }
            .alignmentGuide(VerticalAlignment.center) { d in
                d[VerticalAlignment.topViewCenter]
            }
        }
    }

    private func cancelAction() {
        self.presentationMode.wrappedValue.dismiss()
    }

    private func sendAction() {
        viewModel.send()
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct FeedbackSheetPreview: PreviewProvider {
    static var previews: some View {
        let viewModel = FeedbackViewModel(token: "")
        FeedbackSheet(viewModel: viewModel)
    }
}

extension NSWindow {
    func takeSnapshot() -> NSImage? {
        guard windowNumber != -1, let cgImage = CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(windowNumber), []) else { return nil }

        return NSImage(cgImage: cgImage, size: frame.size)
    }
}

extension VerticalAlignment {
    static let topViewCenter = VerticalAlignment(TopViewCenter.self)
    private enum TopViewCenter: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat { d[VerticalAlignment.firstTextBaseline] }
    }
}

