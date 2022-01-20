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


internal enum GlassesUpdaterError: Error {
    case glassesUpdater(message: String = "")   // Used for development? LET'S TRY...
}

internal class GlassesUpdater {


    // MARK: - Private properties

    private var glasses: Glasses?

    private var updateParameters: GlassesUpdateParameters

    private var softwareVersionCheckResult: VersionCheckResult? = nil {
        didSet {
            guard let swVCR = softwareVersionCheckResult else {
                return
            }

            self.process(swVCR)
        }
    }

    // MARK: - Life cycle

    init(with parameters: GlassesUpdateParameters) {

        self.updateParameters = parameters
    }

    deinit {
        self.glasses = nil
        self.softwareVersionCheckResult = nil
    }


    // MARK: - Internal methods

    public func update(glasses: Glasses) {

        guard let glasses = self.glasses else {
            failed(with: GlassesUpdaterError.glassesUpdater(message: "GLASSES MUST BE SET"))
            return
        }

        self.glasses = glasses

        updateParameters.onUpdateStartCallback()    // TODO: Implement with UpdateProgress

        // Start update process
        self.checkFirmwareRecency()
    }


    // MARK: - Private methods

    private func failed(with error: Error) {
        print(error)

        updateParameters.onUpdateFailureCallback() // TODO: Implement with UpdateProgress
    }


    private func process(_ versCheckResult: VersionCheckResult) {

        updateParameters.onUpdateProgressCallback() // TODO: Implement with UpdateProgress

        switch versCheckResult.software
        {
        case .firmware :
            processFirmwareResponse( versCheckResult.status )

        case .configuration :
            processConfigurationResponse( versCheckResult.status )
        }
    }


    // MARK: Firmware Methods

    private func checkFirmwareRecency() {

        updateParameters.onUpdateProgressCallback() // TODO: Implement with UpdateProgress

        let versionChecker = VersionChecker(for: glasses!)

        versionChecker.isFirmwareUpToDate(
            onSuccess: { (result) in self.process( result ) },
            onError: { (error) in self.failed(with: error ) })
    }


    private func processFirmwareResponse(_ status: VersionStatus ) {

        updateParameters.onUpdateProgressCallback() // TODO: Implement with UpdateProgress

        print("STATUS: \(status)")
        return
        
        switch status
        {
        case .needsUpdate(let apiURL):
            let downloader = Downloader()

            updateParameters.onUpdateProgressCallback() // TODO: Implement with UpdateProgress

            downloader.downloadFile(at: apiURL,
                                    onSuccess: { ( data ) in self.updateFirmware( with: Firmware( with: data )) },
                                    onError: { ( error ) in self.failed(with: error ) })

        case .isUpToDate:
            checkConfigurationRecency()
        }
    }

    private func updateFirmware(with firmware: Firmware) {


        updateParameters.onUpdateProgressCallback() // TODO: Implement with UpdateProgress

        let firmwareUpdater = FirmwareUpdater()

        guard let glasses = glasses else {
            failed(with: GlassesUpdaterError.glassesUpdater(message: "Glasses MUST NOT be nil"))
            return
        }
        firmwareUpdater.update(glasses, with: firmware, onSuccess: { self.checkConfigurationRecency() },
                               onProgress: { updateProgress in self.updateParameters.onUpdateProgressCallback() },
                               onError: { error in self.failed(with: error )} )
    }


    // MARK: Configuration Methods

    private func checkConfigurationRecency() {
        print("FIRMWARE IS UPTODATE, NOW ON CONFIGURATION...")


        //updateParameters.onUpdateProgressCallback() // TODO: Implement with UpdateProgress
    }

    private func processConfigurationResponse(_ status: VersionStatus ) {

        updateParameters.onUpdateProgressCallback() // TODO: Implement with UpdateProgress

        switch status {
        case .needsUpdate(let apiURL):
//            let downloader = Downloader()


            updateParameters.onUpdateProgressCallback() // TODO: Implement with UpdateProgress

            // TODO: IMPLEMENT CONFIGURATION DOWNLOADER
//            downloader.downloadFirmware(at: apiUrl,
//                                        onSuccess: { { data } in self.updateFirmware( with: Firmware( with: data )) },
//                                        onError: { ( error ) in self.failed(with: error ) })
        case .isUpToDate:
            updateParameters.onUpdateSuccessCallback() // TODO: Implement with UpdateProgress
        }
    }

}
