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


// MARK: -  Type Alias

typealias startClosureSignature = () -> ()
typealias progressClosureSignature = () -> ()
typealias successClosureSignature = () -> ()
typealias failureClosureSignature = () -> ()


// MARK: - Internal Enum

internal enum UpdateState : String {
    case NOT_INITIALIZED
    case startingUpdate
    case retrievingDeviceInformations
    case deviceInformationsRetrieved
    case checkingFwVersion
    case downloadingFw
    case noFwUpdateAvailable
    case updatingFw
    case rebooting
    case checkingConfigVersion
    case downloadingConfig
    case updatingConfig
    case updateDone
    case updateFailed
}


// MARK: - Definition

internal class GlassesUpdateParameters {

    var token: String
    var startClosure: startClosureSignature
    var progressClosure: progressClosureSignature
    var successClosure: successClosureSignature
    var failureClosure: failureClosureSignature

    var hardware: String

    var state: UpdateState?


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
    }

    // MARK: - Internal Functions

    func isReady() -> Bool {
        return state == .updateDone
    }

}

