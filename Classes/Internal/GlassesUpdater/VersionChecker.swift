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
import CoreBluetooth

// MARK: - Internal Enumerations

internal enum VersionStatus {
    case needsUpdate( apiURL: URL )
    case isUpToDate
}


// MARK: - Internal Strutures

internal struct VersionCheckResult {
    let software: SoftwareClass
    let status: VersionStatus
}


// MARK: - FilePrivate Structures

fileprivate struct Latest: Codable {
    let api_path: String
    let version: [Int]
}


fileprivate struct FirmwareJSON: Codable {
    let latest: Latest
}


internal enum VersionCheckError: Error {
    case versionCheckerError(message: String)
}


// MARK: - Definition

// The `VersionChecker` class checks if the glasses' softwares are up-to-date.
internal final class VersionChecker: NSObject {


    // MARK: - Private Variables
    private var glasses: Glasses

    private var urlGenerator: GlassesUpdaterURL

    private var successClosure: (( VersionCheckResult ) -> (Void))?
    private var errorClosure: (( VersionCheckError ) -> (Void))?

    private let timeoutDuration: TimeInterval = 5
    private var timeoutTimer: Timer?


    private var glassesFWVersion: FirmwareVersion? {
        didSet {
            if glassesFWVersion != nil {
                self.fetchRemoteFirmwareVersion()
            }
        }
    }

    private var remoteFWVersion: FirmwareVersion? {
        didSet {
            if remoteFWVersion != nil {
                self.compareFWVersions()
            }
        }
    }


/* TODO: STEPS IN TESTING
 SET UP IPHONE XS AS TESTING DEVICE
    1. Install without making any changes
    2. Make necessary changes
    3. Refactor !!!!! (but last step!) */


    private var result: VersionCheckResult? {
        didSet {
            self.versionChecked()
        }
    }


    // MARK: - Initializers
    
    init(for glasses: Glasses) {
        self.glasses = glasses
        self.urlGenerator = GlassesUpdaterURL.shared()
    }


    // MARK: - Life-Cycle
    
    private func cleanUp() {
        self.successClosure = nil
        self.errorClosure = nil
        self.timeoutTimer?.invalidate()
        self.glasses.peripheral.delegate = self.glasses.peripheralDelegate
    }


    // MARK: - Internal Methods

    public func isFirmwareUpToDate(onSuccess successClosure: @escaping ( VersionCheckResult ) -> (Void),
                                   onError errorClosure: @escaping ( VersionCheckError ) -> (Void)) {

        self.successClosure = successClosure
        self.errorClosure = errorClosure

        readDeviceFWVersion()
    }

    #warning("isConfigurationUpToDate TODO later")
//    internal func isConfigurationUpToDate() -> VersionCheckResult {
//    }


    // MARK: - Private Methods

    private func versionChecked() {
        guard let result = result else {
            failed(with: VersionCheckError.versionCheckerError(message: "Result NOT set"))
            return
        }

        successClosure?(result)
        cleanUp()
    }


    private func failed(with error: VersionCheckError) {

        errorClosure?(error)
        cleanUp()
    }


    private func fetchRemoteFirmwareVersion() {

        guard let gfw = glassesFWVersion else {

            failed(with: VersionCheckError.versionCheckerError(message: "Glasses FW Version unavailable"))
            return
        }

        // format URL string
        let url = urlGenerator.firmwareHistoryURL(for: gfw)

        let task = URLSession.shared.dataTask( with: url ) { data, response, error in
            guard error == nil else {
                // Client error
                self.failed(with: VersionCheckError.versionCheckerError( message: "Client error" ))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                      // Server error
                      self.failed(with: VersionCheckError.versionCheckerError( message: "Server error" ))
                      return
                  }

            guard let data = data else {
                self.failed(with: VersionCheckError.versionCheckerError(
                    message: "Retrieved data is nil" ))
                return
            }

            guard let decodedData = try? JSONDecoder().decode( FirmwareJSON.self, from: data ) else {
                self.failed(with: VersionCheckError.versionCheckerError(
                    message: "JSON decoding error: \(String(describing: error))"))
                return
            }

            let vers = decodedData.latest.version
            let apiPath = decodedData.latest.api_path
            
            DispatchQueue.main.async {
                self.remoteFWVersion = FirmwareVersion(major: vers[0],
                                                       minor: vers[1],
                                                       patch: vers[2],
                                                       extra: "",
                                                       path: apiPath)
            }

        }
        task.resume()
    }


    private func compareFWVersions() {
        guard let rfw = remoteFWVersion,
              let gfw = glassesFWVersion else {
                  failed(with: VersionCheckError.versionCheckerError(
                    message: "compareFWVersions: rfw or gfw NOT SET"))
                  return
              }

//        if rfw > gfw {
        if true {
            // need to update
            guard let apiPath = rfw.path else {
                failed(with: VersionCheckError.versionCheckerError(
                    message: "remote FW path not set"))
                return
            }
            let apiURL = urlGenerator.firmwareDownloadURL(using: apiPath)
            result = VersionCheckResult( software: .firmware, status: .needsUpdate(apiURL: apiURL) )
        } else {
            // up-to-date
            self.result = VersionCheckResult( software: .firmware, status: .isUpToDate )
            print("FIRMWARE UP-TO-DATE")
        }
    }

    private func readDeviceFWVersion() {

        guard let di = glasses.peripheral.getService(withUUID: CBUUID.DeviceInformationService) else {
            failed(with: VersionCheckError.versionCheckerError(
                message: "DeviceInformationService Unavailable"))
            return
        }

        guard let characteristic = di.getCharacteristic(forUUID: CBUUID.FirmwareVersionCharateristic) else {
            failed(with: VersionCheckError.versionCheckerError(
                message: "firmwareVersionCharateristic NOT SET"))
            return
        }

        let fwString = characteristic.valueAsUTF8

        let components = fwString.components(
            separatedBy: .decimalDigits.inverted).filter(
                { $0 != "" }).map({
                    Int($0) })

        let major = Int(components[0] ?? 0)
        let minor = Int(components[1] ?? 0)
        let patch = Int(components[2] ?? 0)

        glassesFWVersion = FirmwareVersion(major: major,
                                                minor: minor,
                                                patch: patch,
                                                extra: nil, path: nil, error: nil)
    }

}
