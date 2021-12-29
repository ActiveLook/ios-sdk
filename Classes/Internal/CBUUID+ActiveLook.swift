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

extension CBUUID {

    // MARK: - Generic access service and characteristics identifiers

    static let GenericAccessService = CBUUID.init(string: "00001800-0000-1000-8000-00805f9b34fb")

    static let DeviceNameCharacteristic = CBUUID.init(string: "00002a00-0000-1000-8000-00805f9b34fb")
    static let AppearanceCharacteristic = CBUUID.init(string: "00002a01-0000-1000-8000-00805f9b34fb")
    static let PeripheralPreferredConnectionParametersCharacteristic = CBUUID.init(string: "00002a02-0000-1000-8000-00805f9b34fb")

    // MARK: - Device information service and characteristics identifiers

    static let DeviceInformationService = CBUUID.init(string: "0000180a-0000-1000-8000-00805f9b34fb")

    static let ManufacturerNameCharacteristic = CBUUID.init(string: "00002a29-0000-1000-8000-00805f9b34fb")
    static let ModelNumberCharacteristic = CBUUID.init(string: "00002a24-0000-1000-8000-00805f9b34fb")
    static let SerialNumberCharateristic  = CBUUID.init(string: "00002a25-0000-1000-8000-00805f9b34fb")
    static let HardwareVersionCharateristic  = CBUUID.init(string: "00002a27-0000-1000-8000-00805f9b34fb")
    static let FirmwareVersionCharateristic  = CBUUID.init(string: "00002a26-0000-1000-8000-00805f9b34fb")
    static let SoftwareVersionCharateristic  = CBUUID.init(string: "00002a28-0000-1000-8000-00805f9b34fb")

    static let DeviceInformationCharacteristicsUUIDs = [ManufacturerNameCharacteristic, ModelNumberCharacteristic, SerialNumberCharateristic, HardwareVersionCharateristic, FirmwareVersionCharateristic, SoftwareVersionCharateristic]

    // MARK: - Battery service and characteristics identifiers

    static let BatteryService = CBUUID.init(string: "0000180f-0000-1000-8000-00805f9b34fb")

    static let BatteryLevelCharacteristic = CBUUID.init(string: "00002a19-0000-1000-8000-00805f9b34fb")

    // MARK: - ActiveLook services and characteristics identifiers

    static let ActiveLookCommandsInterfaceService = CBUUID.init(string: "0783b03e-8535-b5a0-7140-a304d2495cb7")

    static let ActiveLookTxCharacteristic = CBUUID.init(string: "0783b03e-8535-b5a0-7140-a304d2495cb8")
    static let ActiveLookRxCharacteristic = CBUUID.init(string: "0783b03e-8535-b5a0-7140-a304d2495cba")
    static let ActiveLookUICharacteristic = CBUUID.init(string: "0783b03e-8535-b5a0-7140-a304d2495cbc")
    static let ActiveLookFlowControlCharacteristic = CBUUID.init(string: "0783b03e-8535-b5a0-7140-a304d2495cb9")
    static let ActiveLookSensorInterfaceCharacteristic = CBUUID.init(string: "0783b03e-8535-b5a0-7140-a304d2495cbb")

    static let ActiveLookCharacteristicsUUIDS = [ActiveLookTxCharacteristic, ActiveLookRxCharacteristic, ActiveLookUICharacteristic, ActiveLookFlowControlCharacteristic, ActiveLookSensorInterfaceCharacteristic]
}
