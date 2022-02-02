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
import CoreText

// MARK: - Internal Structures


// MARK: - Internal Enumerations

internal enum GlassesUpdateError: Error {
    case glassesUpdater(message: String = "")
    case versionChecker(message: String = "")
    case downloader(message: String = "")
    case firmwareUpdater(message: String = "")
}


// MARK: - Class `GlassesUpdater` definition

internal class GlassesUpdater {


    // MARK: - Private properties

    private var updateParameters: GlassesUpdateParameters?

    private var glasses: Glasses?

    private lazy var successClosure: ( Bool ) -> () = {
        return successClosure
    }()

    private lazy var errorClosure: ( GlassesUpdateError ) -> () = {
        return errorClosure
    }()


    // MARK: - Life cycle

    init() {
        guard let sdk = try? ActiveLookSDK.shared() else {
            fatalError(String(format: "SDK Singleton NOT AVAILABLE @  %i", #line))
        }

        self.updateParameters = sdk.updateParameters
    }


    // MARK: - Internal methods

    func update(_ glasses: Glasses,
                onSuccess successClosure: @escaping ( Bool ) -> (),
                onError errorClosure: @escaping ( GlassesUpdateError ) -> ( Void) ) {

        self.glasses = glasses
        self.successClosure = successClosure
        self.errorClosure = errorClosure

        updateParameters?.progressClosure()    // TODO: Implement with UpdateProgress

        // Start update process
        self.checkFirmwareRecency()
    }


    // MARK: - Private methods

    private func failed(with error: GlassesUpdateError) {

        print(error)

        errorClosure( error )
    }


    private func process(_ versCheckResult: VersionCheckResult) {

        updateParameters?.progressClosure() // TODO: Implement with UpdateProgress

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

        updateParameters?.progressClosure() // TODO: Implement with UpdateProgress

        let versionChecker = VersionChecker()

        versionChecker.isFirmwareUpToDate(for: glasses!,
                                             onSuccess: { ( result ) in self.process( result ) },
                                             onError: { ( error ) in self.failed(with: error ) })
    }


    private func processFirmwareResponse(_ status: VersionStatus ) {

        updateParameters?.progressClosure() // TODO: Implement with UpdateProgress

        switch status
        {
        case .needsUpdate(let apiURL):
            let downloader = Downloader()

            updateParameters?.progressClosure() // TODO: Implement with UpdateProgress

            downloader.downloadFile(at: apiURL,
                                    onSuccess: { ( data ) in self.updateFirmware( with: Firmware( with: data )) },
                                    onError: { ( error ) in self.failed(with: error ) })

        case .isUpToDate:
            checkConfigurationRecency()
        }
    }

    private func updateFirmware(with firmware: Firmware) {

        updateParameters?.progressClosure() // TODO: Implement with UpdateProgress

        let fwUpdater = FirmwareUpdater(onSuccess: { self.checkConfigurationRecency() },
                                        onError: { error in self.failed(with: error) })

        fwUpdater.update(glasses!, with: firmware)

//        self.successClosure( true )
    }


    // MARK: Configuration Methods

    private func checkConfigurationRecency() {
        print("FIRMWARE IS UPTODATE, NOW ON CONFIGURATION...")


        //updateParameters.onUpdateProgressCallback() // TODO: Implement with UpdateProgress
    }

    private func processConfigurationResponse(_ status: VersionStatus ) {

        updateParameters?.progressClosure() // TODO: Implement with UpdateProgress

        switch status {
        case .needsUpdate(let apiURL):
//            let downloader = Downloader()


            updateParameters?.progressClosure() // TODO: Implement with UpdateProgress

            // TODO: IMPLEMENT CONFIGURATION DOWNLOADER
//            downloader.downloadFirmware(at: apiUrl,
//                                        onSuccess: { { data } in self.updateFirmware( with: Firmware( with: data )) },
//                                        onError: { ( error ) in self.failed(with: error ) })
        case .isUpToDate:
            updateParameters?.progressClosure() // TODO: Implement with UpdateProgress
        }
    }
}
