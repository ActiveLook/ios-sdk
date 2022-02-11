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

// MARK: - Internal Enumerations

internal enum GlassesUpdateError: Error {
    case glassesUpdater(message: String = "")   // 0
    case versionChecker(message: String = "")   // 1
    case versionCheckerNoUpdateAvailable       // 2
    case downloader(message: String = "")       // 3
    case downloaderClientError                  // 4
    case downloaderServerError                  // 5
    case downloaderJsonError                    // 6
    case firmwareUpdater(message: String = "")  // 7
}


// MARK: -
internal class GlassesUpdater {


    // MARK: - Private properties

    private var sdk: ActiveLookSDK?

    private var updateParameters: GlassesUpdateParameters?

    private var glasses: Glasses?

    private lazy var successClosure: () -> () = {
        return successClosure
    }()

    private lazy var errorClosure: () -> () = {
        return errorClosure
    }()

    private var firmwareUpdater: FirmwareUpdater?


    // MARK: - Life cycle

    init() {
        guard let sdk = try? ActiveLookSDK.shared() else {
            fatalError(String(format: "SDK Singleton NOT AVAILABLE @  %i", #line))
        }

        self.sdk = sdk
    }


    // MARK: - Internal methods

    func update(_ glasses: Glasses,
                onSuccess successClosure: @escaping () -> (),
                onError errorClosure: @escaping () -> () ) {

        self.glasses = glasses
        self.successClosure = successClosure
        self.errorClosure = errorClosure

        updateParameters?.state = .startingUpdate

        // Start update process
        self.checkFirmwareRecency()

        sdk?.updateParameters.state = .startingUpdate
    }


    // MARK: - Private methods

    private func failed(with error: GlassesUpdateError) {
        dlog(message: error.localizedDescription, line: #line, function: #function, file: #fileID)

        sdk?.updateParameters.state = .updateFailed

        errorClosure()
    }


    private func process(_ versCheckResult: VersionCheckResult) {

        sdk?.updateParameters.state = .checkingFwVersion

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

        dlog(message: "",line: #line, function: #function, file: #fileID)

        sdk?.updateParameters.state = .checkingFwVersion

        let versionChecker = VersionChecker()

        versionChecker.isFirmwareUpToDate(for: glasses!,
                                             onSuccess: { ( result ) in self.process( result ) },
                                             onError: { ( error ) in self.failed(with: error ) })
    }


    private func processFirmwareResponse(_ status: VersionStatus ) {

        dlog(message: "",line: #line, function: #function, file: #fileID)

        switch status
        {
        case .needsUpdate(let apiURL):

            let downloader = Downloader()
            downloader.downloadFile(at: apiURL,
                                    onSuccess: { ( data ) in self.updateFirmware( with: Firmware( with: data )) },
                                    onError: { ( error ) in self.failed(with: error ) })

        case .isUpToDate, .noUpdateAvailable:
            checkConfigurationRecency()
        }
    }

    private func updateFirmware(with firmware: Firmware) {

        dlog(message: firmware.description(), line: #line, function: #function, file: #fileID)

        sdk?.updateParameters.state = .updatingFw

        firmwareUpdater = FirmwareUpdater(onSuccess: { self.checkConfigurationRecency() },
                                        onError: { error in self.failed(with: error) })

        firmwareUpdater?.update(glasses!, with: firmware)

    }


    // MARK: Configuration Methods

    private func checkConfigurationRecency() {

        dlog(message: "",line: #line, function: #function, file: #fileID)

        // TODO: FOR NOW...
        sdk?.updateParameters.state = .updateDone
        successClosure()
        // ---------------

        sdk?.updateParameters.state = .checkingConfigVersion
        return

    }

    private func processConfigurationResponse(_ status: VersionStatus ) {


        switch status {
        case .needsUpdate(let apiURL):
//            let downloader = Downloader()

            sdk?.updateParameters.state = .updatingConfig

            updateParameters?.progressClosure() // TODO: Implement with UpdateProgress

            // TODO: IMPLEMENT CONFIGURATION DOWNLOADER
//            downloader.downloadFirmware(at: apiUrl,
//                                        onSuccess: { { data } in self.updateFirmware( with: Firmware( with: data )) },
//                                        onError: { ( error ) in self.failed(with: error ) })
        case .isUpToDate, .noUpdateAvailable:
            updateParameters?.progressClosure() // TODO: Implement with UpdateProgress
            
        }
    }
}
