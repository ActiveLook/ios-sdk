/*

 Copyright 2022 Microoled
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
//import UIKit


// MARK: - Class FirmwareUpdater
// The `FirmwareUpdater` class is responsible for providing glasses that are up-to-date Firmware-wise.

internal class FirmwareUpdater {

    // MARK: - Private properties

    private var successClosure: () -> (Void)
    private var errorClosure: ( GlassesUpdateError ) -> (Void)

    private let BLOCK_SIZE = 240

    private var suotaVersion: Int = 0
    private var suotaPatchDataSize: Int = 20
    private var suotaMtu: Int = 23
    private var suotaL2capPsm: Int = 0

    private var blocks: Blocks = []

    private var blockId: Int = 0
    private var chunkId: Int = 0
    private var patchLength: Int = 0

    private var spotaCharacteristics: [CBCharacteristic] = []
    private var updateParameters: GlassesUpdateParameters?

    private var spotaService: CBService {
        return peripheral.getService(withUUID: CBUUID.SpotaService)!
    }

    private lazy var glasses: Glasses = {
        return glasses
    }()

    private lazy var peripheral: CBPeripheral = {
        return peripheral
    }()

    private lazy var firmware: Firmware = {
        return firmware
    }()

    private lazy var spotaServiceStatusCharacteristic: CBCharacteristic = {
        return spotaService.getCharacteristic(forUUID: CBUUID.SPOTA_SERV_STATUS_UUID)!
    }()

    fileprivate lazy var peripheralDelegate: PeripheralDelegate = {
        return peripheralDelegate
    }()


    // MARK: - Internal properties


    // MARK: - Life cycle

    init(onSuccess successClosure: @escaping () -> (Void),
         onError errorClosure: @escaping ( GlassesUpdateError ) -> (Void)) {

        self.successClosure = successClosure
        self.errorClosure = errorClosure

        guard let sdk = try? ActiveLookSDK.shared() else {
            fatalError(String(format: "Cannot retrieve SDK Singleton @ ", #line))
        }

        guard let updateParameters = sdk.updateParameters else {
            fatalError(String(format: "Cannot retrieve updateParameters @ ", #line))
        }

        self.updateParameters = updateParameters
    }


    // MARK: - Internal Methods

    func update(_ glasses: Glasses, with firmware: Firmware)
    {
        self.peripheral = glasses.peripheral
        self.peripheralDelegate = PeripheralDelegate()

        self.firmware = firmware

        suotaUpdate()
    }


    // MARK: - Private methods

    private func suotaUpdate() {

        print("suotaUpdate")

        guard let spotaCharacteristics = spotaService.characteristics else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "SUOTA VERSION: NO SUOTA_VERSION_UUID characteristic @%d", #line)))
            return
        }

        self.spotaCharacteristics = spotaCharacteristics

        suotaRead_SUOTA_VERSION_UUID()
    }


    private func suotaRead_SUOTA_VERSION_UUID() {

        print("suotaRead_SUOTA_VERSION_UUID")

        guard let characteristic = spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SUOTA_VERSION_UUID } )
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "SUOTA VERSION: NO SUOTA_VERSION_UUID characteristic @%d", #line)))
            return
        }

        guard characteristic.valueAsInt != 0 else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "SUOTA VERSION: unexpected format @%d", #line)))
            return
        }

        suotaVersion = characteristic.valueAsInt

        suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID()
    }


    private func suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID() {

        print("2 - suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID")

        guard let characteristic = spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SUOTA_PATCH_DATA_CHAR_SIZE_UUID } )
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO SUOTA_PATCH_DATA_CHAR_SIZE_UUID characteristic@", #line)))
            return
        }

        let value = characteristic.valueAsInt

        guard value != 0 else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "SUOTA_PATCH_DATA_CHAR_SIZE_UUID: unexpected format@", #line)))
            return
        }

        suotaPatchDataSize = value

        suotaRead_SUOTA_MTU_UUID()
    }


    private func suotaRead_SUOTA_MTU_UUID() {

        print("3 - suotaRead_SUOTA_MTU_UUID")

        guard let characteristic = spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SUOTA_MTU_UUID } )
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO SUOTA_MTU_UUID characteristic@", #line)))
            return
        }

        guard let value = characteristic.value else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO VALUE for SUOTA_MTU_UUID characteristic", #line)))
            return
        }

        let uValue = value.map{ UInt16($0) }

        guard let uValue = uValue.first else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "SUOTA SUOTA_MTU_UUID: unexpected format@", #line)))
            return
        }

        suotaMtu = Int(uValue)

        suotaRead_SUOTA_L2CAP_PSM_UUID()
    }


    private func suotaRead_SUOTA_L2CAP_PSM_UUID() {

        print("4 - suotaRead_SUOTA_L2CAP_PSM_UUID")

        guard let characteristic = spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SUOTA_L2CAP_PSM_UUID } )
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO SUOTA_L2CAP_PSM_UUID characteristic@", #line)))
            return
        }

        guard let value = characteristic.value else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO VALUE for SUOTA_L2CAP_PSM_UUID characteristic@", #line)))
            return
        }

        let uValue = value.map{ UInt16($0) }

        guard let uValue = uValue.first else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "SUOTA SUOTA_L2CAP_PSM_UUID: unexpected format@", #line)))
            return
        }

        suotaL2capPsm = Int(uValue)

        guard spotaServiceStatusCharacteristic.isNotifying else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "SPOTA_SERV_STATUS_UUID characteristic NOT NOTIFYING @", #line)))
            return
        }

        setSpotaMemDev()
    }


    private func onSuotaNotifications() {

        print("onSuotaNotifications()")

//        guard let characteristic = spotaCharacteristics.first(
//            where: { $0.uuid == CBUUID.SPOTA_SERV_STATUS_UUID } )
//        else {
//            failed(with: GlassesUpdateError.firmwareUpdater(
//                message: String(format: "NO SPOTA_SERV_STATUS_UUID characteristic @", #line)))
//            return
//        }

        guard let data = spotaServiceStatusCharacteristic.value else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO VALUE for SPOTA_SERV_STATUS_UUID characteristic @", #line)))
            return
        }

        guard let value = data.first else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "SUOTA notification: unexpected format @", #line)))
            return
        }

        print(String(format: "SPOTA_SERV_STATUS notification: %04x", value))

        switch value {
        case 0x10 :
            self.setSpotaGpioMap()

        case 0x02 :
            self.setPatchLength()

        default :
            print(String(format: "SUOTA notification : SPOTA_SERV_STATUS notification: %04x", value))
        }
    }


    private func setSpotaMemDev() {

        let memType: UInt32 = 0x13000000

        print(String(format:"SPOTA - setSpotaMemDev %010x", arguments: [memType]))

        guard let characteristic = spotaService.getCharacteristic(forUUID: CBUUID.SPOTA_MEM_DEV_UUID) else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "no SPOTA_MEM_DEV_UUID characteristic discovered @%d ", #line)))
            return
        }

        peripheral.writeValue(Data(memType.byteArray), for: characteristic, type: .withResponse)
        print(String(format: "SPOTA - Wait for notification from setSpotaMemDev @%d ", #line))
    }


    private func setSpotaGpioMap() {

        print("setSpotaGpioMap")

        let memInfoData: UInt32 = 0x05060300

        print(String(format: "SPOTA – setSpotaGpioMap: %010x", arguments: [memInfoData]))

        guard let characteristic = spotaService.getCharacteristic(forUUID: CBUUID.SPOTA_GPIO_MAP_UUID) else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "no SPOTA_MEM_DEV_UUID characteristic discovered@", #line)))
            return
        }

        peripheral.writeValue(Data(memInfoData.byteArray), for: characteristic, type: .withResponse)
    }


    private func setBlocks() {

        print("setBlocks")

        let chunkSize = min(suotaPatchDataSize, suotaMtu - 3)

        do {
            try firmware.getSuotaBlocks(BLOCK_SIZE, chunkSize)
        } catch FirmwareError.firmwareNullChunksize {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "Chunk size must be set@", #line)))
        } catch {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "UNKNOWN ERROR getting SUOTA BLOCKS@", #line)))
        }

        blockId = 0
        chunkId = 0
        patchLength = 0

        self.setPatchLength()
    }


    private func setPatchLength() {

        print("setPatchLength")

        if ( blockId < blocks.count ) {

            let block: Block = firmware.blocks [ blockId ]
            let blockSize: UInt16 = UInt16( block.size )

            if ( blockSize != UInt16( patchLength )) {
                print(String(format: "SUOTA setPatchLength: \(blockSize) - %06x", arguments: [blockSize]))

                guard let characteristic = spotaService.getCharacteristic(forUUID: CBUUID.SPOTA_PATCH_LEN_UUID) else {
                    failed(with: GlassesUpdateError.firmwareUpdater(
                        message: String(format: "no SPOTA_PATCH_LEN_UUID characteristic discovered@", #line)))
                    return
                }

                peripheral.writeValue(Data(blockSize.asUInt8Array),
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

        print("sendBlock")

        if ( blockId < firmware.blocks.count ) {

            guard let characteristic = spotaCharacteristics.first(
                where: { $0.uuid == CBUUID.SPOTA_PATCH_DATA_UUID } )
            else {
                failed(with: GlassesUpdateError.firmwareUpdater(
                    message: String(format: "no SPOTA_PATCH_DATA_UUID characteristic discovered @", #line)))
                return
            }

            let block: Block = firmware.blocks[ blockId ]
            let chunks = block.bytes

            if ( chunkId < chunks.count ) {

                print( String( format: "SUOTA - sendBlock %d chunk %d", arguments: [ blockId, chunkId ]))
                peripheral.writeValue( Data( chunks[ chunkId ]), for: characteristic, type: .withoutResponse)
                chunkId += 1
                sendBlock()

            } else {

                blockId += 1
                chunkId = 0

                print("SPOTA - waiting for notification to send block")
            }
        } else {
            self.sendEndSignal()
        }
    }


    private func sendEndSignal() {
        
        print("SUOTA - sendEndSignal()")

        guard let characteristic = spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SPOTA_MEM_DEV_UUID})
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "no SPOTA_MEM_DEV_UUID characteristic discovered @", #line)))
            return
        }


        peripheral.writeValue( Data( UInt32( 0xfe000000 ).asUInt8Array ),
                               for: characteristic,
                               type: .withResponse)
    }


    private func sendRebootSignal() {

        print("SUOTA - sendRebootSignal()")

        guard let characteristic = spotaService.getCharacteristic( forUUID: CBUUID.SPOTA_MEM_DEV_UUID ) else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "no SPOTA_MEM_DEV_UUID characteristic discovered@", #line)))
            return
        }

        peripheral.writeValue( Data( UInt32(0xfd000000).asUInt8Array ),
                               for: characteristic,
                               type: .withResponse)
    }

    private func failed(with error: GlassesUpdateError) {

        errorClosure(error)

        peripheral.delegate = peripheralDelegate
    }
//}

    // MARK: - CBPeripheralDelegate

    // class to allow FirmwareUpdater to not inherit from NSObject and to hide CBPeripheralDelegate methods
    fileprivate class PeripheralDelegate: NSObject, CBPeripheralDelegate {

        weak var parent: FirmwareUpdater?

//        public func peripheral(_ peripheral: CBPeripheral,
//                               didDiscoverCharacteristicsFor service: CBService,
//                               error: Error?) {
//
//            print("didDiscoverCharacteristicsFor")
//
//            guard error == nil else {
//                parent?.failed(with: GlassesUpdateError.firmwareUpdater(
//                    message: String(format: "error \(error!) while discovering characteristics for service: \(service)@", #line)))
//                return
//            }
//
//            guard service.characteristics != nil else {
//                parent?.failed(with: GlassesUpdateError.firmwareUpdater(
//                    message: String(format: "no characteristic discovered for service \(service)@", #line)))
//                return
//            }
//
//            for characteristic in service.characteristics! {
//
//                switch characteristic.uuid
//                {
//                case CBUUID.SUOTA_VERSION_UUID :
//                    print("discovered SUOTA_VERSION_UUID characteristic")
//                    peripheral.readValue(for: characteristic)
//
//                case CBUUID.SUOTA_PATCH_DATA_CHAR_SIZE_UUID :
//                    print("discovered SUOTA_PATCH_DATA_CHAR_SIZE_UUID characteristic")
//                    peripheral.readValue(for: characteristic)
//
//                default:
//                    // print("discovered unknown characteristic: \(characteristic.uuid)")
//                    break
//                }
//            }
//        }

        public func peripheral(_ peripheral: CBPeripheral,
                               didUpdateValueFor characteristic: CBCharacteristic,
                               error: Error?) {

            print("didUpdateValueFor")

            guard error == nil else {
                parent?.failed(with: GlassesUpdateError.firmwareUpdater(
                    message: String(format: "error \(error!) reading value of characteristic: characteristic.uuid @", #line)))
                return
            }

            guard characteristic.value != nil else {
                parent?.failed(with: GlassesUpdateError.firmwareUpdater(
                    message: String(format: "no data read for characteristic: \(characteristic)@", #line)))
                return
            }

            switch characteristic.uuid
            {
//            case CBUUID.SUOTA_VERSION_UUID :
//                parent?.suotaRead_SUOTA_VERSION_UUID()
//
//            case CBUUID.SUOTA_PATCH_DATA_CHAR_SIZE_UUID :
//                parent?.suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID()
//
//            case CBUUID.SUOTA_MTU_UUID :
//                parent?.suotaRead_SUOTA_MTU_UUID()
//
//            case CBUUID.SUOTA_L2CAP_PSM_UUID :
//                parent?.suotaRead_SUOTA_L2CAP_PSM_UUID()

            case CBUUID.SPOTA_SERV_STATUS_UUID :
                parent?.onSuotaNotifications()

            case CBUUID.SPOTA_MEM_DEV_UUID :
                parent?.onSuotaNotifications()

            default:
                // print("updated value for unknown characteristic: \(characteristic.uuid)")
                break
            }
        }

        public func peripheral(_ peripheral: CBPeripheral,
                               didUpdateNotificationStateFor characteristic: CBCharacteristic,
                               error: Error?) {

            print("didUpdateNotificationStateFor")

            guard error == nil else {
                parent?.failed(with: GlassesUpdateError.firmwareUpdater(
                    message: String(format: "error \(error!) updating notification state for characteristic: \(characteristic.uuid)@", #line)))
                return
            }

            guard let _ = characteristic.value else {
                parent?.failed(with: GlassesUpdateError.firmwareUpdater(
                    message: String(format: "no data read for characteristic: \(characteristic)@", #line)))
                return
            }

            // TODO: REFACTOR! SET CHARACTERISTICS TO MATCH
            switch characteristic.uuid {

            case CBUUID.SPOTA_SERV_STATUS_UUID :
                print("Did Updatae notification state for SPOTA_SERV_STATUS_UUID")
                parent?.setSpotaMemDev()

            default :
                parent?.failed(with: GlassesUpdateError.firmwareUpdater(
                    message: String(format: "Did update notification state for unknown characteristic: \(characteristic.uuid)@", #line)))
            }

        }

        public func peripheral(_ peripheral: CBPeripheral,
                               didWriteValueFor characteristic: CBCharacteristic,
                               error: Error?) {

            print("didWriteValueFor")

            guard error == nil else {
                parent?.failed(with: GlassesUpdateError.firmwareUpdater(
                    message: String(format: "error \(error!) updating writing value for characteristic: \(characteristic.uuid)@", #line)))
                return
            }

            switch characteristic.uuid {
            case CBUUID.SPOTA_MEM_DEV_UUID :
                print("SPOTA - Did write value for SPOTA_MEM_DEV_UUID.")

                switch UInt32(characteristic.valueAsInt) {
                case UInt32(0xfe000000):
                    // notification sendEndSignal()
                    parent?.sendRebootSignal()

                case UInt32(0xfd000000):
                    // notification sendRebootSignal()
                    print("REBOOTING")

                default:
                    parent?.failed(with: GlassesUpdateError.firmwareUpdater(
                        message: String(format: "Did write value for unknown characteristic: \(characteristic.uuid)@", #line)))
                    return
                }

            case CBUUID.SPOTA_GPIO_MAP_UUID :
                print("SPOTA - Did write value for SPOTA_GPIO_MAP_UUID.")
                parent?.setBlocks()

            case CBUUID.SPOTA_PATCH_LEN_UUID :
                print("SPOTA - Did write value for SPOTA_PATCH_LEN_UUID")
                parent?.patchLength = characteristic.valueAsInt
                parent?.sendBlock()

            default:
                parent?.failed(with: GlassesUpdateError.firmwareUpdater(
                    message: String(format: "Did write value for unknown characteristic: \(characteristic.uuid)@", #line)))
                return
            }
        }
    }
}
