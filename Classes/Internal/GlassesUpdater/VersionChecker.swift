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
    case isUpToDate
    case needsUpdate( apiURL: URL )
    case noUpdateAvailable
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


fileprivate struct ConfigurationJSON: Codable {
    let latest: Latest
}

fileprivate struct FirmwareJSON: Codable {
    let latest: Latest
}


// MARK: - Definition

internal final class VersionChecker: NSObject {


    // MARK: - Private Variables

    private var sdk: ActiveLookSDK
    private var glasses: Glasses?
    private var peripheral: CBPeripheral?

    private var urlGenerator: GlassesUpdaterURL

    private var successClosure: (( VersionCheckResult ) -> (Void))?
    private var errorClosure: (( GlassesUpdateError ) -> (Void))?

    private var task: URLSessionDataTask?

    private var cancelOperations: Bool = false {
        didSet {
            if cancelOperations == true {
                task?.cancel()
                errorClosure?(GlassesUpdateError.abortingUpdate)
            }
        }
    }

    private var glassesFWVersion: FirmwareVersion? {
        didSet {
            if glassesFWVersion != nil {
                self.fetchFirmwareHistory()
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

    private var glassesConfigurationVersion: UInt32? {
        didSet {
            if (glassesConfigurationVersion != nil) && (remoteConfigurationVersion != nil) {
                self.compareConfigurationVersions()
            }
        }
    }

    private var remoteConfigurationVersion: ConfigurationVersion? {
        didSet {
            if (glassesConfigurationVersion != nil) && (remoteConfigurationVersion != nil) {
                self.compareConfigurationVersions()
            }
        }
    }

    private var result: VersionCheckResult? {
        didSet {
            self.versionChecked()
        }
    }


    // MARK: - Initializers
    
    override init()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        urlGenerator = GlassesUpdaterURL()
        
        guard let sdk = try? ActiveLookSDK.shared() else {
            fatalError(String(format: "Cannot retrieve SDK Singleton @ ", #line))
        }
        self.sdk = sdk
        
        super.init()
    }


    // MARK: - Internal Methods

    internal func isFirmwareUpToDate(for glasses: Glasses,
                                     onSuccess successClosure: @escaping ( VersionCheckResult ) -> (Void),
                                     onError errorClosure: @escaping ( GlassesUpdateError ) -> (Void))
    {
        self.glasses = glasses

        self.urlGenerator = GlassesUpdaterURL.shared()
        self.successClosure = successClosure
        self.errorClosure = errorClosure

        readDeviceFWVersion()
    }


    internal func isConfigurationUpToDate(for glasses: Glasses,
                                     onSuccess successClosure: @escaping ( VersionCheckResult ) -> (Void),
                                     onError errorClosure: @escaping ( GlassesUpdateError ) -> (Void))
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        self.glasses = glasses

        self.urlGenerator = GlassesUpdaterURL.shared()
        self.successClosure = successClosure
        self.errorClosure = errorClosure

        guard glasses.areConnected() else {
          dlog(message: "GLASSES NOT CONNECTED",
               line: #line, function: #function, file: #fileID)

          errorClosure(GlassesUpdateError.versionChecker(message: "GLASSES NOT CONNECTED!"))
          return
        }

        // call to retrieve glasses configuration concurrently with remote configuration
        glasses.cfgRead(name: "ALooK", callback: { (config: ConfigurationElementsInfo) in
            let cfgVers = ConfigurationVersion(major: Int(config.version))
            self.sdk.updateParameters.set(version: cfgVers, for: .device)
            self.glassesConfigurationVersion = config.version
        })

        fetchConfigurationHistory()
    }

    internal func abort() {
        dlog(message: "",line: #line, function: #function, file: #fileID)
        self.cancelOperations = true
    }


    // MARK: - Private Methods

    private func failed(with error: GlassesUpdateError)
    {
        dlog(message: error.localizedDescription,
             line: #line, function: #function, file: #fileID)

        errorClosure?( error )
    }


    private func versionChecked() {
        guard let result = result else {
            return
        }

        successClosure?(result)
    }

    // MARK: Configuration

    private func fetchConfigurationHistory()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        guard let gfw = glassesFWVersion else {
                readDeviceFWVersion()
            return
        }

        // format URL string
        let url = urlGenerator.configurationHistoryURL(for: gfw)

        task = URLSession.shared.dataTask( with: url ) { data, response, error in
            guard error == nil else {
                dlog(message: "CLIENT ERROR",
                        line: #line, function: #function, file: #fileID)

                self.failed(with: GlassesUpdateError.networkUnavailable)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                DispatchQueue.main.async {
                    self.remoteConfigurationVersion =
                    ConfigurationVersion(
                        major:0,
                        path: GlassesUpdateError.versionCheckerNoUpdateAvailable.localizedDescription
                    )
                }
                return
            }

            guard let data = data else {
                dlog(message: "RETRIEVED DATA IS NIL",
                        line: #line, function: #function, file: #fileID)

                self.failed(with: GlassesUpdateError.networkUnavailable)
                return
            }

            guard let decodedData = try? JSONDecoder().decode( ConfigurationJSON.self, from: data ) else {
//                self.failed(with: GlassesUpdateError.versionChecker(
//                    message: String(format: "JSON decoding error: \(String(describing: error)) @", #line)))
                return
            }

            let vers = decodedData.latest.version
            let apiPath = decodedData.latest.api_path

            DispatchQueue.main.async {
                self.remoteConfigurationVersion = ConfigurationVersion(
                                                                        major: vers[3],
                                                                        path: apiPath)
                
                self.sdk.updateParameters.set(version: self.remoteConfigurationVersion!, for: .remote)
            }
        }

        task?.resume()
    }


    private func compareConfigurationVersions()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        guard let rcfg = remoteConfigurationVersion, let gcfgVersion = glassesConfigurationVersion else {
//            failed(with: GlassesUpdateError.versionChecker(
//                message: String(format: "compareConfigurationVersions: rcfg or gcfg NOT SET @", #line)))
            return
        }

        // The 'ALooK' configuration version is only one #
        if rcfg.major > gcfgVersion {
            // needs update
            guard let apiPath = rcfg.path else {
//                failed(with: GlassesUpdateError.versionChecker(
//                    message: String(format: "remote Configuration path NOT SET @", #line)))
                return
            }

            let apiURL = urlGenerator.configurationDownloadURL(using: apiPath)
            result = VersionCheckResult( software: .configurations, status: .needsUpdate(apiURL: apiURL) )

        } else {
            // up-to-date

            if rcfg.path == GlassesUpdateError.versionCheckerNoUpdateAvailable.localizedDescription
            {
                dlog(message: "No update available",
                     line: #line, function: #function, file: #fileID)

                result = VersionCheckResult( software: .configurations, status: .noUpdateAvailable )
            }
            else {
                dlog(message: "Configuration up-to-date", 
                     line: #line, function: #function, file: #fileID)

                result = VersionCheckResult( software: .configurations, status: .isUpToDate )
            }
        }
    }


    // MARK: Firmware

    private func fetchFirmwareHistory() {

        guard let gfw = glassesFWVersion else {
            return
        }

        // format URL string
        let url = urlGenerator.firmwareHistoryURL(for: gfw)

        let task = URLSession.shared.dataTask( with: url ) { data, response, error in
            guard error == nil
            else {
//                self.failed(with: GlassesUpdateError.versionChecker(
//                    message: String(format: "Client error @", #line)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.failed(with: GlassesUpdateError.downloader(message: "Invalid Response"))
                return
            }

            guard httpResponse.statusCode != 403 else {
                self.failed(with: GlassesUpdateError.invalidToken)
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    self.remoteFWVersion =
                        FirmwareVersion(major:0,
                                        minor:0,
                                        patch:0,
                                        extra: "",
                                        path:
                                          GlassesUpdateError.versionCheckerNoUpdateAvailable.localizedDescription)
                    self.sdk.updateParameters.set(version: self.remoteFWVersion!, for: .remote)
                }
                return
            }

            guard let data = data else {
//                self.failed(with: GlassesUpdateError.versionChecker(
//                    message: String(format: "Retrieved data is nil @", #line)))
                return
            }

            guard let decodedData = try? JSONDecoder().decode( FirmwareJSON.self, from: data )
            else {
//                self.failed(with: GlassesUpdateError.versionChecker(
//                    message: String(format: "JSON decoding error: \(String(describing: error)) @", #line)))
                return
            }

            let vers = decodedData.latest.version
            let apiPath = decodedData.latest.api_path

            DispatchQueue.main.async {
                let fwVers = FirmwareVersion(major: vers[0],
                                             minor: vers[1],
                                             patch: vers[2],
                                             extra: "",
                                             path: "\(vers[0]).\(vers[1]).\(vers[2])")
                self.sdk.updateParameters.set(version: fwVers, for: .remote)
                self.remoteFWVersion = fwVers
            }

        }
        task.resume()
    }


    private func compareFWVersions()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        guard let rfw = remoteFWVersion, let gfw = glassesFWVersion
        else {
//            failed(with: GlassesUpdateError.versionChecker(
//                message: String(format: "compareFWVersions: rfw or gfw NOT SET @", #line)))
            return
        }

        if rfw > gfw {
            // need to update
            guard let apiPath = rfw.path else {
//                failed(with: GlassesUpdateError.versionChecker(
//                    message: String(format: "remote FW path NOT SET @", #line)))
                return
            }
            let apiURL = urlGenerator.firmwareDownloadURL(using: apiPath)
            result = VersionCheckResult( software: .firmwares, status: .needsUpdate(apiURL: apiURL) )
        } else {
            // up-to-date
            var message = ""
            if rfw.path == GlassesUpdateError.versionCheckerNoUpdateAvailable.localizedDescription {
                message = "No update available"
                result = VersionCheckResult( software: .firmwares, status: .noUpdateAvailable )

            } else {
                message = "Firmware up-to-date"
                result = VersionCheckResult( software: .firmwares, status: .isUpToDate )
            }
            dlog(message: message,
                 line: #line, function: #function, file: #fileID)
        }
    }

    private func readDeviceFWVersion()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        guard let di = glasses?.peripheral.getService(withUUID: CBUUID.DeviceInformationService) else {
            return
        }

        guard let characteristic = di.getCharacteristic(forUUID: CBUUID.FirmwareVersionCharateristic) else {
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

        dlog(message: "firmware Vers: \(major).\(minor).\(patch)",
             line: #line, function: #function, file: #fileID)

        let fwVers = FirmwareVersion(major: major,
                                     minor: minor,
                                     patch: patch,
                                     extra: nil, path: nil, error: nil)

        sdk.updateParameters.set(version: fwVers, for: .device)

        glassesFWVersion = fwVers
    }
}
