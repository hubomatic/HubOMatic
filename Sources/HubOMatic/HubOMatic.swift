//
//  HubOMatic.swift
//  MicroVector
//
//  Created by Marc Prud'hommeaux on 2/12/21.
//

import Foundation
import Combine
import SwiftUI
import Sparkle
import OSLog

/// The central manager for checking for app updates and providing UI components for configuring and controlling the update process.
public final class HubOMatic : ObservableObject {
    public let log = Logger(subsystem: "HubOMatic", category: "HubOMatic")

    public let config: Config
    private var subscribers = Set<AnyCancellable>()
    private let updater = SUUpdater.shared()!

    @State private var feedbackSheetPresented: Bool = false

    /// The configuration for a HubOMatic App. Provides default conventions for deployment platforms such as GitHub.
    public struct Config : Hashable, Codable {
        public var releasesURL: URL
        public var versionInfo: URL
        public var versionInfoLocal: URL?
        public var relativeArtifact: String
        public var token: String

        /// Creates a Hub-O-Matic™ config following a convention for a GitHub (or GitHub-compatible) organization and repository with the default naming convention.
        /// If no arguments are specified, the `Bundle.main.bundleIdentifier` is checked and the last two sections are used for the organization and repository names respectively. For example, the bundle named "com.mycompany.mydepartment.awesomeapps.AwesomeApp" will use "awesomeapps" as the org and "AwesomeApp" as the repository. The behavior for an invalid bundle identifier (a string that is not a dot-separated reverse-domain) is undefined.
        ///
        /// "https://github.com/hubomatic/MicroVector/releases/latest/download/appcast.xml"
        /// - Parameters:
        ///   - orgName: the name of the organization, defaulting to the penultimate component of `Bundle.main.bundleIdentifier`
        ///   - repoName: the name of the repository, defaulting to the final component of `Bundle.main.bundleIdentifier`
        ///   - update: the update endpoint, defaulting to "appcast.xml"
        ///   - archive: the name of the archive, defaulting to "`repoName`.zip"
        ///   - latest: the base URL for the latest release, defaulting to "latest"
        ///   - host: the root URL for the host, defaulting to "https://github.com"
        ///
        /// - Returns: a `HubOMatic.Config` to be used to initialize a HubOMatic
        public static func github(org orgName: String? = nil, repo repoName: String? = nil, update: String = "appcast.xml", archive: String? = nil, latest: String = "latest", host hostURL: URL = URL(string: "https://github.com")!, token: String) -> Self {

            let mainBundle = Bundle.main.bundleIdentifier
            let repo = repoName ?? mainBundle?.split(separator: ".").last?.description ?? "RepoName"
            let org = orgName ?? mainBundle?.split(separator: ".").dropLast().last?.description ?? "orgname"
            let orgURL = hostURL.appendingPathComponent(org)
            let repoURL = orgURL.appendingPathComponent(repo)
            let releasesURL = repoURL.appendingPathComponent("releases")
            let latestURL = releasesURL.appendingPathComponent(latest)
            let downloadDir = latestURL.appendingPathComponent("download")
            let updatePath = downloadDir.appendingPathComponent(update)

            let config = Config(releasesURL: releasesURL, versionInfo: updatePath, versionInfoLocal: Bundle.main.url(forResource: update, withExtension: nil), relativeArtifact: archive ?? repo + ".zip", token: token)

            return config
        }
    }

    deinit {
        subscribers.removeAll()
    }

    private init(config: Config) {
        self.config = config
    }
}

public extension Bundle {
    /// Returns the `kCFBundleVersionKey` from the dictionary, which corresponds to the build number
    var buildVersionString: String? { object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String }

    /// Returns the `CFBundleShortVersionString` from the dictionary
    var shortVersionString: String? { object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String }
}

public extension HubOMatic {
    /// The URL for downloading the artifact
    var artifactURL: URL {
        config.versionInfo
            .deletingLastPathComponent()
            .appendingPathComponent(config.relativeArtifact)
    }

    /// Initialized any necessary properties for performing update checking
    func setup() {
        UserDefaults.standard.set(config.versionInfo.absoluteString, forKey: "SUFeedURL")
    }

    /// Returns whether update checking is possible with the current bundle
    var canPerformUpdateCheck: Bool {
        Bundle.main.buildVersionString != nil
    }

    /// Initialized, but does not start, a `HubOMatic` with the given config. To start the update check scheduing, call `start`.
    ///
    /// Example usage:
    /// ```
    /// struct AutoUpdatingApp: App {
    ///     @StateObject var hub = HubOMatic.create(.github()).start()
    ///
    ///     @SceneBuilder var body: some Scene {
    ///         DocumentGroup(newDocument: MyDocument()) { file in
    ///             ContentView(document: file.$document)
    ///                 .toolbar { hub.toolbarButton() }
    ///         }
    ///         .withHubOMatic(hub)
    ///     }
    /// }
    /// ```
    static func create(_ config: Config) -> Self {
        Self(config: config)
    }

    /// Start the app, scheduling an update check for users who have opted-in to checking.
    @discardableResult func start() -> Self {
        self.setup()
        self.checkForUpdate(background: true)
        return self
    }

    /// Action for checking for an update. Meant to be used like:
    /// ```
    /// @StateObject var hub = HubOMatic.create(.github())
    /// var body: some View {
    ///     Button(LocalizedStringKey("Check for Update"), action: hub.checkForUpdateAction)
    /// }
    /// ```
    func checkForUpdateAction() {
        checkForUpdate(background: false)
    }

    /// Button for checking for an update. Meant to be used like:
    /// ```
    /// @StateObject var hub = HubOMatic.create(.github())
    /// var body: some View {
    ///     hub.checkForUpdateButton()
    /// }
    /// ```
    func checkForUpdateButton(title: LocalizedStringKey = LocalizedStringKey("Check for Updates")) -> some View {
        Button(title, action: checkForUpdateAction).disabled(!canPerformUpdateCheck)
    }

    /// Button for feedback screen. Meant to be used like:
    /// ```
    /// @StateObject var hub = HubOMatic.create(.github())
    /// var body: some View {
    ///     hub.feedbackButton()
    /// }
    /// ```
    func feedbackButton(isPresented: Binding<Bool>, title: LocalizedStringKey = LocalizedStringKey("Feedback")) -> some View {
        Button(title, action: {
            isPresented.wrappedValue.toggle()
        })
        .sheet(isPresented: isPresented, content: {
            let viewModel = FeedbackViewModel(token: self.config.token)
            FeedbackSheet(viewModel: viewModel)
        })
    }

    /// Initiates an update check either in the foreground or background
    @discardableResult func checkForUpdate(background: Bool) -> Bool {
        if !canPerformUpdateCheck {
            log.info("cannot check for updates due to HubOMatic.canPerformUpdateCheck failure")
            return false
        }

        if background {
            updater.checkForUpdatesInBackground()
        } else {
            updater.checkForUpdates(nil)
        }
        return true
    }
}

/// Commands for Hub-O-Matic
public struct HubOMaticUpdateCommands : Commands {
    let hub: HubOMatic

    public var body: some Commands {
        Group {
            CommandGroup(after: CommandGroupPlacement.appSettings) {
                hub.checkForUpdateButton()
            }
            CommandGroup(after: CommandGroupPlacement.help) {
                hub.checkForUpdateButton()
            }
        }
    }
}

public extension Scene {
    /// Installs update commands into the given scene
    func withHubOMatic(_ hub: HubOMatic) -> some Scene {
        Group {
            self.commands { HubOMaticUpdateCommands(hub: hub) }
        }
    }
}


