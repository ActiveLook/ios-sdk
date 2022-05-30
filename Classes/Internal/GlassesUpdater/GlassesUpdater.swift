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

internal enum GlassesUpdateError: Error
{
    case glassesUpdater(message: String = "")   // 0
    case versionChecker(message: String = "")   // 1
    case versionCheckerNoUpdateAvailable        // 2
    case downloader(message: String = "")       // 3
    case downloaderClientError                  // 4
    case downloaderServerError                  // 5
    case downloaderJsonError                    // 6
    case firmwareUpdater(message: String = "")  // 7
    case networkUnavailable                     // 8
    case connectionLost                         // 10
    case abortingUpdate                         // 11
}


// MARK: - Definition

internal class GlassesUpdater {


    // MARK: - Private properties

    private weak var sdk: ActiveLookSDK?

    private var glasses: Glasses?

    private var rebootClosure: ( (Int) -> Void )?
    private var successClosure: ( () -> () )?
    private var errorClosure: ( (GlassesUpdateError) -> () )?

    private var firmwareUpdater: FirmwareUpdater?
    private var versionChecker: VersionChecker?
    private var downloader: Downloader?


    // MARK: - Life cycle

    init()
    {
        guard let sdk = try? ActiveLookSDK.shared()
        else {
            fatalError("SDK Singleton NOT AVAILABLE")
        }

        self.sdk = sdk
    }


    // MARK: - Internal methods

    func update(_ glasses: Glasses,
                onReboot rebootClosure: @escaping (Int) -> Void,
                onSuccess successClosure: @escaping () -> (),
                onError errorClosure: @escaping (GlassesUpdateError) -> () )
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        self.glasses = glasses
        self.rebootClosure = rebootClosure
        self.successClosure = successClosure
        self.errorClosure = errorClosure

        versionChecker = VersionChecker()

        sdk?.updateParameters.notify(.startingUpdate)

        // Start update process
        checkFirmwareRecency()
    }

    func abort() -> Void {
        versionChecker?.abort()
        versionChecker = nil

        downloader?.abort()
        downloader = nil

//        firmwareUpdater.abort() // TODO: ...
        firmwareUpdater = nil
    }


    // MARK: - Private methods

    private func failed(with error: GlassesUpdateError)
    {
        switch error {
        case .networkUnavailable:
            break

        default:
            sdk?.updateParameters.update(.updateFailed)
            break
        }
        
        errorClosure?(error)
    }


    private func process(_ versCheckResult: VersionCheckResult)
    {
        switch versCheckResult.software
        {
        case .firmwares :
            processFirmwareResponse( versCheckResult )

        case .configurations :
            processConfigurationResponse( versCheckResult )
        }
    }


    // MARK: Firmware Methods

    private func checkFirmwareRecency()
    {
        sdk?.updateParameters.notify(.checkingFwVersion)

        guard NetworkMonitor.shared.isConnected else {
            failed(with: GlassesUpdateError.networkUnavailable)
            return
        }

        guard glasses!.areConnected() else {
            failed(with: GlassesUpdateError.glassesUpdater(message: "Glasses NOT connected"))
            return
        }

        versionChecker?.isFirmwareUpToDate(for: glasses!,
                                             onSuccess: { ( result ) in self.process( result ) },
                                             onError: { ( error ) in self.failed(with: error ) })
    }


    private func processFirmwareResponse(_ result: VersionCheckResult )
    {
        switch result.status
        {
        case .needsUpdate(let apiUrl) :
            dlog(message: "Firmware needs update",
                 line: #line, function: #function, file: #fileID)

            guard NetworkMonitor.shared.isConnected else {
                failed(with: GlassesUpdateError.networkUnavailable)
                return
            }

            sdk?.updateParameters.notify(.downloadingFw)

            downloader = Downloader()
            downloader?.downloadFirmware(at: apiUrl,
                                         onSuccess: {( data ) in self.updateFirmware(using: Firmware( with: data))},
                                         onError: {( error ) in self.failed(with: error )})

        case .isUpToDate, .noUpdateAvailable:
            dlog(message: "Firmware is up-to-date",
                 line: #line, function: #function, file: #fileID)

            checkConfigurationRecency()
        }
    }


    private func updateFirmware(using firmware: Firmware)
    {
        sdk?.updateParameters.notify(.updatingFw)

        downloader = nil

        sdk?.updateParameters.update(.updatingFw)

        guard glasses!.areConnected() else {
            failed(with: GlassesUpdateError.glassesUpdater(message: "Glasses NOT connected"))
            return
        }

        firmwareUpdater = FirmwareUpdater(onSuccess: { self.waitingForGlassesReboot() },
                                          onError: { error in self.failed(with: error) })

        guard glasses!.areConnected() else {
            failed(with: GlassesUpdateError.glassesUpdater(message: "Glasses NOT connected"))
            return
        }
        firmwareUpdater?.update(glasses!, with: firmware)
    }


    private func waitingForGlassesReboot()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        guard let sdk = sdk else {
            print("cannot retrieve sdk")
            return
        }

        let delay: Int = sdk.updateParameters.needDelayAfterReboot() ? 3 : 0

        rebootClosure?(delay)
    }


    // MARK: Configuration Methods

    private func checkConfigurationRecency()
    {
        sdk?.updateParameters.notify(.checkingConfigVersion)

        guard NetworkMonitor.shared.isConnected else {
            failed(with: GlassesUpdateError.networkUnavailable)
            return
        }

        guard glasses!.areConnected() else {
            failed(with: GlassesUpdateError.glassesUpdater(message: "Glasses NOT connected"))
            return
        }

        versionChecker?.isConfigurationUpToDate( for: glasses!,
                                                 onSuccess: { ( result ) in self.process( result ) },
                                                 onError: { ( error ) in self.failed(with: error ) })
    }


    private func processConfigurationResponse(_ result: VersionCheckResult )
    {
        guard glasses!.areConnected() else {
            failed(with: GlassesUpdateError.glassesUpdater(message: "Glasses NOT connected"))
            return
        }

        switch result.status
        {
        case .needsUpdate(let apiUrl):
            dlog(message: "Configuration needs update", 
                 line: #line, function: #function, file: #fileID)

            guard NetworkMonitor.shared.isConnected else {
                failed(with: GlassesUpdateError.networkUnavailable)
                return
            }
            
            sdk?.updateParameters.notify(.downloadingConfig)

            downloader = Downloader()
            downloader?.downloadConfiguration(at: apiUrl,
                                              onSuccess: { ( cfg ) in self.updateConfiguration(with: cfg ) },
                                              onError: { ( error ) in self.failed(with: error ) })

        case .isUpToDate, .noUpdateAvailable:
            dlog(message: "Configuration is up-to-date!",
                 line: #line, function: #function, file: #fileID)

            configurationIsUpToDate()
        }
    }


    private func updateConfiguration(with configuration: String)
    {
        sdk?.updateParameters.notify(.updatingConfig)

        downloader = nil

        sdk?.updateParameters.update(.updatingConfig)

        guard glasses!.areConnected() else {
            failed(with: GlassesUpdateError.glassesUpdater(message: "Glasses NOT connected"))
            return
        }

        glasses?.loadConfigurationWithClosures(cfg: configuration,
                                               onSuccess: { self.configurationIsUpToDate() },
                                               onError: { print("Configuration could not be downloaded") } )
    }


    private func configurationIsUpToDate()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        guard glasses!.areConnected() else {
            failed(with: GlassesUpdateError.glassesUpdater(message: "Glasses NOT connected"))
            return
        }

        successClosure?()
    }
}
