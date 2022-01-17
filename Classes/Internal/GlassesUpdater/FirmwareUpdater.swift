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

public enum FirmwareUpdaterError: Error {
    case firmwareUpdater(message: String)
    case sdk
    case sdkDevelopment(message: String = "")   // Used for development? LET'S TRY...
}

#warning("PUT FOLLOWING DEFINITION WHERE IT BELONGS...")
extension UInt32 {
    var byteArray: [UInt8] {
        withUnsafeBytes(of: self.bigEndian) {
            Array($0)
        }
    }
}

// The `FirmwareUpdater` class is responsible for providing glasses that are up-to-date Firmware-wise.
// 
class FirmwareUpdater: NSObject, CBPeripheralDelegate {


    // MARK: - Private properties

    private var glasses: Glasses
    private var firmware: Firmware?

    private let initTimeoutDuration: TimeInterval = 5
    private let initPollInterval: TimeInterval = 0.2

    private var initTimeoutTimer: Timer?
    private var initPollTimer: Timer?

    private static let BLOCK_SIZE = 240

    private var suotaVersion: Int = 0
    private var suotaPatchDataSize: Int = 20
    private var suotaMtu: Int = 23
    private var suotaL2capPsm: Int = 0

    private var blocks: Blocks = []

    private var blockId: Int = 0
    private var chunkId: Int = 0
    private var patchLength: Int = 0

    private var batteryLevelCharacteristic: CBCharacteristic?
    private var txCharacteristic: CBCharacteristic?
    private var rxCharacteristic: CBCharacteristic?
    private var flowControlCharacteristic: CBCharacteristic?
    private var sensorInterfaceCharacteristic: CBCharacteristic?

    private var didDiscoverServices: Bool = false
    private var didDiscoverCharacteristics: Bool = false

    private var steps: [Int8] = [] {
        didSet {
            steps.sort()
            print("steps = \(steps)")
            if steps.count == 4 && steps.last == 4  {
                enableNotifications()
            }
        }
    }


    // MARK: - Internal properties

//    internal var centralManager: CBCentralManager
    internal var peripheral: CBPeripheral
//    internal var peripheralDelegate: PeripheralDelegate

    
    // MARK: - Life cycle

    init(with glasses: Glasses) {
        self.glasses = glasses
        self.peripheral = glasses.peripheral    // IS IT GOOD HERE ??? MAYBE AFTER...

        super.init()

        peripheral.delegate = self
    }


    // MARK: - Private methods

    private func suotaUpdate() {
        peripheral.discoverServices([CBUUID.SPOTA_SERVICE_UUID])

        if didDiscoverServices && didDiscoverCharacteristics {
        }
    }

    private func suotaRead_SUOTA_VERSION_UUID(data: Data) {
        print("1 - suotaRead_SUOTA_VERSION_UUID")

        guard let value = data.first else {
            failed(withError: GlassesUpdaterError.glassesUpdater(
                message: "SUOTA VERSION: unexpected format"))
            return
        }
        self.suotaVersion = Int(value)
        print("suotaVersion: ", self.suotaVersion)
        steps.append(1)
    }

    private func suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID(data: Data) {
        print("2 - suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID")

        let value = data.map{ UInt16($0) }
        guard let uValue = value.first else {
            failed(withError: GlassesUpdaterError.glassesUpdater(
                message: "SUOTA PATCH_DATA_CHAR_SIZE: unexpected format"))
            return
        }
        self.suotaPatchDataSize = Int(uValue)
        steps.append(2)
    }

    private func suotaRead_SUOTA_MTU_UUID(data: Data) {
        print("3 - suotaRead_SUOTA_MTU_UUID")

        let value = data.map{ UInt16($0) }
        guard let uValue = value.first else {
            failed(withError: GlassesUpdaterError.glassesUpdater(
                message: "SUOTA SUOTA_MTU_UUID: unexpected format"))
            return
        }
        self.suotaMtu = Int(uValue)
        steps.append(3)
    }

    private func suotaRead_SUOTA_L2CAP_PSM_UUID(data: Data) {
        print("4 - suotaRead_SUOTA_L2CAP_PSM_UUID")

        let value = data.map{ UInt16($0) }
        guard let uValue = value.first else {
            failed(withError: GlassesUpdaterError.glassesUpdater(
                message: "SUOTA SUOTA_L2CAP_PSM_UUID: unexpected format"))
            return
        }
        self.suotaL2capPsm = Int(uValue)
        steps.append(4)
    }

    private func enableNotifications() {  // -- ✅
        print("SUOTA - enable notification")

        let service = peripheral.getService(withUUID: CBUUID.SPOTA_SERVICE_UUID)

        guard let service = service else {
            print("no SPOTA_SERVICE_UUID service discovered")
            return
        }

        let characteristic = service.getCharacteristic(forUUID: CBUUID.SPOTA_SERV_STATUS_UUID)
        guard let characteristic = characteristic else {
            print("no SPOTA_SERV_STATUS_UUID characteristic discovered")
            return
        }

        peripheral.setNotifyValue(true, for: characteristic)
        steps.append(5)
        print("5 - enableNotifications")
        // onSuccess -> setSpotaMemDev()        -- ✅
        // fail -> throw error                  -- ✅
        // onUpdate -> onSuotaNotification()    -- ✅
    }

    private func onSuotaNotifications(data: Data) { // -- ✅
//        int value = characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8, 0); -- ✅
//        Log.d("Suota notification", String.format("SPOTA_SERV_STATUS notification: %#04x", value)); -- ✅
//        if (value == 0x10) {
//            this.setSpotaGpioMap(gatt, service);  -- ✅
//        } else if (value == 0x02) {
//            this.setPatchLength(gatt, service);   -- ✅
//        } else {
//            Log.e("Suota notification", String.format("SPOTA_SERV_STATUS notification error: %#04x", value)); -- ✅
//        }
        print("onSuotaNotifications()")

        guard let value = data.first else {
            failed(withError: GlassesUpdaterError.glassesUpdater(
                message: "SUOTA notification: unexpected format"))
            return
        }

        print(String(format: "SPOTA_SERV_STATUS notification: %04x", arguments: [value]))

        switch value {
        case 0x10 :
            // self.setSpotaGpioMap()
            self.setSpotaGpioMap()

        case 0x02 :
            // self.setPatchLength()
            self.setPatchLength()

        default :
            print(String(format: "SUOTA notification : SPOTA_SERV_STATUS notification: %04x", arguments: [value]))
        }
    }

    private func setSpotaMemDev() {  // -- ✅
//        final int memType = 0x13000000; -- ✅
//        Log.d("SPOTA", "setSpotaMemDev: " + String.format("%#010x", memType));    -- ✅
//        final BluetoothGattCharacteristic characteristic = service.getCharacteristic(GlassesGatt.SPOTA_MEM_DEV_UUID); -- ✅
//        characteristic.setValue(memType, BluetoothGattCharacteristic.FORMAT_UINT32, 0);
//        gatt.writeCharacteristic(
//            characteristic, -- ✅
//            c -> {
//                Log.d("SPOTA", "Wait for notification for setSpotaMemDev."); -- ✅
//            },
//            this::onCharacteristicError); -- ✅
        let memType: UInt32 = 0x13000000
        print(String(format:"SPOTA - setSpotaMemDev %010x", arguments: [memType]))

        guard let service = peripheral.getService(withUUID: CBUUID.SPOTA_SERVICE_UUID) else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "no SPOTA_SERVICE_UUID service discovered"))
            return
        }

        guard let characteristic = service.getCharacteristic(forUUID: CBUUID.SPOTA_MEM_DEV_UUID) else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "no SPOTA_MEM_DEV_UUID characteristic discovered"))
            return
        }

        peripheral.writeValue(Data(memType.byteArray), for: characteristic, type: .withResponse)
        print("SPOTA - Wait for notification from setSpotaMemDev")
    }

    private func setSpotaGpioMap() { // -- ❌
// private void setSpotaGpioMap(final GlassesGatt gatt, final BluetoothGattService service) {
//        final int memInfoData = 0x05060300; // -- ✅ ### -- ✅ -- ❌
//        Log.d("SPOTA", "setSpotaGpioMap: " + String.format("%#010x", memInfoData));// -- ✅
//        final BluetoothGattCharacteristic characteristic = service.getCharacteristic(GlassesGatt.SPOTA_GPIO_MAP_UUID); // -- ✅
//        characteristic.setValue(memInfoData, BluetoothGattCharacteristic.FORMAT_UINT32, 0); // -- ✅
//        gatt.writeCharacteristic( // -- ✅
//            characteristic,
//            c -> { // -- ✅
//                final int chunkSize = Math.min(this.suotaPatchDataSize, this.suotaMtu - 3); // -- ✅
//                this.blocks = this.firmware.getSuotaBlocks(BLOCK_SIZE, chunkSize); // -- ❌
//                this.blockId = 0; // -- ✅
//                this.chunkId = 0; // -- ✅
//                this.patchLength = 0; // -- ✅
//                this.setPatchLength(gatt, service); // -- ❌
//            },
//            this::onCharacteristicError); // -- ❌
        let memInfoData: UInt32 = 0x05060300

        print(String(format: "SPOTA – setSpotaGpioMap: %010x", arguments: [memInfoData]))

        guard let service = peripheral.getService(withUUID: CBUUID.SPOTA_SERVICE_UUID) else {
            return
        }

        guard let characteristic = service.getCharacteristic(forUUID: CBUUID.SPOTA_GPIO_MAP_UUID) else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "no SPOTA_MEM_DEV_UUID characteristic discovered"))
            return
        }

        peripheral.writeValue(Data(memInfoData.byteArray), for: characteristic, type: .withResponse)
    }

    private func setBlocks() {

        guard let firmware = firmware else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "error updating writing value for characteristic: \(characteristic.uuid)"))
            return
        }

        let chunkSize = min(self.suotaPatchDataSize, self.suotaMtu - 3)

        do {
            try self.blocks = firmware.getSuotaBlocks(Self.BLOCK_SIZE, chunkSize)
        } catch error {
            switch error {
            case E.firmwareNullChunksize :
                failed(withError: FirmwareUpdaterError.firmwareUpdater(
                    message: "Chunk size should not be nul"))
            }
        }

        self.blockId = 0
        self.chunkId = 0
        self.patchLength = 0

        self.setPatchLength()
    }

    private func setPatchLength() {
//    private void setPatchLength(final GlassesGatt gatt, final BluetoothGattService service) {
//        if (this.blockId < this.blocks.size()) {
//            final Pair<Integer, List<byte[]>> block = this.blocks.get(this.blockId);
//            final int blockSize = block.first;
//            if (blockSize != this.patchLength) {
//                Log.d("SUOTA", "setPatchLength: " + blockSize + " - " + String.format("%#06x", blockSize));
//                final BluetoothGattCharacteristic characteristic = service.getCharacteristic(GlassesGatt.SPOTA_PATCH_LEN_UUID);
//                characteristic.setValue(blockSize, BluetoothGattCharacteristic.FORMAT_UINT16, 0);
//                gatt.writeCharacteristic(
//                    characteristic,
//                    c -> {
//                        this.patchLength = blockSize;
//                        this.sendBlock(gatt, service);
//                    },
//                    this::onCharacteristicError);
//            } else {
//                this.sendBlock(gatt, service);
//            }
//        } else {
//            this.sendEndSignal(gatt, service);
//        }


        if ( self.blockId < self.blocks.count ) {

            let block: Block = self.blocks [ self.blockId ]
            let blockSize: UInt16 = block.size

            if ( blockSize != UInt16(self.patchLength)) {
                print(String(format: "SUOTA setPatchLength: \(blockSize) - %06x", arguments: [blockSize]))

                guard let service = peripheral.getService(withUUID: CBUUID.SPOTA_SERVICE_UUID) else {
                    failed(withError: FirmwareUpdaterError.firmwareUpdater(
                        message: "no SPOTA_SERVICE_UUID service discovered"))
                    return
                }

                guard let characteristic = service.getCharacteristic(forUUID: CBUUID.SPOTA_PATCH_LEN_UUID) else {
                    failed(withError: FirmwareUpdaterError.firmwareUpdater(
                        message: "no SPOTA_PATCH_LEN_UUID characteristic discovered"))
                    return
                }

                peripheral.writeValue(blockSize,
                                      for: characteristic,
                                      type: .withResponse)
            } else {
                self.sendBlock()
            }
        } else {
            self.sendEndSignal()
        }
    }

    private func sendBlock() {
//    private void sendBlock(final GlassesGatt gatt, final BluetoothGattService service) {
//        if (this.blockId < this.blocks.size()) {
//            final Pair<Integer, List<byte[]>> block = this.blocks.get(this.blockId);
//            final List<byte[]> chunks = block.second;
//            if (this.chunkId < chunks.size()) { <<<<--------------- ❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌
//                Log.d("SUOTA", String.format("sendBlock %d chunk %d", this.blockId, this.chunkId));
//                final BluetoothGattCharacteristic characteristic = service.getCharacteristic(GlassesGatt.SPOTA_PATCH_DATA_UUID);
//                characteristic.setValue(chunks.get(this.chunkId++));
//                characteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
//                gatt.writeCharacteristic(
//                    characteristic,
//                    c -> this.sendBlock(gatt, service),
//                    this::onCharacteristicError);
//            } else {
//                this.blockId ++;
//                this.chunkId = 0;
//                Log.d("SPOTA", "Wait for notification for sendBlock.");
//            }
//        } else {
//            this.sendEndSignal(gatt, service);
//        }
        if ( self.blockId < self.blocks.count ) {
            let block: Block = self.blocks[blockId]
            les chunks = block.bytes

            if
        }
    }

    private func sendEndSignal() {
//    private void sendEndSignal(final GlassesGatt gatt, final BluetoothGattService service) {
//        Log.d("SUOTA", "sendEndSignal");
//        final BluetoothGattCharacteristic characteristic = service.getCharacteristic(GlassesGatt.SPOTA_MEM_DEV_UUID);
//        characteristic.setValue(0xfe000000, BluetoothGattCharacteristic.FORMAT_UINT32, 0);
//        gatt.writeCharacteristic(
//            characteristic,
//            c -> this.sendRebootSignal(gatt, service),
//            this::onCharacteristicError);
    }

    private func sendRebootSignal() {
//    private void sendRebootSignal(final GlassesGatt gatt, final BluetoothGattService service) {
//        Log.d("SUOTA", "sendRebootSignal");
//        final BluetoothGattCharacteristic characteristic = service.getCharacteristic(GlassesGatt.SPOTA_MEM_DEV_UUID);
//        characteristic.setValue(0xfd000000, BluetoothGattCharacteristic.FORMAT_UINT32, 0);
//        gatt.writeCharacteristic(
//            characteristic,
//            c -> {
//                Log.d("SUOTA", String.format("REBOOTING"));
//            },
//            this::onCharacteristicError);
    }

    private func failed(withError error: Error) {
//        self.initErrorClosure?(ActiveLookError.connectionTimeoutError)
//        self.initErrorClosure = nil
//
//        self.initPollTimer?.invalidate()
        print(error)

        // reset delegate to glasses' own.
        self.glasses.peripheral.delegate = self.glasses.peripheralDelegate
    }


    // MARK: - Public methods

    public func update(glasses : Glasses, with firmware : Firmware) {
    }


    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {

        guard error == nil else {
            print("error while discovering services: ", error!)
            failed(withError: error!)
            return
        }

        guard let services = peripheral.services else {
            print("no service discovered for peripheral", peripheral)
            failed(withError: GlassesUpdaterError.glassesUpdater(
                message: "no service discovered for peripheral"))
            return
        }

        for service in services {
            print("discovered service: \(service.uuid)")

            switch service.uuid {
            case CBUUID.SPOTA_SERVICE_UUID :
                print("discovered service SPOTA_SERVICE_UUID")
                peripheral.discoverCharacteristics(nil, for: service)

            default:
                // print("discovered unknown service: \(service.uuid)")
                break
            }
        }
    }


    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {

        guard error == nil else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "error \(error!) while discovering characteristics for service: \(service)"))
            return
        }

        guard service.characteristics != nil else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "no characteristic discovered for service \(service)"))
            return
        }

        for characteristic in service.characteristics! {

            switch characteristic.uuid {
            case CBUUID.SUOTA_VERSION_UUID :
                print("discovered SUOTA_VERSION_UUID characteristic")
                peripheral.readValue(for: characteristic)

            case CBUUID.SUOTA_PATCH_DATA_CHAR_SIZE_UUID :
                print("discovered SUOTA_PATCH_DATA_CHAR_SIZE_UUID characteristic")
                peripheral.readValue(for: characteristic)

            default:
                // print("discovered unknown characteristic: \(characteristic.uuid)")
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {

        guard error == nil else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "error \(error!) reading value of characteristic: characteristic.uuid "))
            return
        }

        guard let data = characteristic.value else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "no data read for characteristic: \(characteristic)"))
            return
        }

        switch characteristic.uuid {
        case CBUUID.SUOTA_VERSION_UUID :
            suotaRead_SUOTA_VERSION_UUID(data: data)

        case CBUUID.SUOTA_PATCH_DATA_CHAR_SIZE_UUID :
            suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID(data: data)

        case CBUUID.SUOTA_MTU_UUID :
            suotaRead_SUOTA_MTU_UUID(data: data)

        case CBUUID.SUOTA_L2CAP_PSM_UUID :
            suotaRead_SUOTA_L2CAP_PSM_UUID(data: data)

        case CBUUID.SPOTA_MEM_DEV_UUID :
            onSuotaNotifications(data: data)

        default:
            // print("updated value for unknown characteristic: \(characteristic.uuid)")
            break
        }
    }


    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {

        guard error == nil else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "error \(error!) updating notification state for characteristic: \(characteristic.uuid)"))
            return
        }

        guard let data = characteristic.value else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "no data read for characteristic: \(characteristic)"))
            return
        }

        switch characteristic.uuid {

        default :
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "Did update notification state for unknown characteristic: \(characteristic.uuid)"))
        }

    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {

        guard error == nil else {
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "error \(error!) updating writing value for characteristic: \(characteristic.uuid)"))
            return
        }

        switch characteristic.uuid {
        case CBUUID.SPOTA_MEM_DEV_UUID :
            print("SPOTA - Did write value for SPOTA_MEM_DEV_UUID.")

        case CBUUID.SPOTA_GPIO_MAP_UUID :
            print("SPOTA - Did write value for SPOTA_GPIO_MAP_UUID.")
            self.setBlocks()

        case CBUUID.SPOTA_PATCH_LEN_UUID :
            print("SPOTA - Did write value for SPOTA_PATCH_LEN_UUID")
            self.patchLength = UInt16(characteristic.valueAsInt)
            self.sendBlock()

        default:
            failed(withError: FirmwareUpdaterError.firmwareUpdater(
                message: "Did write value for unknown characteristic: \(characteristic.uuid)"))
            return
        }
    }
}
