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

// MARK: - Internal Enum

internal enum UpdateState : String {
    case NOT_INITIALIZED
    case startingUpdate
    case retrievingDeviceInformations
    case deviceInformationsRetrieved
    case checkingFwVersion
    case noFwUpdateAvailable
    // case DOWNLOADING_FIRMWARE -> calling startClosure(GlassesUpdate)
    case downloadingFw
    // case UPDATING_FIRMWARE -> calling progressClosure(GlassesUpdate)
    case updatingFw
    case rebooting
    case checkingConfigVersion
    // case DOWNLOADING_CONFIGURATION -> calling startClosure(GlassesUpdate)
    case noConfigUpdateAvailable
    case downloadingConfig
    // case UPDATING_CONFIGURATION -> calling progressClosure(GlassesUpdate)
    case updatingConfig
    // -> calling successClosure(GlassesUpdate)
    case upToDate
    // case ERROR_UPDATE_FAIL_LOW_BATTERY
    // case ERROR_UPDATE_FORBIDDEN // UNAVAILABLE
    // case ERROR_DOWNGRADE_FORBIDDEN
    case updateForbidden
    case downgradeForbidden
    // case ERROR_UPDATE_FAIL
    //  -> calling failurexClosure(GlassesUpdate)
    case updateFailed
    case lowBattery
    // -> calling failureClosure(.gu(ERROR_UPDATE_FAIL_LOW_BATTERY))
}


// MARK: - Definition

internal class GlassesUpdateParameters {

    // TODO: refactor glassesUpdateParameter / GlassesUpdate / SdkGlassesUpdate
    // TODO: CREATE NEW class `UpdaterParameters{}`? to dissociate GlassesUpdate parameters from SDK ones?

    // FIXME: vvv RELATED TO Updater vvv
    var token: String
    var startClosure: StartClosureSignature
    var updateAvailableClosure: UpdateAvailableClosureSignature
    var progressClosure: ProgressClosureSignature
    var successClosure: SuccessClosureSignature
    var failureClosure: FailureClosureSignature
    // FIXME: ^^^ RELATED TO Updater ^^^

    // FIXME: vvv RELATED TO GlassesUpdate vvvv
    var discoveredGlasses: DiscoveredGlasses?
    
    var hardware: String

    var state: UpdateState?
    
    private var softwareVersions: [SoftwareLocation : SoftwareVersions?]
    
    private var progress: Double = 0
    private var batteryLevel: Int?

    // used to match `UpdateStates` to `SDKGlassesUpdate.States`
    private var updateStateToGlassesUpdate: [[UpdateState]]

    private let downloadingFW: [UpdateState] = [.downloadingFw]
    private let updatingFW: [UpdateState] = [.updatingFw, .rebooting]
    private let downloadingCfg: [UpdateState] = [.downloadingConfig]
    private let updatingCfg: [UpdateState] = [.updatingConfig, .upToDate]
    private let updateFailed: [UpdateState] = [.updateFailed]
    private let updateFailedLowBattery: [UpdateState] = [.lowBattery]
    private let updateForbidden: [UpdateState] = [.updateForbidden] // TODO: ASANA task "Check glasses FW version <= SDK version" – https://app.asana.com/0/1201639829815358/1202209982822311 – 220504
    private let downgradeForbidden: [UpdateState] = [.downgradeForbidden] // TODO: ASANA task "Check glasses FW version <= SDK version" – https://app.asana.com/0/1201639829815358/1202209982822311 – 220504

    // FIXME: ^^^ RELATED TO GlassesUpdate ^^^
    
    // MARK: - Life Cycle
    
    init(_ token: String,
         _ onUpdateStartCallback: @escaping StartClosureSignature,
         _ onUpdateAvailableCallback: @escaping UpdateAvailableClosureSignature,
         _ onUpdateProgressCallback: @escaping ProgressClosureSignature,
         _ onUpdateSuccessCallback: @escaping SuccessClosureSignature,
         _ onUpdateFailureCallback: @escaping FailureClosureSignature )
    {
        // FIXME: vvv RELATED TO Updater vvv
        self.token = token
        self.startClosure = onUpdateStartCallback
        self.updateAvailableClosure = onUpdateAvailableCallback
        self.progressClosure = onUpdateProgressCallback
        self.successClosure = onUpdateSuccessCallback
        self.failureClosure = onUpdateFailureCallback
        // FIXME: ^^^ RELATED TO Updater ^^^

        // FIXME: vvv RELATED TO GlassesUpdate vvv
        self.hardware = ""

        self.updateStateToGlassesUpdate = [downloadingFW, updatingFW,
                                           downloadingCfg, updatingCfg,
                                           updateFailed, updateFailedLowBattery,
                                           updateForbidden, downgradeForbidden]
        
        self.softwareVersions = [ .device: nil, .remote: nil ]
        // FIXME: ^^^ RELATED TO GlassesUpdate ^^^
    }


    // MARK: - Internal Functions

    func notify(_ stateUpdate: UpdateState, _ progress: Double = 0, _ batteryLevel: Int? = nil)
    {
        dlog(message: "progress update to \(stateUpdate) – \(progress)",
             line: #line, function: #function, file: #fileID)

        state = stateUpdate

        var closureToSummon: StartClosureSignature? // all closures have the same signature

        switch stateUpdate
        {
        case .downloadingFw, .downloadingConfig:
            // start closure
            self.progress = 0
            closureToSummon = startClosure

        case .updatingFw, .updatingConfig:
            // progress closure
            if ( progress <= self.progress ) { return }
            
            self.progress = progress
            closureToSummon = progressClosure

        case .rebooting:
            // we are calling notify(.rebooting) twice:
            //  - once to signify that the fw update has completed, thus progress == 100
            //  - the 2nd time, to call the success() closure, so the notification flow is on par with Android
            self.progress = 100

            if progress > 100 {
                closureToSummon = successClosure
            } else {
                closureToSummon = progressClosure
            }

        case .upToDate:
            // success closure
            self.progress = 100
            closureToSummon = successClosure

        case .updateFailed, .lowBattery, .updateForbidden, .downgradeForbidden:
            // failure closure
            if batteryLevel != nil { self.batteryLevel = batteryLevel }
            closureToSummon = failureClosure

        default:
            // the remaining UpdateStates are not forwarded to the application.
            return
        }

        closureToSummon!(createSDKGU(state!))
    }


    func createSDKGU(_ state: UpdateState) -> SdkGlassesUpdate
    {
        return SdkGlassesUpdate(for: nil,
                                state: retrieveState(from: state)!,
                                progress: self.progress,
                                batteryLevel: self.batteryLevel,
                                sourceFirmwareVersion: self.getVersion(for: .device, softwareClass: .firmwares),
                                targetFirmwareVersion: self.getVersion(for: .remote, softwareClass: .firmwares),
                                sourceConfigurationVersion: self.getVersion(for: .device, softwareClass: .configurations),
                                targetConfigurationVersion: self.getVersion(for: .remote, softwareClass: .configurations))
    }


    func set(version: SoftwareClassProtocol, for location: SoftwareLocation)
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)
        switch version {
        case is ConfigurationVersion:
            let fwVers = softwareVersions[location]!!.firmware
            softwareVersions[location] = SoftwareVersions(firmware: fwVers, configuration: version as! ConfigurationVersion)
            break
        case is FirmwareVersion:
            let cfgVers = ConfigurationVersion(major: 0)
            softwareVersions[location] = SoftwareVersions(firmware: version as! FirmwareVersion, configuration: cfgVers)
            break
        default:
            // Unknown
            break
        }
    }

    
    func getVersions() -> String {
        var versions = ""
        versions.append(getVersion(for: .device, softwareClass: .firmwares))
        versions.append(getVersion(for: .remote, softwareClass: .firmwares))
        versions.append(getVersion(for: .device, softwareClass: .configurations))
        versions.append(getVersion(for: .remote, softwareClass: .configurations))
        return versions
    }


    func reset() {
        discoveredGlasses = nil
        hardware = ""
        state = .NOT_INITIALIZED
        progress = 0
    }


    func isUpdating() -> Bool {
        switch state {
        case .NOT_INITIALIZED, .rebooting, .upToDate, .updateFailed:
            return false
        default:
            return true
        }
    }

    func isRebooting() -> Bool {
        switch state {
        case .rebooting:
            return true
        default:
            return false
        }
    }

    func firmwareHasBeenUpdated () {
        softwareVersions[.device]!!.firmware = softwareVersions[.remote]!!.firmware
    }


    // TODO: remove after micooled says so
    func needDelayAfterReboot() -> Bool
    {
        let fwVers = softwareVersions[.device]!!.firmware

        return (fwVers.major < 4) || (fwVers.major == 4 && fwVers.minor < 3) || (fwVers.major == 4 && fwVers.minor == 3 && fwVers.patch < 2)
    }


    // MARK: - Private functions

    /// Retrieve the `State` associated with the internal `UpdateState`.
    ///
    /// The table `updateStateToGlassesUpdate[]` is used to match the different cases.
    ///
    /// - parameter stateUpdate: UpdateState — The internal state to retrieve
    ///
    /// - returns: `Optional` `State` to include in a `GlassesUpdate` object. Nil if not found.
    ///
    private func retrieveState(from stateUpdate: UpdateState) -> State?
    {
        guard let index = updateStateToGlassesUpdate.firstIndex( where: {
            updateStateArr in updateStateArr.contains( stateUpdate ) })
        else {
            return nil
        }
        return State(rawValue: index)!
    }
    
    
    private func getVersion(for location: SoftwareLocation, softwareClass: SoftwareClass) -> String
    {
        let na = "n/a"
        
        guard let swVers: SoftwareVersions = softwareVersions[location]! else {
            return na
        }
        
        var version: String = ""
        switch softwareClass {
        case .firmwares:
            version = swVers.firmware.version
            break
        case .configurations:
            version = swVers.configuration.major != 0 ? swVers.configuration.description : na
            break
        }
        return version
    }
    // FIXME: ^^^ RELATED TO GlassesUpdate ^^^
}

