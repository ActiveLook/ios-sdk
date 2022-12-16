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

    static let DeviceInformationCharacteristicsUUIDs = [ManufacturerNameCharacteristic,
                                                        ModelNumberCharacteristic,
                                                        SerialNumberCharateristic,
                                                        HardwareVersionCharateristic,
                                                        FirmwareVersionCharateristic,
                                                        SoftwareVersionCharateristic]


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

    static let ActiveLookCharacteristicsUUIDS = [ActiveLookTxCharacteristic,
                                                 ActiveLookRxCharacteristic,
                                                 ActiveLookUICharacteristic,
                                                 ActiveLookFlowControlCharacteristic,
                                                 ActiveLookSensorInterfaceCharacteristic]


    // MARK: - SUOTA services and characteristics identifiers

    static let NOTIFICATION_DESCRIPTOR = CBUUID.init(string: "00002902-0000-1000-8000-00805f9b34fb") // NOT NEEDED FOR iOS...

//    static let SPOTA_SERVICE_UUID = CBUUID.init(string: "0000fef5-0000-1000-8000-00805f9b34fb")
    static let SpotaService = CBUUID.init(string: "0000fef5-0000-1000-8000-00805f9b34fb")
    static let SPOTA_SERV_STATUS_UUID = CBUUID.init(string: "5f78df94-798c-46f5-990a-b3eb6a065c88")
    static let SPOTA_MEM_DEV_UUID = CBUUID.init(string: "8082caa8-41a6-4021-91c6-56f9b954cc34")
    static let SPOTA_GPIO_MAP_UUID = CBUUID.init(string: "724249f0-5eC3-4b5f-8804-42345af08651")
    static let SPOTA_PATCH_LEN_UUID = CBUUID.init(string: "9d84b9a3-000c-49d8-9183-855b673fda31")
    static let SPOTA_PATCH_DATA_UUID = CBUUID.init(string: "457871e8-d516-4ca1-9116-57d0b17b9cb2")

    static let SUOTA_VERSION_UUID = CBUUID.init(string: "64B4E8B5-0DE5-401B-A21D-ACC8DB3B913A")
    static let SUOTA_PATCH_DATA_CHAR_SIZE_UUID = CBUUID.init(string: "42C3DFDD-77BE-4D9C-8454-8F875267FB3B")
    static let SUOTA_MTU_UUID = CBUUID.init(string: "B7DE1EEA-823D-43BB-A3AF-C4903DFCE23C")
    static let SUOTA_L2CAP_PSM_UUID = CBUUID.init(string: "61C8849C-F639-4765-946E-5C3419BEBB2A")

    static let SUOTA_UUIDS = [NOTIFICATION_DESCRIPTOR,
                              SpotaService,
                              SPOTA_SERV_STATUS_UUID,
                              SPOTA_MEM_DEV_UUID,
                              SPOTA_GPIO_MAP_UUID,
                              SPOTA_PATCH_LEN_UUID,
                              SPOTA_PATCH_DATA_UUID,
                              SUOTA_VERSION_UUID,
                              SUOTA_PATCH_DATA_CHAR_SIZE_UUID,
                              SUOTA_MTU_UUID,
                              SUOTA_L2CAP_PSM_UUID]
}
