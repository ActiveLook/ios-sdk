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

internal enum VersionStatus {
    case needsUpdate( apiURL: URL )
    case isUpToDate
}


// MARK: - Internal Strutures

internal struct VersionCheckResult {
    let software: SoftwareClass
    let status: VersionStatus
}


// MARK: - FilePrivate Structures

fileprivate struct Latest: Codable {
    let api_path: String
    let version: [Int]
}


fileprivate struct FirmwareJSON: Codable {
    let latest: Latest
}


internal enum VersionCheckError: Error {
    case versionCheckerError(message: String)
}


// MARK: - Definition

// The `VersionChecker` class checks if the glasses' softwares are up-to-date.
internal final class VersionChecker: NSObject, CBPeripheralDelegate {


    // MARK: - Private Variables
    private var glasses: Glasses

    private var urlGenerator: GlassesUpdaterURL

    private var checkVersionSuccessClosure: (( VersionCheckResult ) -> (Void))?
    private var checkVersionErrorClosure: (( VersionCheckError ) -> (Void))?

    private let checkVersionTimeoutDuration: TimeInterval = 5
    private var checkVersionTimeoutTimer: Timer?

    private var serialNumberCharateristic: CBCharacteristic?
    private var hardwareVersionCharateristic: CBCharacteristic?
    private var firmwareVersionCharateristic: CBCharacteristic?
    private var softwareVersionCharateristic: CBCharacteristic?

    private var serialNumberDescriptor: CBDescriptor?
    private var hardwareVersionDescriptor: CBDescriptor?
    private var firmwareVersionDescriptor: CBDescriptor?
    private var softwareVersionDescriptor: CBDescriptor?

    private var glassesFWVersion: FirmwareVersion? {
        didSet {
            self.fetchRemoteFirmwareVersion()
        }
    }

    private var remoteFWVersion: FirmwareVersion? {
        didSet {
            self.compareFWVersions()
        }
    }

    private var result: VersionCheckResult? {
        didSet {
            self.isDone()
        }
    }


    // MARK: - Initializers
    
    init(for glasses: Glasses) {
        self.glasses = glasses
        self.urlGenerator = GlassesUpdaterURL.shared()
    }


    // MARK: - Life-Cycle
    
    private func cleanUp() {
        self.checkVersionSuccessClosure = nil
        self.checkVersionErrorClosure = nil
        self.checkVersionTimeoutTimer?.invalidate()
        self.glasses.peripheral.delegate = self.glasses.peripheralDelegate
    }


    // MARK: - Internal Methods

    public func isFirmwareUpToDate(onSuccess successClosure: @escaping ( VersionCheckResult ) -> (Void),
                                   onError errorClosure: @escaping ( VersionCheckError ) -> (Void)) {

        // We're setting ourselves as the peripheral delegate in order to complete the  process.
        // When the process is done, we'll set the original delegate back
        self.glasses.peripheral.delegate = self
        self.checkVersionSuccessClosure = successClosure
        self.checkVersionErrorClosure = errorClosure
        print("checking firmware versions")

        // 1st : retrieve informations from device
        self.glasses.peripheral.discoverServices([CBUUID.DeviceInformationService])

        // We're failing after an arbitrary timeout duration
        checkVersionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: checkVersionTimeoutDuration, repeats: false) { _ in
            self.failed( withError: VersionCheckError.versionCheckerError( message: "connectionTimeoutError") )
        }
    }

    #warning("isConfigurationUpToDate TODO later")
//    internal func isConfigurationUpToDate() -> VersionCheckResult {
//    }


    // MARK: - Private Methods

    private func isDone() {
        checkVersionSuccessClosure?(self.result!)

        cleanUp()
    }


    private func failed(withError error: VersionCheckError) {
        checkVersionErrorClosure?(error)

        cleanUp()
    }


    private func fetchRemoteFirmwareVersion() {

        guard let gfw = glassesFWVersion else {
            failed(withError: VersionCheckError.versionCheckerError(message: "Glasses FW Version Unavailable"))
            return
        }

        // format URL string
        let url = urlGenerator.firmwareHistoryURL(for: gfw)

        let remoteFirmwareVersion: FirmwareVersion

        let task = URLSession.shared.dataTask( with: url ) { data, response, error in
            guard error == nil else {
                // Client error
                self.failed( withError: VersionCheckError.versionCheckerError( message: "Client error" ))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                      // Server error
                      self.failed( withError: VersionCheckError.versionCheckerError( message: "Server error" ))
                      return
                  }

            guard let data = data else {
                self.failed( withError: VersionCheckError.versionCheckerError( message: "Retrieved data is nil" ))
                return
            }

            guard let decodedData = try? JSONDecoder().decode( FirmwareJSON.self, from: data ) else {
                self.failed( withError: VersionCheckError.versionCheckerError(
                    message: "JSON decoding error: \(String(describing: error))"))
                return
            }

            let vers = decodedData.latest.version
            let apiPath = decodedData.latest.api_path
            
            DispatchQueue.main.async {
                self.remoteFWVersion = FirmwareVersion(major: vers[0],
                                                       minor: vers[1],
                                                       patch: vers[2],
                                                       extra: "",
                                                       path: apiPath)
            }

        }
        task.resume()
    }


    private func compareFWVersions() {
        guard let rfw = remoteFWVersion,
              let gfw = glassesFWVersion else {
                  failed( withError: VersionCheckError.versionCheckerError(
                    message: "compareFWVersions: rfw or gfw NOT SET"))
                  return
              }

        if rfw > gfw {
            guard let apiPath = rfw.path else {
                failed(withError: VersionCheckError.versionCheckerError(
                    message: "remote FW path not set"))
                return
            }
            let apiURL = urlGenerator.firmwareDownloadURL(using: apiPath)
            self.result = VersionCheckResult( software: .firmware, status: .needsUpdate(apiURL: apiURL) )
            print("NEED TO UPDATE!!!")
        } else {
            self.result = VersionCheckResult( software: .firmware, status: .isUpToDate )
            print("FIRMWARE UP-TO-DATE")
        }
    }

    
    // MARK: - CBPeripheralDelegate

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("error while discovering services: ", error!)
            failed( withError: error as! VersionCheckError )
            return
        }

        guard let services = peripheral.services else {
            let message = "no services discovered for peripheral: \(peripheral)"
            failed( withError: VersionCheckError.versionCheckerError(message: message) )
            return
        }

        for service in services {
            print("discovered service: \(service.uuid)")
            switch service.uuid {

            case CBUUID.ActiveLookCommandsInterfaceService :
                peripheral.discoverCharacteristics(CBUUID.ActiveLookCharacteristicsUUIDS, for: service)

            case CBUUID.BatteryService :
                peripheral.discoverCharacteristics([CBUUID.BatteryLevelCharacteristic], for: service)

            case CBUUID.DeviceInformationService :
                peripheral.discoverCharacteristics(CBUUID.DeviceInformationCharacteristicsUUIDs, for: service)

            default:
                // print("discovered unknown service: \(service.uuid)")
                break
            }
        }
    }

    
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?) {
        guard error == nil else {
            print("error while discovering characteristics: ", error!, ", for service: ", service)
            failed( withError: error as! VersionCheckError)
            return
        }

        guard service.characteristics != nil else {
            let message = "no characteristics found for service: \(service)"
            failed(withError: VersionCheckError.versionCheckerError(message: message))
            return
        }

        for characteristic in service.characteristics!
        {
            switch characteristic.uuid
            {
            case CBUUID.FirmwareVersionCharateristic:
                firmwareVersionCharateristic = characteristic

                // format Glasses FirmwareVersion
                guard let data = characteristic.value else {
                    failed( withError: VersionCheckError.versionCheckerError(
                        message: "No FW version retrieved"))
                    return
                }
                guard data.count >= 9 else {
                    failed( withError: VersionCheckError.versionCheckerError(
                        message: "Unexpected Firmware Version Format"))
                    return
                }

                let major = Int(data[0])
                let minor = Int(data[1])
                let patch = Int(data[2])

                self.glassesFWVersion = FirmwareVersion(major: major,
                                                        minor: minor,
                                                        patch: patch,
                                                        extra: nil, path: nil, error: nil)

            default:
                break
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverDescriptorsFor characteristic: CBCharacteristic,
                           error: Error?) {

//        switch characteristic.uuid {
//        case CBUUID.BatteryLevelCharacteristic:
//            batteryLevelDescriptor = characteristic.descriptors?.first
//
//        case CBUUID.SerialNumberCharateristic:
//            serialNumberCharateristic = characteristic.descriptors?.first
//
//        case CBUUID.HardwareVersionCharateristic:
//            hardwareVersionCharateristic = characteristic.descriptors?.first
//
//        case CBUUID.FirmwareVersionCharateristic:
//            firmwareVersionCharateristic = characteristic.descriptors?.first
//
//
//        case CBUUID.SoftwareVersionCharateristic:
//            softwareVersionCharateristic = characteristic.descriptors?.first
//
//        default:
//            break
//        }
    }

    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        //        print("peripheral did update value for characteristic: ", characteristic.uuid)
    }
}


