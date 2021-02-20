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

/// The central manager for checking for app updates and providing UI components for configuring and controlling the update process.
public final class HubOMatic : ObservableObject {
    public let config: Config
    private var subscribers = Set<AnyCancellable>()
    private let updater = SUUpdater.shared()!

    /// The configuration for a HubOMatic App. Provides default conventions for deployment platforms such as GitHub.
    public struct Config : Hashable, Codable {
        public var releasesURL: URL
        public var versionInfo: URL
        public var versionInfoLocal: URL?
        public var relativeArtifact: String

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
        public static func github(org orgName: String? = nil, repo repoName: String? = nil, update: String = "appcast.xml", archive: String? = nil, latest: String = "latest", host hostURL: URL = URL(string: "https://github.com")!) -> Self {

            let mainBundle = Bundle.main.bundleIdentifier
            let repo = repoName ?? mainBundle?.split(separator: ".").last?.description ?? "RepoName"
            let org = orgName ?? mainBundle?.split(separator: ".").dropLast().last?.description ?? "orgname"
            let orgURL = hostURL.appendingPathComponent(org)
            let repoURL = orgURL.appendingPathComponent(repo)
            let releasesURL = repoURL.appendingPathComponent("releases")
            let latestURL = releasesURL.appendingPathComponent(latest)
            let downloadDir = latestURL.appendingPathComponent("download")
            let updatePath = downloadDir.appendingPathComponent(update)

            let config = Config(releasesURL: releasesURL, versionInfo: updatePath, versionInfoLocal: Bundle.main.url(forResource: update, withExtension: nil), relativeArtifact: archive ?? repo + ".zip")

            return config
        }
    }

    deinit {
        subscribers.removeAll()
    }

    private init(config: Config) {
        self.config = config
    }

    func setup() {
        UserDefaults.standard.set(config.versionInfo.absoluteString, forKey: "SUFeedURL")
    }
}

public extension HubOMatic {
    /// The URL for downloading the artifact
    var artifactURL: URL {
        config.versionInfo
            .deletingLastPathComponent()
            .appendingPathComponent(config.relativeArtifact)
    }

    @discardableResult static func create(_ config: Config) -> Self {
        let hom = Self(config: config)
        hom.setup()
        return hom
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
        Button(title, action: checkForUpdateAction)
    }


    /// Initiates an update check either in the foreground or background
    func checkForUpdate(background: Bool) {
        if background {
            updater.checkForUpdatesInBackground()
        } else {
            updater.checkForUpdates(nil)
        }
    }

    func toolbarButton() -> some View {
        Button(LocalizedStringKey("Check for Update"), action: checkForUpdateAction)
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


