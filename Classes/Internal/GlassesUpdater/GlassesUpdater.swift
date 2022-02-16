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
//import CoreText

// MARK: - Internal Enumerations

internal enum GlassesUpdateError: Error
{
    case glassesUpdater(message: String = "")   // 0
    case versionChecker(message: String = "")   // 1
    case versionCheckerNoUpdateAvailable       // 2
    case downloader(message: String = "")       // 3
    case downloaderClientError                  // 4
    case downloaderServerError                  // 5
    case downloaderJsonError                    // 6
    case firmwareUpdater(message: String = "")  // 7
}


// MARK: - Definition

internal class GlassesUpdater {


    // MARK: - Private properties

    private weak var sdk: ActiveLookSDK?

    private var glasses: Glasses?

    private var successClosure: ( () -> () )?

    private var errorClosure: ( () -> () )?

    private var firmwareUpdater: FirmwareUpdater?
    private var versionChecker: VersionChecker?


    // MARK: - Life cycle

    init()
    {
        guard let sdk = try? ActiveLookSDK.shared() else
        {
            fatalError(String(format: "SDK Singleton NOT AVAILABLE @  %i", #line))
        }

        self.sdk = sdk
    }


    // MARK: - Internal methods

    func update(_ glasses: Glasses,
                onSuccess successClosure: @escaping () -> (),
                onError errorClosure: @escaping () -> () )
    {
        self.glasses = glasses
        self.successClosure = successClosure
        self.errorClosure = errorClosure

        versionChecker = VersionChecker()

        // Start update process
        sdk?.updateParameters.state = .startingUpdate
        
        self.checkFirmwareRecency()
    }


    // MARK: - Private methods

    private func failed(with error: GlassesUpdateError)
    {
        dlog(message: error.localizedDescription, line: #line, function: #function, file: #fileID)

        sdk?.updateParameters.state = .updateFailed

        errorClosure?()
    }


    private func process(_ versCheckResult: VersionCheckResult)
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        switch versCheckResult.software
        {
        case .firmwares :
            sdk?.updateParameters.state = .checkingFwVersion
            processFirmwareResponse( versCheckResult )

        case .configurations :
            sdk?.updateParameters.state = .checkingConfigVersion
            processConfigurationResponse( versCheckResult )
        }
    }


    // MARK: Firmware Methods

    private func checkFirmwareRecency()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        sdk?.updateParameters.state = .checkingFwVersion

        versionChecker?.isFirmwareUpToDate(for: glasses!,
                                             onSuccess: { ( result ) in self.process( result ) },
                                             onError: { ( error ) in self.failed(with: error ) })
    }


    private func processFirmwareResponse(_ result: VersionCheckResult )
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        switch result.status
        {
        case .needsUpdate(let apiUrl) :
            let downloader = Downloader()
            downloader.downloadFirmware(at: apiUrl,
                                         onSuccess: {( data ) in self.updateFirmware(using: Firmware( with: data))},
                                         onError: {( error ) in self.failed(with: error )})

        case .isUpToDate, .noUpdateAvailable:
            checkConfigurationRecency()
        }
    }

    private func updateFirmware(using firmware: Firmware)
    {
        dlog(message: firmware.description(), line: #line, function: #function, file: #fileID)

        sdk?.updateParameters.state = .updatingFw

        firmwareUpdater = FirmwareUpdater(onSuccess: { self.waitingForGlassesReboot() },
                                        onError: { error in self.failed(with: error) })

        firmwareUpdater?.update(glasses!, with: firmware)

    }


    private func waitingForGlassesReboot()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        successClosure?()
    }


    // MARK: Configuration Methods

    private func checkConfigurationRecency()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        sdk?.updateParameters.state = .checkingFwVersion

        versionChecker?.isConfigurationUpToDate( for: glasses!,
                                                    onSuccess: { ( result ) in self.process( result ) },
                                                    onError: { ( error ) in self.failed(with: error ) })
    }

    private func processConfigurationResponse(_ result: VersionCheckResult )
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        switch result.status
        {
        case .needsUpdate(let apiUrl):
            dlog(message: "Configuration needs update", 
                 line: #line, function: #function, file: #fileID)

            sdk?.updateParameters.state = .updatingConfig
            print(apiUrl)
            let downloader = Downloader()
            downloader.downloadConfiguration(at: apiUrl,
                                              onSuccess: { ( cfg ) in self.updateConfiguration(with: cfg ) },
                                              onError: { ( error ) in self.failed(with: error ) })
//            if let filePath = Bundle.main.path(forResource: "configTEST", ofType: "txt") {
//                do {
//                    let cfg = try String(contentsOfFile: filePath)
//                    self.updateConfiguration(with: cfg )
//                } catch {}
//            }

        case .isUpToDate, .noUpdateAvailable:
            dlog(message: "Configuration is up-to-date!",
                 line: #line, function: #function, file: #fileID)

            configurationUpToDate()
        }
    }

    private func updateConfiguration(with configuration: String)
    {
        dlog(message: "", line: #line, function: #function, file: #fileID)

        print("ConfigurationString.count: \(configuration.count)")

        glasses?.loadConfigurationWithClosures(cfg: configuration,
                                               onProgress: { progress in print("progress: \(progress)") },
                                               onSuccess: { print("success"); self.configurationUpToDate()},
                                               onError: { print("ERROR") })
    }

    private func configurationUpToDate() {

        dlog(message: "",line: #line, function: #function, file: #fileID)

        sdk?.updateParameters.state = .updateDone
        successClosure?()
    }
}
