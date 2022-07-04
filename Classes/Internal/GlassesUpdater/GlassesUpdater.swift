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
import UIKit

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
    case invalidToken                           // 9
    case connectionLost                         // 10
    case abortingUpdate                         // 11
}


// MARK: - Definition

internal class GlassesUpdater {


    // MARK: - Private properties

    private weak var sdk: ActiveLookSDK?

    private var glasses: Glasses?

    private var rebootClosure: ( (Int) -> Void )?
    private var successClosure: ( () -> Void )?
    private var errorClosure: ( (GlassesUpdateError) -> Void )?

    private var firmwareUpdater: FirmwareUpdater?
    private var versionChecker: VersionChecker?
    private var downloader: Downloader?

    // If the batteryLevel is less than 10, the update will not proceed.
    private var batteryLevel: Int? {
        didSet {
            guard let bl = batteryLevel else {
                return
            }

            // TODO: NC Question: Are you sure about this ? It seams that a low battery notification if triggered
            // TODO: NC Question: even if the update process has not been started.
            // TODO: NC Question: In this class, the battery level is set first before checking anything
            // TODO: Check if remove ok : if bl < 10 {
            // TODO: Check if remove ok :    sdk?.updateParameters.notify(.lowBattery, 0, bl)
            // TODO: Check if remove ok : } else {
                if let vcr = vcResult {
                    process(vcr)
                }
            // }
        }
    }

    private var vcResult: VersionCheckResult?

    private enum SoftwareAsset {
        case firmware(Firmware)
        case configuration(String)
    }

    private struct Authorization {
        let software: SoftwareAsset
        var decision: Bool?

        init(_ asset: SoftwareAsset) {
            self.software = asset
        }
    }

    private var authorization: Authorization? {
        didSet {
            guard let authorization = authorization else {
                return
            }

            guard let decision = authorization.decision else {
                return
            }

            guard decision else {
                sdk?.updateParameters.notify(.updateFailed)
                return
            }

            switch authorization.software {
            case .firmware(let firmware):
                updateFirmware(using: firmware)
            case .configuration(let cfg):
                updateConfiguration(with: cfg)
            }
        }
    }

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

        // TODO: ASANA task "Check glasses FW version <= SDK version" – https://app.asana.com/0/1201639829815358/1202209982822311 – 220504

        sdk?.updateParameters.notify(.startingUpdate)

        // get battery level
        glasses.battery( { self.batteryLevel = $0 } )

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
            sdk?.updateParameters.notify(.updateFailed)
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
        case .needsUpdate(let url) :
            dlog(message: "Firmware needs update",
                 line: #line, function: #function, file: #fileID)

            // If battery level is < 10, update is stopped here, and will start back only when > 10
            guard let bl = batteryLevel, bl >= 10 else {
                glasses?.subscribeToBatteryLevelNotifications(onBatteryLevelUpdate: {
                    if $0 < 10 {
                        self.sdk?.updateParameters.notify(.lowBattery, 0, $0)
                    }
                    self.batteryLevel = $0
                })
                vcResult = result
                sdk?.updateParameters.notify(.lowBattery, 0, batteryLevel)
                return
            }

            if vcResult != nil { vcResult = nil }

            guard NetworkMonitor.shared.isConnected else {
                failed(with: GlassesUpdateError.networkUnavailable)
                return
            }

            sdk?.updateParameters.notify(.downloadingFw)

            downloader = Downloader()
            downloader?.downloadFirmware(at: url,
                                         onSuccess: {( data ) in self.askUpdateAuthorization(for: Firmware( with: data))},
                                         onError: {( error ) in self.failed(with: error )})

        case .isUpToDate, .noUpdateAvailable:
            dlog(message: "Firmware is up-to-date",
                 line: #line, function: #function, file: #fileID)

            checkConfigurationRecency()
        }
    }

    private func askUpdateAuthorization(for firmware: Firmware)
    {
        guard let sdkGU = sdk?.updateParameters.createSDKGU(.updatingFw) else {
            fatalError("cannot create SDKGlassesUpdate from .updatingFW")
        }

        // the decision is processed via an observer on `self.authorisation`
        self.authorization = Authorization(.firmware(firmware))
        sdk?.updateParameters.updateAvailableClosure(sdkGU, {
            self.authorization?.decision = true
        })
    }

    private func updateFirmware(using firmware: Firmware)
    {
        sdk?.updateParameters.notify(.updatingFw)

        downloader = nil

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

        let delay: Int = sdk.updateParameters.needDelayAfterReboot() ? 3000 : 500

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
        case .needsUpdate(let url):
            dlog(message: "Configuration needs update", 
                 line: #line, function: #function, file: #fileID)

            guard NetworkMonitor.shared.isConnected else {
                failed(with: GlassesUpdateError.networkUnavailable)
                return
            }
            
            sdk?.updateParameters.notify(.downloadingConfig)

            downloader = Downloader()
            downloader?.downloadConfiguration(at: url,
                                             onSuccess: { ( cfg ) in self.askUpdateAuthorization(for: cfg) },
                                              onError: { ( error ) in self.failed(with: error ) })

        case .isUpToDate, .noUpdateAvailable:
            dlog(message: "Configuration is up-to-date!",
                 line: #line, function: #function, file: #fileID)

            configurationIsUpToDate()
        }
    }


    private func askUpdateAuthorization(for configuration: String)
    {
        guard let sdkGU = sdk?.updateParameters.createSDKGU(.updatingConfig) else {
            fatalError("cannot create SDKGlassesUpdate from .updatingConfig")
        }
        // the decision is processed via an observer on `self.authorisation`
        self.authorization = Authorization(.configuration(configuration))
        sdk?.updateParameters.updateAvailableClosure(sdkGU, {
            self.authorization?.decision = true
        })
    }


    private func updateConfiguration(with configuration: String)
    {
        sdk?.updateParameters.notify(.updatingConfig)

        downloader = nil

        sdk?.updateParameters.notify(.updatingConfig)

        guard glasses!.areConnected() else {
            failed(with: GlassesUpdateError.glassesUpdater(message: "Glasses NOT connected"))
            return
        }

        glasses?.clear()
        glasses?.layoutDisplay(id: 0x09, text: "")
        glasses?.loadConfigurationWithClosures(cfg: configuration,
                                               onSuccess: {
                                                    self.glasses?.clear()
                                                    self.configurationIsUpToDate()
                                               },
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
