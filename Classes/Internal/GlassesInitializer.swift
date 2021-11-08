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

class GlassesInitializer: NSObject, CBPeripheralDelegate {
    
    
    // MARK: - Private properties
    
    private let initTimeoutDuration: TimeInterval = 5
    private let initPollInterval: TimeInterval = 0.2
    
    private var glasses: Glasses
    
    private var initSuccessClosure: (() -> (Void))?
    private var initErrorClosure: ((Error) -> (Void))?
    private var initTimeoutTimer: Timer?
    private var initPollTimer: Timer?
    
    private var batteryLevelCharacteristic: CBCharacteristic?
    private var txCharacteristic: CBCharacteristic?
    private var rxCharacteristic: CBCharacteristic?
    private var flowControlCharacteristic: CBCharacteristic?
    private var sensorInterfaceCharacteristic: CBCharacteristic?
    

    // MARK: - Life cycle

    init(glasses: Glasses) {
        self.glasses = glasses
    }
    
    
    // MARK: - Private methods
    
    private func isReady() -> Bool {
        if (glasses.peripheral.state != .connected) {
            return false
        }
        
        let di = glasses.getDeviceInformation()
        
        let requiredProperties: [Any?] = [
            rxCharacteristic, txCharacteristic, batteryLevelCharacteristic, flowControlCharacteristic, sensorInterfaceCharacteristic,
            di.manufacturerName, di.modelNumber, di.serialNumber, di.hardwareVersion, di.firmwareVersion, di.softwareVersion
        ]
        
        for prop in requiredProperties {
            if prop == nil { return false }
        }
        
        if !txCharacteristic!.isNotifying { return false }
        
        if !flowControlCharacteristic!.isNotifying { return false }
        
        return true
    }
    
    private func isDone() {
        self.initSuccessClosure?()
        self.initSuccessClosure = nil

        self.initTimeoutTimer?.invalidate()

        self.glasses.peripheral.delegate = self.glasses.peripheralDelegate
    }
    
    private func failed(withError error: Error) {
        self.initErrorClosure?(ActiveLookError.connectionTimeoutError)
        self.initErrorClosure = nil

        self.initPollTimer?.invalidate()

        self.glasses.peripheral.delegate = self.glasses.peripheralDelegate
    }
    
    
    // MARK: - Public methods

    public func initialize(onSuccess successClosure: @escaping () -> (Void), onError errorClosure: @escaping (Error) -> (Void)) {
        // We're setting ourselves as the peripheral delegate in order to complete the init process.
        // When the process is done, we'll set the original delegate back

        glasses.peripheral.delegate = self
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
        initTimeoutTimer = Timer.scheduledTimer(withTimeInterval: initTimeoutDuration, repeats: false) { timer in
            self.failed(withError: ActiveLookError.connectionTimeoutError)
        }
    }
    

    // MARK: - CBPeripheralDelegate
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("error while discovering services: ", error!)
            failed(withError: error!)
            return
        }
        
        guard let services = peripheral.services else {
            print("no services discovered for peripheral", peripheral)
            failed(withError: ActiveLookError.initializationError)
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

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("error while discovering characteristics: ", error!, ", for service: ", service)
            failed(withError: error!)
            return
        }
        
        guard service.characteristics != nil else {
            print("no characteristics found for service: ", service)
            failed(withError: ActiveLookError.initializationError)
            return
        }

        for characteristic in service.characteristics! {
            switch characteristic.uuid {
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

            peripheral.discoverDescriptors(for: characteristic)
        
            if (service.uuid == CBUUID.DeviceInformationService) {
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
//        print("peripheral did discover descriptors: ", characteristic.descriptors!," for characteristic: ", characteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        print("peripheral did update value for characteristic: ", characteristic.uuid)
    }
}
