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
    case downloadingConfig
    // case UPDATING_CONFIGURATION -> calling progressClosure(GlassesUpdate)
    case updatingConfig
    // -> calling successClosure(GlassesUpdate)
    case upToDate
    // case ERROR_UPDATE_FORBIDDEN // UNAVAILABLE
    // case ERROR_DOWNGRADE_FORBIDDEN
    // case ERROR_UPDATE_FAIL
    //  -> calling failurexClosure(GlassesUpdate)
    case updateFailed
}


// MARK: - Definition

internal class GlassesUpdateParameters {

    // TODO: CREATE NEW class `UpdaterParameters{}`? to dissociate GlassesUpdate parameters from SDK ones?
    var token: String
    var startClosure: StartClosureSignature
    var progressClosure: ProgressClosureSignature
    var successClosure: SuccessClosureSignature
    var failureClosure: FailureClosureSignature

    var discoveredGlasses: DiscoveredGlasses?
    
    var hardware: String

    var state: UpdateState?
    
    private var softwareVersions: [SoftwareLocation : SoftwareVersions?]
    
    private var progress: Double = 0

    private var updateStateToGlassesUpdate: [[UpdateState]]
    private let downloadingFW: [UpdateState] = [.downloadingFw]
    private let updatingFW: [UpdateState] = [.updatingFw, .rebooting]
    private let downloadingCfg: [UpdateState] = [.downloadingConfig]
    private let updatingCfg: [UpdateState] = [.updatingConfig]
    private let upToDate: [UpdateState] = [.upToDate]
    private let updateFailed: [UpdateState] = [.updateFailed]

    
    // MARK: - Life Cycle
    
    init(_ token: String,
    _ onUpdateStartCallback: @escaping StartClosureSignature,
    _ onUpdateProgressCallback: @escaping ProgressClosureSignature,
    _ onUpdateSuccessCallback: @escaping SuccessClosureSignature,
    _ onUpdateFailureCallback: @escaping FailureClosureSignature ) {
        self.token = token
        self.startClosure = onUpdateStartCallback
        self.progressClosure = onUpdateProgressCallback
        self.successClosure = onUpdateSuccessCallback
        self.failureClosure = onUpdateFailureCallback
        self.hardware = ""

        self.updateStateToGlassesUpdate = [downloadingFW, updatingFW,
                                           downloadingCfg, updatingCfg,
                                           upToDate, updateFailed]
        
        self.softwareVersions = [ .device: nil, .remote: nil ]
    }


    // MARK: - Internal Functions
    
    func update(_ stateUpdate: UpdateState, _ progress: Double = 0)
    {
        dlog(message: "progress update to \(stateUpdate) – \(progress)",
             line: #line, function: #function, file: #fileID)

        state = stateUpdate

        var closureToSummon: StartClosureSignature? // all closures have the same signature

        switch stateUpdate
        {
        case .downloadingFw, .downloadingConfig:
            // start closure
            closureToSummon = startClosure
            self.progress = 0

        case .updatingFw, .rebooting, .updatingConfig:
            // progress closure
            if ( progress <= self.progress ) { return }
            
            self.progress = progress
            closureToSummon = progressClosure

        case .upToDate:
            // success closure
            closureToSummon = successClosure
            self.progress = 100

        case .updateFailed:
            // failure closure
            closureToSummon = failureClosure

        default:
            // the remaining UpdateStates are not forwarded to the application.
            return
        }

        // new glassUpdate
        let sdkGU = SdkGlassesUpdate(for: nil,
                                     state: retrieveState(from: stateUpdate)!,
                                     progress: self.progress,
                                     sourceFirmwareVersion: getVersion(for: .device, softwareClass: .firmwares),
                                     targetFirmwareVersion: getVersion(for: .remote, softwareClass: .firmwares),
                                     sourceConfigurationVersion: getVersion(for: .device, softwareClass: .configurations),
                                     targetConfigurationVersion: getVersion(for: .remote, softwareClass: .configurations))

        closureToSummon!(sdkGU)
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

    
    func getVersion() -> String {
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
}

