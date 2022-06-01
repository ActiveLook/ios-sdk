/*

Copyright 2022 Microoled
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

import XCTest
@testable import ActiveLookSDK

final class ActiveLookSDKTests: XCTestCase {

    let token = "invalid token"
    var sut: ActiveLookSDK!
    var onUpdateStart: StartClosureSignature = { update in }
    var onUpdateAvailable: UpdateAvailableClosureSignature = { update in return true }
    var onUpdateProgress: ProgressClosureSignature = { update in }
    var onUpdateSuccess: SuccessClosureSignature = { update in }
    var onUpdateFailure: FailureClosureSignature = { update in }

    override func setUpWithError() throws {
        sut = try ActiveLookSDK.shared(token: token,
                                       onUpdateStartCallback: onUpdateStart,
                                       onUpdateAvailableCallback: onUpdateAvailable,
                                       onUpdateProgressCallback: onUpdateProgress,
                                       onUpdateSuccessCallback: onUpdateSuccess,
                                       onUpdateFailureCallback: onUpdateFailure)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func test_SDK_takesOnUpdateAvailableCallback() throws {
        XCTAssertNotNil(sut, "ActiveLookSDK needs onUpdateAvailableCallback() to get initialized.")
    }
}
