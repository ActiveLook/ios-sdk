/*

 Copyright 2021 Microoled
 Licensed under the Apache License, Version 2.0 (the “License”);
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an “AS IS” BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 */

import Foundation

// MARK: -
internal final class GlassesUpdaterURL {


    // MARK: - Private Properties

    private static var _shared: GlassesUpdaterURL!

    private let scheme: String = "http"
    private let host: String = "vps468290.ovh.net"
    private let port: Int? = nil   // Set to `nil` if no port number assigned

    private let minCompatibility = "4"

    private let apiVersion = "v1"
    private var softwareClass: String = ""
    private var hardware: String = ""
    private var channel: String = ""

    private var generatedURLComponents = URLComponents()

    private var sdk: ActiveLookSDK?




    // MARK: - Initializers

    init() {
        GlassesUpdaterURL._shared = self

        guard let sdk = try? ActiveLookSDK.shared() else {
            fatalError(String(format: "SDK Singleton NOT AVAILABLE @  %i", #line))
        }

        self.sdk = sdk
    }

    // MARK: - Internal Methods

    static func shared() -> GlassesUpdaterURL
    {
        switch (self._shared) {
        case let (i?):
            return i
        default:
            _shared = GlassesUpdaterURL()
            return _shared
        }
    }

    func firmwareHistoryURL(for firmwareVersion: FirmwareVersion) -> URL {
        self.softwareClass = "firmwares"
        return generateURL(for: firmwareVersion)
    }

    func firmwareDownloadURL(using apiPathString: String) -> URL {
        self.softwareClass = "firmwares"
        generateDownloadURL(for: apiPathString)
        return generatedURLComponents.url!
    }

    // MARK: - Private Methods

    private func generateURL(for firmwareVersion: FirmwareVersion) -> URL {

        guard let hardware = sdk?.updateParameters.hardware else {
            fatalError("NO HARDWARE SET")
        }

        guard let token = sdk?.updateParameters.token else {
            fatalError("NO TOKEN SET")
        }

        let pathComponents = [
            self.apiVersion,
            self.softwareClass,
            hardware,
            token
        ]

        let separator: Character = "/"
        var path = pathComponents.joined(separator: separator.description)
        if ( separator != path.first ) {
            path.insert(separator, at: path.startIndex)
        }

        var tempURLCompts = URLComponents()
        tempURLCompts.scheme = self.scheme
        tempURLCompts.host = self.host
        tempURLCompts.port = self.port
        tempURLCompts.path = path
        tempURLCompts.queryItems = [
            URLQueryItem(name: "compatibility", value: self.minCompatibility),
            URLQueryItem(name: "min-version", value: firmwareVersion.minVersion)
        ]

        return tempURLCompts.url!
    }

    private func generateDownloadURL(for apiPathString: String) {
        var tempURLCompts = URLComponents()
        tempURLCompts.scheme = self.scheme
        tempURLCompts.host = self.host
        tempURLCompts.port = self.port
        tempURLCompts.path = apiPathString

        self.generatedURLComponents = tempURLCompts
    }
}
