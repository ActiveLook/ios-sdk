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
    //    case DOWNLOADING_FIRMWARE
    case startingUpdate
    case retrievingDeviceInformations
    case deviceInformationsRetrieved
    case checkingFwVersion
    case downloadingFw
    case noFwUpdateAvailable
    //    case UPDATING_FIRMWARE
    case updatingFw
    case rebooting
    //    case DOWNLOADING_CONFIGURATION
    case checkingConfigVersion
    case downloadingConfig
    //    case UPDATING_CONFIGURATION
    case updatingConfig
    //    case ERROR_UPDATE_FORBIDDEN // UNAVAILABLE
    //    case ERROR_DOWNGRADE_FORBIDDEN
    case updateDone
    //    case ERROR_UPDATE_FAIL
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
    
    private var progress: UInt8 = 0

    private var updateStateToGlassesUpdate: [[UpdateState]]

    private let downloadingFW: [UpdateState] = [.startingUpdate,
                                        .retrievingDeviceInformations,
                                        .deviceInformationsRetrieved,
                                        .checkingFwVersion,
                                        .downloadingFw]
    private let updatingFW: [UpdateState] = [.noFwUpdateAvailable, .updatingFw, .rebooting]
    private let downloadingCfg: [UpdateState] = [.checkingConfigVersion,
                                                 .downloadingConfig]
    private let updatingCfg: [UpdateState] = [.updatingConfig, .updateDone]
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

        self.updateStateToGlassesUpdate = [downloadingFW, updatingFW, downloadingCfg, updatingCfg, updateFailed]
    }


    // MARK: - Internal Functions
    
    func update(_ stateUpdate: UpdateState, _ progress: UInt8 = 0)
    {
        dlog(message: "progress update to \(stateUpdate) – \(progress)",
             line: #line, function: #function, file: #fileID)

        guard let index = updateStateToGlassesUpdate.firstIndex(where: {
            updateStateArr in updateStateArr.contains(stateUpdate) })
        else {
            return
        }

        var stateProgress: UInt8 = 0

        switch index {
        case State.DOWNLOADING_FIRMWARE.rawValue:
            stateProgress = 1

        case State.UPDATING_FIRMWARE.rawValue:
            stateProgress = 1 + (UInt8(progress / 2) < 48 ? UInt8(progress / 2) : 48)

        case State.DOWNLOADING_CONFIGURATION.rawValue:
            stateProgress = 50

        case State.UPDATING_CONFIGURATION.rawValue:
            stateProgress = 51 + (UInt8(progress / 2) <= 48 ? UInt8(progress / 2) : 48)

        case State.ERROR_UPDATE_FAIL.rawValue:
            stateProgress = 200
        default:
            return
        }

        if (stateProgress <= self.progress) { return }
        self.progress = stateProgress

        // new glassUpdate
        let state = State(rawValue: index)!
        let sdkGU = SdkGlassesUpdate(for: nil,
                                        state: state,
                                        progress: self.progress,
                                        sourceFirmwareVersion: "sFwV",
                                        targetFirmwareVersion: "tFwV",
                                        sourceConfigurationVersion: "sCfgV",
                                        targetConfigurationVersion: "tCfgV")

        switch state {
        case .DOWNLOADING_FIRMWARE, .UPDATING_FIRMWARE, .DOWNLOADING_CONFIGURATION, .UPDATING_CONFIGURATION:
            progressClosure(sdkGU)
        case .ERROR_UPDATE_FORBIDDEN, .ERROR_DOWNGRADE_FORBIDDEN:
            successClosure(sdkGU)
        case .ERROR_UPDATE_FAIL:
            failureClosure(sdkGU)
        }
    }


    func reset() {
        discoveredGlasses = nil
        hardware = ""
        state = nil
        progress = 0
    }
}

