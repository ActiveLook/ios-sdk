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

// The `FirmwareUpdater` class is responsible for providing glasses that are up-to-date Firmware-wise.
// 
class FirmwareUpdater: NSObject, CBPeripheralDelegate {


    // MARK: - Private properties

    private var glasses: Glasses
    private var firmware: Firmware?

//    private let initTimeoutDuration: TimeInterval = 5
//    private let initPollInterval: TimeInterval = 0.2
//
//    private var initTimeoutTimer: Timer?
//    private var initPollTimer: Timer?

    private static let BLOCK_SIZE = 240

    private var suotaVersion: Int = 0
    private var suotaPatchDataSize: Int = 20
    private var suotaMtu: Int = 23
    private var suotaL2capPsm: Int = 0

    private var blocks: Blocks = []

    private var blockId: Int = 0
    private var chunkId: Int = 0
    private var patchLength: Int = 0

    private var spotaService: CBService?
    private var spotaCharacteristics: [CBCharacteristic] = []

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

    internal var peripheral: CBPeripheral

    
    // MARK: - Life cycle

    init(with glasses: Glasses) {
        self.glasses = glasses
        self.peripheral = glasses.peripheral    // IS IT GOOD HERE ??? MAYBE AFTER...

        super.init()

        peripheral.delegate = self
    }


    // MARK: - Private methods

    private func suotaUpdate() {

        guard ( let self.spotaService = peripheral.getService( withUUID: CBUUID.SPOTA_SERVICE_UUID ) ) else {
            peripheral.discoverServices( [ CBUUID.SPOTA_SERVICE_UUID ] )
            return
        }

        guard ( let self.spotaCharacteristics = self.spotaService?.characteristics ) else {
            peripheral.discoverCharacteristics( nil, for: self.spotaService )
            return
        }

        // TODO: REFACTOR --- include timout ?
        self.suotaRead_SUOTA_VERSION_UUID()
    }

    private func suotaRead_SUOTA_VERSION_UUID() {  // -- ✅

        guard let characteristic = self.spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SUOTA_VERSION_UUID } )
        else {
            failed( withError: FirmwareUpdaterError.firmwareUpdater(
                message: "SUOTA VERSION: NO SUOTA_VERSION_UUID characteristic"))
            return
        }

        guard characteristic.valueAsInt != 0 else {
            failed( withError: FirmwareUpdaterError.firmwareUpdater(
                message: "SUOTA VERSION: unexpected format") )
            return
        }

        self.suotaVersion = characteristic.valueAsInt

        // TODO: REFACTOR ---
        steps.append(1)

        self.suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID()
        // ---
    }

    private func suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID() { // -- ✅
        print("2 - suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID")

        guard let characteristic = self.spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SUOTA_PATCH_DATA_CHAR_SIZE_UUID } )
        else {
            failed( withError: FirmwareUpdaterError.firmwareUpdater(
                message: "NO SUOTA_PATCH_DATA_CHAR_SIZE_UUID characteristic"))
            return
        }

        guard ( let value = characteristic.valueAsInt ) != 0 else {
            failed( withError: FirmwareUpdaterError.firmwareUpdater(
                message: "SUOTA_PATCH_DATA_CHAR_SIZE_UUID: unexpected format"))
            return
        }

        self.suotaPatchDataSize = value

        // TODO: REFACTOR ---
        steps.append(2)
    }

    // TODO: REFACTOR ---
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

    // TODO: REFACTOR ---
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

    // TODO: REFACTOR ---
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
    }

    private func onSuotaNotifications(data: Data) { // -- ✅
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

    private func setSpotaGpioMap() { // -- ✅
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

    private func setBlocks() { // -- ✅

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

    private func setPatchLength() { // -- ✅

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

    private func sendBlock() {   // -- ✅

        if ( self.blockId < self.blocks.count ) {

            guard let service = peripheral.getService( withUUID: CBUUID.SPOTA_SERVICE_UUID ) else {
                failed( withError: FirmwareUpdaterError.firmwareUpdater(
                    message: "no SPOTA_SERVICE_UUID service discovered"))
                return
            }

            guard let characteristic = service.getCharacteristic( forUUID: CBUUID.SPOTA_PATCH_DATA_UUID ) else {
                failed( withError: FirmwareUpdaterError.firmwareUpdater(
                    message: "no SPOTA_PATCH_DATA_UUID characteristic discovered"))
                return
            }

            let block: Block = self.blocks[blockId]
            let chunks = block.bytes

            if (self.chunkId < chunks.count) {

                print( String( format: "SUOTA - sendBlock %d chunk %d", arguments: [self.blockId, self.chunkId]))
                peripheral.writeValue( chunks[self.chunkId], for: characteristic, type: .withoutResponse)
                self.chunkId++
                sendBlock()

            } else {

                self.blockId++
                self.chunkId = 0
                print("SPOTA - waiting for notification to send block")
            }
        } else {
            self.sendEndSignal()
        }
    }

    private func sendEndSignal() { // -- ✅
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

        print("SUOTA - sendEndSignal()")
        peripheral.writeValue(UInt32(0xfe000000), for: characteristic, type: .withResponse)
    }

    private func sendRebootSignal() { // -- ✅
        print("SUOTA - sendRebootSignal()")
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

        peripheral.writeValue(UInt32(0xfd000000), for: characteristic, type: .withResponse)
    }

    private func failed(withError error: Error) {
        print(error)
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
                self.suotaUpdate()
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

        // TODO: REFACTOR!
        switch characteristic.uuid {
        case CBUUID.SUOTA_VERSION_UUID :
            suotaRead_SUOTA_VERSION_UUID()

        case CBUUID.SUOTA_PATCH_DATA_CHAR_SIZE_UUID :
            suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID()

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

        // TODO: REFACTOR! SET CHARACTERISTICS TO MATCH
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
            switch UInt32(characteristic.valueAsInt) {
            case UInt32(0xfe000000):
                // notification sendEndSignal()
                self.sendRebootSignal()
            case UInt32(0xfd000000):
                // notification sendRebootSignal()
                print("REBOOTING")
            }

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
