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


// MARK: - Definition

public final class FirmwareUpdater: NSObject {


    // MARK: - Private properties

    private let BLOCK_SIZE = 240

    private var suotaVersion: Int = 0 {
        didSet {
            suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID()
        }
    }
    private var suotaPatchDataSize: Int = 20 {
        didSet {
            suotaRead_SUOTA_MTU_UUID()
        }
    }
    private var suotaMtu: Int = 23 {
        didSet {
            suotaRead_SUOTA_L2CAP_PSM_UUID()
        }
    }
    private var suotaL2capPsm: Int = 0 {
        didSet {
            enableNotifications()
        }
    }
    
    private enum QSPIUpdateState: Int {
        case erase
        case write
    }

    private var blocks: Blocks = []

    private var blockId: Int = 0
    private var chunkId: Int = 0
    private var patchLength: Int = 0

    private weak var sdk: ActiveLookSDK?

    private var spotaCharacteristics: [CBCharacteristic] = []
    private var spotaService: CBService?

    private var glasses: Glasses?

    private var peripheral: CBPeripheral?

    private var firmware: Firmware?

    private var spotaServiceStatusCharacteristic: CBCharacteristic?

    private var currentProgress: Double = 0
    private var successClosure: () -> (Void)
    private var errorClosure: ( GlassesUpdateError ) -> (Void)
    
    private let CMD_OVERHEAD: Int = 5
    private let DATA_SIZE_MAX: Int = 512
    private let FLASH_SECTOR_SIZE: Int = 1024 * 4
    private let QSPI_PART_FW_UPDATE: UInt8 = 7
    private var qspiState: QSPIUpdateState = QSPIUpdateState.erase;
    private var currentAddr: Int?
    private var eraseSize: Int?
    private var writeSize: Int?

    
    // MARK: - Life cycle

    init(onSuccess successClosure: @escaping () -> (Void),
         onError errorClosure: @escaping ( GlassesUpdateError ) -> (Void))
    {
        self.successClosure = successClosure
        self.errorClosure = errorClosure

        guard let sdk = try? ActiveLookSDK.shared() else {
            fatalError(String(format: "Cannot retrieve SDK Singleton @ ", #line))
        }

        self.sdk = sdk
    }


    // MARK: - Internal Methods

    func update(_ glasses: Glasses, with firmware: Firmware, glassesFwVersion: String)
    {
        // We're setting ourselves as the peripheral delegate in order update the firmware.
        // If the update succeeds, the device reboots.
        // If the update fails, it will be set back to original one in `failed(with)`.
        glasses.setPeripheralDelegate(to: self)
        self.glasses = glasses
        self.peripheral = glasses.peripheral

        self.firmware = firmware

        sdk?.updateParameters.notify(.updatingFw)
        
        if(glassesFwVersion == "4.12.0"){
            peripheral?.discoverServices([CBUUID.ActiveLookCommandsInterfaceService])
        }
        else{
            peripheral?.discoverServices([CBUUID.SpotaService])
        }
    }
    
    private func FW4120_erase(_ glasses: Glasses, with firmware: Firmware) {
        if qspiState != QSPIUpdateState.erase { return }
        
        let size: Int = firmware.size()
        
        if (self.eraseSize == nil) {
            print("Deleting current partition ...")
            self.eraseSize = size
        }
        
        if (self.currentAddr == nil) {
            self.currentAddr = 0
        }
        
        if let eraseSize = self.eraseSize, let currentAddr = self.currentAddr {
            var block_size = eraseSize
            if block_size > FLASH_SECTOR_SIZE{
                block_size = FLASH_SECTOR_SIZE
            }
            
            self.glasses?.qspi_erase(part: self.QSPI_PART_FW_UPDATE, addr: currentAddr, length: block_size)
                
            self.eraseSize! -= block_size
            self.currentAddr! += block_size
            
            let progress: Double = (1.0 - (Double(self.eraseSize!) / Double(size))) * 50
            print("Remaining erase size: \(self.eraseSize!)")
            sdk?.updateParameters.notify(.updatingFw, progress)
        }
    }
    
    private func FW4120_write(_ glasses: Glasses, with firmware: Firmware) {
        if qspiState != QSPIUpdateState.write { return }

        let firmwareBytes: [UInt8] = firmware.getBytes()
        let size: Int = firmware.size()
        
        if (self.writeSize == nil) {
            print("Writting new partition ...\n")
            self.writeSize = size
        }
        
        if (self.currentAddr == nil) {
            self.currentAddr = 0
        }
        
        if let writeSize = writeSize, let currentAddr = currentAddr {
            var sub_len: Int = size

            if writeSize > (DATA_SIZE_MAX - CMD_OVERHEAD){
                sub_len = DATA_SIZE_MAX - CMD_OVERHEAD
            } else {
                sub_len = writeSize
            }

            let slice: ArraySlice = firmwareBytes[currentAddr..<currentAddr + sub_len]
            let dataToWrite = Array(slice)
            
            self.glasses?.qspi_write(part: self.QSPI_PART_FW_UPDATE, addr: currentAddr, values: dataToWrite)
                
            self.currentAddr! += sub_len
            self.writeSize! -= sub_len
            
            let progress: Double = (1.0 - (Double(self.writeSize!) / Double(size))) * 50 + 50
            print("Writing size remaining : \(self.writeSize!)")
            sdk?.updateParameters.notify(.updatingFw, progress)
        }
    }

    // MARK: - Private methods

    private func failed(with error: GlassesUpdateError)
    {
        glasses?.resetPeripheralDelegate()

        errorClosure(error)
    }


    private func rebooting()
    {
        self.glasses?.resetPeripheralDelegate()
        
        successClosure()
    }


    // MARK: - SUOTA Update

    private func suotaUpdate()
    {
        guard let spotaService = peripheral?.services?.first(
            where: { $0.uuid == CBUUID.SpotaService})
        else {
            dlog(message: "no SPOTA service",
                 line: #line, function: #function, file: #fileID)
            return
        }

        self.spotaService = spotaService

        guard let spotaCharacteristics = spotaService.characteristics else {
            dlog(message: "no characteristics",
                 line: #line, function: #function, file: #fileID)
            return
        }

        self.spotaCharacteristics = spotaCharacteristics

        suotaRead_SUOTA_VERSION_UUID()
    }


    private func suotaRead_SUOTA_VERSION_UUID()
    {
        guard let characteristic = spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SUOTA_VERSION_UUID } )
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO SUOTA_VERSION_UUID characteristic @%d", #line)))
            return
        }

        peripheral?.readValue(for: characteristic)
    }


    private func suotaRead_SUOTA_PATCH_DATA_CHAR_SIZE_UUID()
    {
        guard let characteristic = spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SUOTA_PATCH_DATA_CHAR_SIZE_UUID } )
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO SUOTA_PATCH_DATA_CHAR_SIZE_UUID characteristic@", #line)))
            return
        }

        peripheral?.readValue(for: characteristic)
    }


    private func suotaRead_SUOTA_MTU_UUID()
    {
        guard let characteristic = spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SUOTA_MTU_UUID } )
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO SUOTA_MTU_UUID characteristic@", #line)))
            return
        }

        peripheral?.readValue(for: characteristic)
    }


    private func suotaRead_SUOTA_L2CAP_PSM_UUID()
    {
        guard let characteristic = spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SUOTA_L2CAP_PSM_UUID } )
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO SUOTA_L2CAP_PSM_UUID characteristic@", #line)))
            return
        }

        peripheral?.readValue(for: characteristic)
    }


    private func enableNotifications()
    {
        guard let characteristic = spotaCharacteristics.first(
            where: { $0.uuid == CBUUID.SPOTA_SERV_STATUS_UUID })
        else {
            fatalError("SPOTA_SERV_STATUS_UUID NOT RETRIEVED")
        }

        if !characteristic.isNotifying {
            peripheral?.setNotifyValue( true, for: characteristic )
        }

        spotaServiceStatusCharacteristic = characteristic
    }


    private func onSuotaNotifications()
    {
        guard let data = spotaServiceStatusCharacteristic?.value else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "NO VALUE for SPOTA_SERV_STATUS_UUID characteristic @", #line)))
            return
        }

        guard let value = data.first else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "SUOTA notification: unexpected format @", #line)))
            return
        }

        let message = String(format: "SPOTA_SERV_STATUS notification: %04x", value)
        dlog(message: message, line: #line, function: #function, file: #fileID)

        switch value {
        case 0x10 :
            self.setSpotaGpioMap()

        case 0x02 :
            self.setPatchLength()

        default :
            dlog(message: String(format: "SUOTA notification : SPOTA_SERV_STATUS notification: %04x", value),
                 line: #line, function: #function, file: #fileID)
        }
    }


    private func setSpotaMemDev()
    {
        let memType: UInt32 = 0x13000000

        let message = String(format:"SPOTA - setSpotaMemDev %010x",memType)
        dlog(message: message, line: #line, function: #function, file: #fileID)

        guard let characteristic = spotaCharacteristics.first(
            where: {$0.uuid == CBUUID.SPOTA_MEM_DEV_UUID })
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "no SPOTA_MEM_DEV_UUID characteristic discovered @%d ", #line)))
            return
        }

        let data = Data(memType.byteArray)

        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }


    private func setSpotaGpioMap()
    {
        let memInfoData: UInt32 = 0x05060300

        let message = String(format: "SPOTA – setSpotaGpioMap: %010x", arguments: [memInfoData])
        dlog(message: message, line: #line, function: #function, file: #fileID)

        guard let characteristic = spotaCharacteristics.first(where: { $0.uuid == CBUUID.SPOTA_GPIO_MAP_UUID })
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "no SPOTA_GPIO_MAP_UUID characteristic discovered@", #line)))
            return
        }

        let data = Data(memInfoData.byteArray)
        peripheral?.writeValue( data, for: characteristic, type: .withResponse)
    }


    private func setBlocks()
    {
        let chunkSize = min(suotaPatchDataSize, suotaMtu - 3)

        do {
            try firmware?.getSuotaBlocks(BLOCK_SIZE, chunkSize)
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

        guard let firmware = firmware else {
            fatalError(String(format: "FIRMWARE NOT SET @", #line))
        }

        if ( blockId < firmware.blocks.count ) {

            let block: Block = firmware.blocks [ blockId ]
            let blockSize: UInt16 = UInt16( block.size )

            if ( blockSize != UInt16( patchLength )) {

                let message = String(format: "SUOTA setPatchLength: \(blockSize) - %06x", arguments: [blockSize])
                dlog(message: message, line: #line, function: #function, file: #fileID)

                guard let characteristic = spotaService?.getCharacteristic(forUUID: CBUUID.SPOTA_PATCH_LEN_UUID)
                else {
                    failed(with: GlassesUpdateError.firmwareUpdater(
                        message: String(
                            format: "no SPOTA_PATCH_LEN_UUID characteristic discovered@", #line)))
                    return
                }

                patchLength = Int(blockSize)

                peripheral?.writeValue(Data(blockSize.byteArray),
                                      for: characteristic,
                                      type: .withResponse)
            } else {
                sendBlock()
            }
        } else {
            sendEndSignal()
        }
    }


    private func sendBlock() {

        guard let firmware = firmware else {
            fatalError("FIRMWARE NOT SET")
        }

        if ( blockId < firmware.blocks.count ) {

            let block: Block = firmware.blocks[ blockId ]
            let chunks = block.chunks

            if ( chunkId < chunks.count ) {

                dlog(message: String( format: "SUOTA - sendBlock %d chunk %d", blockId, chunkId),
                     line: #line, function: #function, file: #fileID)


                guard let characteristic = spotaCharacteristics.first(
                    where: { $0.uuid == CBUUID.SPOTA_PATCH_DATA_UUID } )
                else {
                    failed(with: GlassesUpdateError.firmwareUpdater(
                        message: String(format: "no SPOTA_PATCH_DATA_UUID characteristic discovered @", #line)))
                    return
                }

                peripheral?.writeValue( Data( chunks[ chunkId ]), for: characteristic, type: .withoutResponse)

                let progress: Double = Double(blockId * 100) / Double(firmware.blocks.count)
                if ( progress > currentProgress ) {
                    currentProgress = progress
                    sdk?.updateParameters.notify(.updatingFw, progress)
                }
                
                chunkId += 1
                sendBlock()

            } else {

                blockId += 1
                chunkId = 0

                dlog(message: "SUOTA – Waiting for notification...",
                     line: #line, function: #function, file: #fileID)

            }
        } else {
            self.sendEndSignal()
        }
    }


    private func sendEndSignal()
    {
        peripheral?.setNotifyValue(false, for: spotaServiceStatusCharacteristic!)
    }


    private func sendRebootSignal()
    {
        guard let characteristic = spotaService?.getCharacteristic( forUUID: CBUUID.SPOTA_MEM_DEV_UUID )
        else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "no SPOTA_MEM_DEV_UUID characteristic discovered@", #line)))
            return
        }

        self.glasses?.isIntentionalDisconnect = true

        sdk?.updateParameters.notify(.rebooting)

        peripheral?.writeValue( Data( UInt32(0xfd000000).byteArray ),
                               for: characteristic,
                               type: .withResponse)
        rebooting()
    }
    
    private func sendQSPIResetSignal()
    {
        self.glasses?.isIntentionalDisconnect = true

        sdk?.updateParameters.notify(.rebooting)
        
        glasses?.reset()

        rebooting()
    }
}


// MARK: -
extension FirmwareUpdater: CBPeripheralDelegate
{

    // TODO: make delegate react to battery level notifications !!!
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverServices error: Error?)
    {
        guard let services = peripheral.services else {
            fatalError("NO SERVICES FOUND")
        }
        
        if let activelookCommandsService = services.first(where: {$0.uuid == CBUUID.ActiveLookCommandsInterfaceService}) {
            peripheral.discoverCharacteristics([CBUUID.ActiveLookRxCharacteristic], for: activelookCommandsService)
            return
        }

        guard let spotaService = services.first(where: {$0.uuid == CBUUID.SpotaService}) else {
            fatalError("NO SPOTA SERVICE FOUND")
        }

        peripheral.discoverCharacteristics(nil, for: spotaService)
    }


    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?)
    {
        guard error == nil else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(
                    format: "error \(error!) while discovering characteristics for service: \(service)@",
                    #line)))
            return
        }
        
        if service.uuid == CBUUID.ActiveLookCommandsInterfaceService {
            if let characteristics = service.characteristics {
                if characteristics.contains(where: { c in
                    c.uuid == CBUUID.ActiveLookRxCharacteristic
                }) {
                    glasses?.clear()
                    glasses?.layoutDisplay(id: 0x09, text: "")
                    
                    qspiState = .erase
                    FW4120_erase(self.glasses!, with: self.firmware!)
                    return
                }
            }
        }

        guard let _ = service.characteristics else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "no characteristic discovered for service \(service)@", #line)))
            return
        }

        suotaUpdate()
    }


    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: Error?)
    {
        guard error == nil else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(
                    format: "error \(error!) reading value of characteristic: characteristic.uuid @", #line)))
            return
        }

        guard let value = characteristic.value else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(format: "no data read for characteristic: \(characteristic)@", #line)))
            return
        }

        switch characteristic.uuid
        {
        case CBUUID.ActiveLookFlowControlCharacteristic:
            if let flowControlState = FlowControlState(rawValue: characteristic.valueAsInt) {
                glasses?.notifyFlowControl(state: flowControlState)
            }
        case CBUUID.SUOTA_VERSION_UUID :
            suotaVersion = Int(value.withUnsafeBytes( { $0.load(as: UInt8.self ) }))

        case CBUUID.SUOTA_PATCH_DATA_CHAR_SIZE_UUID :
            suotaPatchDataSize = Int(value.withUnsafeBytes( { $0.load(as: UInt16.self ) }))

        case CBUUID.SUOTA_MTU_UUID :
            suotaMtu = Int(value.withUnsafeBytes( { $0.load(as: UInt16.self ) }))

        case CBUUID.SUOTA_L2CAP_PSM_UUID :
            suotaL2capPsm = Int(value.withUnsafeBytes( { $0.load(as: UInt16.self ) }))

        case CBUUID.SPOTA_SERV_STATUS_UUID :
            onSuotaNotifications()

        case CBUUID.SPOTA_MEM_DEV_UUID :
            guard let value = characteristic.value else {
                fatalError("SPOTA_MEM_DEV_UUID is nil")
            }

            if (value.count >= 4 && value[0] == 0x00 && value[1] == 0x00
                && value[2] == 0x00 && value[3] == 0xfe) {
                sendRebootSignal()
            } else {
                dlog(message: "waiting for notification SPOTA",
                     line: #line, function: #function, file: #fileID)
            }

        default:
            // print("updated value for unknown characteristic: \(characteristic.uuid)")
            break
        }
    }


    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateNotificationStateFor characteristic: CBCharacteristic,
                           error: Error?)
    {
        guard error == nil else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(
                    format: "error \(error!) updating notification state for char: \(characteristic.uuid)@",
                    #line)))
            return
        }

        switch characteristic.uuid {

        case CBUUID.SPOTA_SERV_STATUS_UUID :
            if characteristic.isNotifying {
                setSpotaMemDev()
            } else {
                guard let charac = spotaCharacteristics.first(
                    where: { $0.uuid == CBUUID.SPOTA_MEM_DEV_UUID}) else {
                        fatalError()
                    }
                peripheral.writeValue( Data( UInt32( 0xfe000000 ).byteArray ),
                                       for: charac,
                                       type: .withResponse)
            }

        default :
            dlog(message: "Did update notification state for unknown characteristic",
                 line: #line, function: #function, file: #fileID)
        }
    }


    public func peripheral(_ peripheral: CBPeripheral,
                           didWriteValueFor characteristic: CBCharacteristic,
                           error: Error?)
    {
        guard error == nil else {
            failed(with: GlassesUpdateError.firmwareUpdater(
                message: String(
                    format: "error \(error!) writing value for characteristic: \(characteristic.uuid)@", #line)))
            return
        }

        switch characteristic.uuid {
        case CBUUID.ActiveLookRxCharacteristic :
            guard let glasses = glasses, let firmware = firmware else {
                print("Failed to retrieve glasses & firmware info")
                return
            }

            // TODO: Soucis avec CBATTError.Code.writeNotPermitted, probalement du à la longueur envoyé qui est trop grande
            glasses.setRxCharacteristicAvailable()
            
            if glasses.isLastCommandWrittenComplete {
                switch qspiState {
                    case .erase:
                        if self.eraseSize == 0 {
                            print("QSPI Erase done !")
                            
                            self.eraseSize = nil
                            self.currentAddr = nil
                            qspiState = .write
                            self.FW4120_write(glasses, with: firmware)
                        } else {
                            self.FW4120_erase(glasses, with: firmware)
                        }
                    case .write:
                        if self.writeSize == 0 {
                            print("QSPI Update done !")
                            
                            self.writeSize = nil
                            self.currentAddr = nil
                            sendQSPIResetSignal()
                        } else {
                            self.FW4120_write(glasses, with: firmware)
                        }
                }
            }
            
            
        case CBUUID.SPOTA_MEM_DEV_UUID :
            if !spotaServiceStatusCharacteristic!.isNotifying {
                dlog(message: "Did WRITE END SIGNAL",
                     line: #line, function: #function, file: #fileID)

                sendRebootSignal()
            }

        case CBUUID.SPOTA_GPIO_MAP_UUID :
            dlog(message: "Did write value for SPOTA_GPIO_MAP_UUID",
                 line: #line, function: #function, file: #fileID)
            setBlocks()

        case CBUUID.SPOTA_PATCH_LEN_UUID :
            dlog(message: "Did write value for SPOTA_PATCH_LEN_UUID",
                 line: #line, function: #function, file: #fileID)
            sendBlock()

        default:
            break
        }
    }
}
