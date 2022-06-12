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


// MARK: - Internal Structures

internal enum GlassesInitializerError: Error {
    case glassesInitializer(message: String)
}


// MARK: - Definition

internal class GlassesInitializer: NSObject, CBPeripheralDelegate {


    // MARK: - Private properties

    private let initTimeoutDuration: TimeInterval = 2 // 5
    private let initPollInterval: TimeInterval = 0.2

    private var updateParameters: GlassesUpdateParameters?

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

    private var deviceNameCharacteristic: CBCharacteristic?

    // MARK: - Life cycle

    override init()
    {
        super.init()
        
        guard let sdk = try? ActiveLookSDK.shared() else {
            fatalError(String(format: "SDK Singleton NOT AVAILABLE @  %i", #line))
        }

        updateParameters = sdk.updateParameters
    }


    // MARK: - Private methods

    private func isReady() -> Bool
    {
        if glasses.peripheral.state != .connected {
            return false
        }

        let di = glasses.getDeviceInformation()

        let requiredProperties: [Any?] = [
            rxCharacteristic, txCharacteristic, batteryLevelCharacteristic,
            flowControlCharacteristic, sensorInterfaceCharacteristic, di.manufacturerName, di.modelNumber,
            di.serialNumber, di.hardwareVersion, di.firmwareVersion, di.softwareVersion
        ]

        for prop in requiredProperties {
            if prop == nil {
                return false
            }
        }
        
        updateParameters?.hardware = di.hardwareVersion!

        if !txCharacteristic!.isNotifying { return false }

        if !flowControlCharacteristic!.isNotifying { return false }

        if !batteryLevelCharacteristic!.isNotifying { return false }

        return true
    }


    private func isDone()
    {
        self.initSuccessClosure?()
        self.initSuccessClosure = nil

        self.initTimeoutTimer?.invalidate()

        self.glasses.resetPeripheralDelegate()
    }


    private func failed(with error: GlassesInitializerError )
    {
        self.initErrorClosure?(ActiveLookError.connectionTimeoutError)
        self.initErrorClosure = nil

        self.initPollTimer?.invalidate()

        self.glasses.resetPeripheralDelegate()
    }

    
    // MARK: - Internal methods

    func initialize(_ glasses: Glasses,
                    onSuccess successClosure: @escaping () -> (Void),
                    onError errorClosure: @escaping (Error) -> (Void))
    {

        self.glasses = glasses

        // We're setting ourselves as the peripheral delegate in order to complete the init process.
        // When the process is done, we'll set the original delegate back in `isDone()`
        glasses.setPeripheralDelegate(to: self)

        initSuccessClosure = successClosure
        initErrorClosure = errorClosure
        
        print("initializing glasses")

        glasses.peripheral.discoverServices([CBUUID.DeviceInformationService,
                                             CBUUID.BatteryService,
                                             CBUUID.ActiveLookCommandsInterfaceService])

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

    // TODO: make delegate react to battery level notifications ???
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
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

            default:
                // print("discovered unknown service: \(service.uuid)")
                break
            }
        }
    }


    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?)
    {
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
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)

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

    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateNotificationStateFor characteristic: CBCharacteristic,
                           error: Error?)
    {
        guard error == nil else {
            let desc = error!.localizedDescription
            print("error while updating notification state : \(desc) for characteristic: \(characteristic.uuid)")
            return
        }
//        print("peripheral did update notification state for characteristic: \(characteristic) in: \(#fileID)")
    }
}
