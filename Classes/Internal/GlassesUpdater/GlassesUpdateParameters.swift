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

    #warning("CREATE NEW class `UpdaterParameters{}`")
    var token: String
    var startClosure: startClosureSignature
    var progressClosure: progressClosureSignature
    var successClosure: successClosureSignature
    var failureClosure: failureClosureSignature

    var hardware: String

    var state: UpdateState?

    var progress = 0

    var updateStateToGlassesUpdate: [[UpdateState]]

    let downloadingFW: [UpdateState] = [.startingUpdate,
                                        .retrievingDeviceInformations,
                                        .deviceInformationsRetrieved,
                                        .checkingFwVersion,
                                        .downloadingFw]
    let updatingFW: [UpdateState] = [.noFwUpdateAvailable, .updatingFw, .rebooting]
    let downloadingCfg: [UpdateState] = [.checkingConfigVersion,
                                            .downloadingConfig]
    let updatingCfg: [UpdateState] = [.updatingConfig]
    let updateFailed: [UpdateState] = [.updateFailed]

    
    // MARK: - Life Cycle
    
    init(_ token: String,
    _ onUpdateStartCallback: @escaping startClosureSignature,
    _ onUpdateProgressCallback: @escaping progressClosureSignature,
    _ onUpdateSuccessCallback: @escaping successClosureSignature,
    _ onUpdateFailureCallback: @escaping failureClosureSignature ) {
        self.token = token
        self.startClosure = onUpdateStartCallback
        self.progressClosure = onUpdateProgressCallback
        self.successClosure = onUpdateSuccessCallback
        self.failureClosure = onUpdateFailureCallback
        self.hardware = ""

        self.updateStateToGlassesUpdate = [downloadingFW, updatingFW, downloadingCfg, updatingCfg, updateFailed]
    }

    // MARK: - Internal Functions

    func isReady() -> Bool {
        return state == .updateDone
    }

    
    func update(_ stateUpdate: UpdateState, _ progress: Int = 0) {

        state = stateUpdate
        
        guard let index = updateStateToGlassesUpdate.firstIndex(where: {
            updateStateArr in updateStateArr.contains(stateUpdate) })
        else {
            return
        }

        switch index {
        case State.DOWNLOADING_FIRMWARE.rawValue:
            self.progress = 1
        case State.UPDATING_FIRMWARE.rawValue:
            self.progress = 1 + Int(progress / 2) < 48 ? Int(progress / 2) : 48
            break
        case State.DOWNLOADING_CONFIGURATION.rawValue:
            self.progress = 50
            break
        case State.UPDATING_CONFIGURATION.rawValue:
            self.progress = 51 + (Int(progress / 2) <= 48 ? Int(progress / 2) : 48)
            break
        case State.ERROR_UPDATE_FAIL.rawValue:
            self.progress = 0
            break
        default:
            return
        }

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
}

