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

typealias startClosureSignature = () -> ()
typealias progressClosureSignature = () -> ()
typealias successClosureSignature = () -> ()
typealias failureClosureSignature = () -> ()

internal enum UpdateState : Int {
    case NOT_INITIALIZED = 0
    case retrievedDeviceInformations
    case updating
    case checkingFWVersion
    case updatingFW
    case checkingConfigVersion
    case updatingConfig
    case DONE
    case FAILED
}


internal class GlassesUpdateParameters {

    var token: String
    var startClosure: startClosureSignature
    var progressClosure: progressClosureSignature
    var successClosure: successClosureSignature
    var failureClosure: failureClosureSignature

    var state: UpdateState = .checkingFWVersion

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
    }


    func isReady() -> Bool {
        return state == .DONE
    }

}

