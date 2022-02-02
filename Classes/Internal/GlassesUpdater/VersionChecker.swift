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


// MARK: - Definition

// The `VersionChecker` class checks if the glasses' softwares are up-to-date.
internal final class VersionChecker: NSObject {


    // MARK: - Private Variables
    private var glasses: Glasses?
    private var peripheral: CBPeripheral?

    private var urlGenerator: GlassesUpdaterURL

    private var successClosure: (( VersionCheckResult ) -> (Void))?
    private var errorClosure: (( GlassesUpdateError ) -> (Void))?

    private let timeoutDuration: TimeInterval = 5
    private var timeoutTimer: Timer?


    private var glassesFWVersion: FirmwareVersion? {
        didSet {
            if glassesFWVersion != nil {
                self.fetchRemoteFirmwareVersion()
            }
        }
    }

    private var remoteFWVersion: FirmwareVersion? {
        didSet {
            if remoteFWVersion != nil {
                self.compareFWVersions()
            }
        }
    }


/* TODO: STEPS IN TESTING LIKE IN TDD
    1. Install without making any changes
    2. Make necessary changes
    3. Refactor !!!!! (but last step!) */


    private var result: VersionCheckResult? {
        didSet {
            self.versionChecked()
        }
    }


    // MARK: - Initializers
    
    override init() {
        urlGenerator = GlassesUpdaterURL()
        super.init()
    }


    // MARK: - Life-Cycle
    
    private func cleanUp() {
        self.successClosure = nil
        self.errorClosure = nil
        self.timeoutTimer?.invalidate()
    }


    // MARK: - Internal Methods

    internal func isFirmwareUpToDate(for glasses: Glasses,
                                     onSuccess successClosure: @escaping ( VersionCheckResult ) -> (Void),
                                     onError errorClosure: @escaping ( GlassesUpdateError ) -> (Void)) {

        self.peripheral = glasses.peripheral
        self.glasses = glasses

        self.urlGenerator = GlassesUpdaterURL.shared()
        self.successClosure = successClosure
        self.errorClosure = errorClosure

        readDeviceFWVersion()
    }

    #warning("isConfigurationUpToDate TODO later")
//    internal func isConfigurationUpToDate() -> VersionCheckResult {
//    }


    // MARK: - Private Methods

    private func versionChecked() {
        guard let result = result else {
            failed(with: GlassesUpdateError.versionChecker(
                message: String(format: "Result NOT set @", #line)))
            return
        }

        successClosure?(result)
        cleanUp()
    }


    private func failed(with error: GlassesUpdateError) {
        errorClosure?( error )
        cleanUp()
    }


    private func fetchRemoteFirmwareVersion() {

        guard let gfw = glassesFWVersion else {

            failed(with: GlassesUpdateError.versionChecker(
                message: String(format: "Glasses FW Version unavailable @", #line)))
            return
        }

        // format URL string
        let url = urlGenerator.firmwareHistoryURL(for: gfw)

        let task = URLSession.shared.dataTask( with: url ) { data, response, error in
            guard error == nil else {
                // Client error
                self.failed(with: GlassesUpdateError.versionChecker(
                    message: String(format: "Client error @", #line)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                // Server error
                self.failed(with: GlassesUpdateError.versionChecker(
                    message: String(format: "Server error @", #line)))
                return
            }

            guard let data = data else {
                self.failed(with: GlassesUpdateError.versionChecker(
                    message: String(format: "Retrieved data is nil @", #line)))
                return
            }

            guard let decodedData = try? JSONDecoder().decode( FirmwareJSON.self, from: data ) else {
                self.failed(with: GlassesUpdateError.versionChecker(
                    message: String(format: "JSON decoding error: \(String(describing: error)) @", #line)))
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
                  failed(with: GlassesUpdateError.versionChecker(
                    message: String(format: "compareFWVersions: rfw or gfw NOT SET @", #line)))
                  return
              }

//        if rfw > gfw {
        if true {
            // need to update
            guard let apiPath = rfw.path else {
                failed(with: GlassesUpdateError.versionChecker(
                    message: String(format: "remote FW path NOT SET @", #line)))
                return
            }
            let apiURL = urlGenerator.firmwareDownloadURL(using: apiPath)
            result = VersionCheckResult( software: .firmware, status: .needsUpdate(apiURL: apiURL) )
        } else {
            // up-to-date
            self.result = VersionCheckResult( software: .firmware, status: .isUpToDate )
            print("FIRMWARE UP-TO-DATE")
        }
    }

    private func readDeviceFWVersion() {

        glasses?.peripheral.discoverServices( [CBUUID.DeviceInformationService])

        guard let di = glasses?.peripheral.getService(withUUID: CBUUID.DeviceInformationService) else {
            failed(with: GlassesUpdateError.versionChecker(
                message: String(format: "DeviceInformationService Unavailable @", #line)))
            return
        }

        guard let characteristic = di.getCharacteristic(forUUID: CBUUID.FirmwareVersionCharateristic) else {
                failed(with: GlassesUpdateError.versionChecker(
                    message: String(format: "firmwareVersionCharateristic NOT SET @", #line)))
            return
        }

        let fwString = characteristic.valueAsUTF8

        let components = fwString.components(
            separatedBy: .decimalDigits.inverted).filter(
                { $0 != "" }).map({
                    Int($0) })

        let major = Int(components[0] ?? 0)
        let minor = Int(components[1] ?? 0)
        let patch = Int(components[2] ?? 0)

        glassesFWVersion = FirmwareVersion(major: major,
                                                minor: minor,
                                                patch: patch,
                                                extra: nil, path: nil, error: nil)
    }

}

// MARK: - PeripheralDelegate

extension VersionChecker: CBPeripheralDelegate {


    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

    }
}

/*
// MARK: - Internal Structures

internal enum GlassesInitializerError: Error {
    case glassesInitializer(message: String)
}

// MARK: - Class `GlassesInitializer` definition

internal class GlassesInitializer: NSObject, CBPeripheralDelegate {


    // MARK: - Private properties

#warning("SET TIMEOUT BACK TO 5")   // Add pause method to invoke if FW update ?
    private let initTimeoutDuration: TimeInterval = 2000 // 5
    private let initPollInterval: TimeInterval = 0.2

    private lazy var updateParameters: GlassesUpdateParameters = {
        return updateParameters
    }()

    private lazy var glasses: Glasses = {
        return glasses
    }()

    private var initSuccessClosure: (() -> (Void))?
    private var initErrorClosure: ((Error) -> (Void))?
    private var initTimeoutTimer: Timer?
    private var initPollTimer: Timer?

    private var spotaService: CBService?

    private var batteryLevelCharacteristic: CBCharacteristic?
    private var txCharacteristic: CBCharacteristic?
    private var rxCharacteristic: CBCharacteristic?
    private var flowControlCharacteristic: CBCharacteristic?
    private var sensorInterfaceCharacteristic: CBCharacteristic?

    internal var glassesAreUpToDate: Bool = false {
        didSet {
            print("glassesAreUpToDate: %b", glassesAreUpToDate)
            glassesAreUpToDate ? updateParameters.state = .DONE : print("glasses not up to date =(")
        }
    }


    // MARK: - Life cycle

    override init() {
        super.init()

        guard let sdk = try? ActiveLookSDK.shared() else {
            fatalError(String(format: "SDK Singleton NOT AVAILABLE @  %i", #line))
        }

        updateParameters = sdk.updateParameters
    }


    // MARK: - Private methods

    private func updateGlasse() {

        let updater = GlassesUpdater()

        //        updater.update(glasses,
        //                       onSuccess: { result in self.glassesAreUpToDate = result},
        //                       onError: { error in self.failed(with: error)})
    }

    private func isReady() -> Bool {
        if glasses.peripheral.state != .connected {
            return false
        }

        let di = glasses.getDeviceInformation()

        let requiredProperties: [Any?] = [
            spotaService, rxCharacteristic, txCharacteristic, batteryLevelCharacteristic,
            flowControlCharacteristic, sensorInterfaceCharacteristic, di.manufacturerName, di.modelNumber,
            di.serialNumber, di.hardwareVersion, di.firmwareVersion, di.softwareVersion
        ]

        for prop in requiredProperties {
            if prop == nil {
                return false
            }
        }

        if !txCharacteristic!.isNotifying { return false }

        if !flowControlCharacteristic!.isNotifying { return false }

        if updateParameters.state != .updating {
            updateParameters.state = .retrievedDeviceInformations
        }

        if !glassesAreUpToDate
            && updateParameters.state == .retrievedDeviceInformations
        {
            updateGlasse()
            updateParameters.state = .updating
            return false
        }

        if updateParameters.state == .updating {
            return false
        }

        return true
    }


    private func isDone() {
        self.initSuccessClosure?()
        self.initSuccessClosure = nil

        self.initTimeoutTimer?.invalidate()

        self.glasses.resetPeripheralDelegate()
    }


    private func failed(with error: GlassesInitializerError ) {

        print(error)

        self.initErrorClosure?(ActiveLookError.connectionTimeoutError)
        self.initErrorClosure = nil

        self.initPollTimer?.invalidate()

        self.glasses.resetPeripheralDelegate()
    }


    // MARK: - Internal methods

    func initialize(_ glasses: Glasses,
                    onSuccess successClosure: @escaping () -> (Void),
                    onError errorClosure: @escaping (Error) -> (Void)) {

        self.glasses = glasses

        // We're setting ourselves as the peripheral delegate in order to complete the init process.
        // When the process is done, we'll set the original delegate back
        glasses.peripheral.delegate = self

        initSuccessClosure = successClosure
        initErrorClosure = errorClosure

        print("initializing glasses")

        glasses.peripheral.discoverServices([CBUUID.DeviceInformationService,
                                             CBUUID.BatteryService,
                                             CBUUID.ActiveLookCommandsInterfaceService,
                                             CBUUID.SpotaService])

        // We're 'polling', or checking regularly that we've received all needed information about the glasses
        initPollTimer = Timer.scheduledTimer(withTimeInterval: initPollInterval, repeats: true) { (timer) in
            if self.isReady() {
                self.isDone()
                timer.invalidate()
            }
        }

        // We're failing after an arbitrary timeout duration
        initTimeoutTimer = Timer.scheduledTimer(withTimeInterval: initTimeoutDuration, repeats: false) { _ in
            self.failed(with: GlassesInitializerError.glassesInitializer(
                message: String(format: "connectionTimeoutError: ", #line)))
        }
    }


    // MARK: - CBPeripheralDelegate

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        guard error == nil else {
            failed(with: GlassesInitializerError.glassesInitializer(
                message: String(format: "error while discovering services: ", error.debugDescription)))
            return
        }

        guard let services = peripheral.services else {
            failed(with: GlassesInitializerError.glassesInitializer(
                message: String(format: "no services discovered for peripheral: ", peripheral )))
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

            case CBUUID.SpotaService :
                spotaService = service
                peripheral.discoverCharacteristics(nil, for: service)

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
            failed(with: GlassesInitializerError.glassesInitializer(
                message: String(format: "error while discovering characteristics: ", error.debugDescription,
                                ", for service: ", service, "@ ", #line)))
            return
        }

        guard let characteristics = service.characteristics else {
            failed(with: GlassesInitializerError.glassesInitializer(
                message: String(format: "error while discovering characteristics: ", error.debugDescription,
                                ", for service: ", service, "@ ", #line)))
            return
        }


        switch service.uuid {
        case CBUUID.DeviceInformationService :
            service.characteristics?.forEach({
                peripheral.readValue(for: $0)
            })

        case CBUUID.SpotaService :
            for characteristic in characteristics {
                switch characteristic.uuid {
                case CBUUID.SPOTA_SERV_STATUS_UUID:
                    print("setting NOTIFY TRUE for SPOTA_SERV_STATUS_UUID")
                    peripheral.setNotifyValue(true, for: characteristic)

                case CBUUID.SUOTA_VERSION_UUID :
                    print("discovered SUOTA_VERSION_UUID characteristic")
                    peripheral.readValue(for: characteristic)

                case CBUUID.SUOTA_PATCH_DATA_CHAR_SIZE_UUID :
                    print("discovered SUOTA_PATCH_DATA_CHAR_SIZE_UUID characteristic")
                    peripheral.readValue(for: characteristic)

                default:
                    peripheral.readValue(for: characteristic)
                }
            }

        default :
            break
        }

        for characteristic in characteristics
        {
            switch characteristic.uuid
            {
            case CBUUID.ActiveLookRxCharacteristic:
                rxCharacteristic = characteristic

            case CBUUID.ActiveLookTxCharacteristic:
                txCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)

            case CBUUID.BatteryLevelCharacteristic:
                batteryLevelCharacteristic = characteristic

            case CBUUID.ActiveLookFlowControlCharacteristic:
                flowControlCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)

            case CBUUID.ActiveLookSensorInterfaceCharacteristic:
                sensorInterfaceCharacteristic = characteristic

            default:
                break
            }

            self.glasses.peripheral.discoverDescriptors(for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?)
    {
        guard error == nil else {
            failed(with: GlassesInitializerError.glassesInitializer(
                message: String(format: "error reading value for characteristics", error.debugDescription,
                                ", for characteristic: ", characteristic, "@ ", #line)))
            return
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverDescriptorsFor characteristic: CBCharacteristic,
                    error: Error?)
    {
        guard error == nil else {
            failed(with: GlassesInitializerError.glassesInitializer(
                message: String(format: "error discovering descriptors for characteristics",
                                error.debugDescription, ", for characteristic: ", characteristic, "@ ", #line)))
            return
        }
    }
}
*/
