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


internal enum UpdateState : Int {
    case NOT_INITIALIZED = 0
    case retrievedDeviceInformations
    case updating
    case checkingFWVersion
    case updatingFW
    case checkingConfigVersion
    case updatingConfig
    case DONE
}


internal class GlassesUpdateParameters {

    var token: String
    var startClosure: () -> Void
    var progressClosure: () -> Void
    var successClosure: () -> Void
    var failureClosure: () -> Void

    var state: UpdateState = .checkingFWVersion

//    var firmware: Firmware?

//    var successClosure: (() -> (Void))?
//    var progressClosure: (( UpdateProgress ) -> (Void))?
//    var errorClosure: (( FirmwareUpdateError ) -> (Void))?

//    private let initTimeoutDuration: TimeInterval = 5
//    private let initPollInterval: TimeInterval = 0.2
//
//    private var initTimeoutTimer: Timer?
//    private var initPollTimer: Timer?

    init(_ token: String,
    _ onUpdateStartCallback: @escaping () -> Void,
    _ onUpdateProgressCallback: @escaping () -> Void,
    _ onUpdateSuccessCallback: @escaping () -> Void,
    _ onUpdateFailureCallback: @escaping () -> Void ) {
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

