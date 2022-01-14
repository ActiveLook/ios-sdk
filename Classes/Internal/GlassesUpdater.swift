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


public enum GlassesUpdaterError: Error {
    case glassesUpdater(message: String = "")   // Used for development? LET'S TRY...
}

class GlassesUpdater {


    // MARK: - Private properties
//    private var firmwareDownloader: FirmwareDownloader?
    private var firmwareUpdater: FirmwareUpdater?
    private var glasses: Glasses?
    private var updateParameters: GlassesUpdateParameters


    // MARK: - Life cycle

    internal init(with parameters: GlassesUpdateParameters) {
        self.updateParameters = parameters
    }


    // MARK: - Public methods

    public func update(glasses: Glasses) throws {

        self.glasses = glasses

//        do {
//            let _ = try function_that_throws()
//            catch {
//                print("error: \(error)")
//            }
//        }

        // Upload Firmware
            // download history JSON
            // ❌ -> throw error

            // ✅ -> is upload necessary?
            // ❌ -> return()

        // Upload Config
            // ✅ -> download config file
            // ❌ -> throw error

            // ✅ -> upload config file : sdk.loadCongfig()
            // ❌ -> throw error

            // ✅ -> return()
    }

    // MARK: - Private methods
    
}
