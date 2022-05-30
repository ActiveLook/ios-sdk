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

/// A representation of connected ActiveLook® glasses.
///
/// Commands can be sent directly using the corresponding method.
///
/// If a response from the glasses is expected, it can be handled by providing a closure to the callback argument.
///
/// It is possible to subscribe to three different types of notifications by providing a callback closure using the corresponding method.
///
/// The glasses will send updates about the current battery level once every 30 seconds.
///
/// They will notify about the state of the flow control whenever it changes.
///
/// Finally, the registered callback will be triggered when a gesture is detected by the gesture detection sensor.
///
/// To disconnect from the glasses, simply call the `disconnect()` method.
///
public class Glasses {
    
    // MARK: - Public properties
    
    /// The name of the glasses, as advertised over Bluetooth.
    public var name: String
    
    /// The identifier of the glasses, as advertised over Bluetooth. It is not guaranteed to be unique over a certain period and across sessions.
    public var identifier: UUID
    
    /// The manufacturer id as set on the device as a hex string.
    public var manufacturerId: String
    

    // MARK: - Internal properties

    internal var centralManager: CBCentralManager
    internal var peripheral: CBPeripheral

    internal var disconnectionCallback: (() -> Void)?
    
    internal var isIntentionalDisconnect: Bool = false

    // MARK: - Fileprivate properties

    fileprivate var peripheralDelegate: PeripheralDelegate


    // MARK: - Private properties

    private var batteryLevelUpdateCallback: ((Int) -> Void)?
    private var flowControlUpdateCallback: ((FlowControlState) -> Void)?
    private var sensorInterfaceTriggeredCallback: (() -> Void)?
    
    // Query ids are handled internally by the SDK. The `queryId` variable is used to keep track of
    // the last queryId sent to the glasses and increment the value for each new command.
    private var queryId: UInt8
    
    // The maximum amount of data, in bytes, you can send to a characteristic in a single write type.
    private var availableMTU: Int = 20
    
    // A queue used for storing commands while glasses are unavailable
    private var commandQueue: ConcurrentDataQueue {
        didSet {
            if (oldValue.count < commandQueue.count) {
                self.sendBytes()
            }
        }
    }

    // The status of the flowControl server
    private var flowControlState: FlowControlState {
        didSet {
            if (flowControlState == .on) {
                self.sendBytes()
            }
        }
    }
    
    // RXCharacteristicState
    private enum RXCharacteristicState: Int {
        case available = 0
        case busy = 1
    }
    
    private var rxCharacteristicState: RXCharacteristicState {
        didSet {
            if (rxCharacteristicState == .available) {
                self.sendBytes()
            }
        }
    }

    private weak var sdk: ActiveLookSDK?

    // used for loading configurations
    private var isUpdating = false
    private var configSize = 0
    private var currentProgress: Double = 0
    private var successClosure: (() -> Void)?
    private var errorClosure: (() -> Void)?
    
    // An array used to track queries (commands expecting a response) and match them to
    // the corresponding callback returning the response data as a byte array ([UInt8]).
    private var pendingQueries: [UInt8: (CommandResponseData) -> Void]
    
    // A buffer used to squash response chunks into a single CommandResponseData
    private var responseBuffer: [UInt8]?
    
    // The expected size of the response buffer
    private var expectedResponseBufferLength: Int
    
    private var deviceInformationService: CBService? {
        return peripheral.getService(withUUID: CBUUID.DeviceInformationService)
    }
    
    private var batteryService: CBService? {
        return peripheral.getService(withUUID: CBUUID.BatteryService)
    }
    
    private var activeLookService: CBService? {
        return peripheral.getService(withUUID: CBUUID.ActiveLookCommandsInterfaceService)
    }

    private var spotaService: CBService? {
        return peripheral.getService(withUUID: CBUUID.SpotaService)
    }

    private var batteryLevelCharacteristic: CBCharacteristic? {
        return batteryService?.getCharacteristic(forUUID: CBUUID.BatteryLevelCharacteristic)
    }

    private var rxCharacteristic: CBCharacteristic? {
        return activeLookService?.getCharacteristic(forUUID: CBUUID.ActiveLookRxCharacteristic)
    }

    private var txCharacteristic: CBCharacteristic? {
        return activeLookService?.getCharacteristic(forUUID: CBUUID.ActiveLookTxCharacteristic)
    }

    private var flowControlCharacteristic: CBCharacteristic? {
        return activeLookService?.getCharacteristic(forUUID: CBUUID.ActiveLookFlowControlCharacteristic)
    }

    private var sensorInterfaceCharacteristic: CBCharacteristic? {
        return activeLookService?.getCharacteristic(forUUID: CBUUID.ActiveLookSensorInterfaceCharacteristic)
    }


    // MARK: - Initializers
    
    internal init(name: String,
                  identifier: UUID,
                  manufacturerId: String,
                  peripheral: CBPeripheral,
                  centralManager: CBCentralManager )
    {
        self.name = name
        self.identifier = identifier
        self.manufacturerId = manufacturerId
        self.peripheral = peripheral
        self.centralManager = centralManager
        
        self.queryId = 0x00
        self.pendingQueries = [:]
        self.responseBuffer = nil
        self.expectedResponseBufferLength = 0
        // MTU not retrieved dynamically as maximumWriteValueLength() is flawed for now...
        // self.availableMTU = (self.peripheral.maximumWriteValueLength(for: .withResponse)) / 2 - 3
        self.availableMTU = 256 - 3
        self.commandQueue = ConcurrentDataQueue(using: self.availableMTU)
        self.flowControlState = .on
        self.rxCharacteristicState = .available
        self.peripheralDelegate = PeripheralDelegate()
        self.peripheralDelegate.parent = self
        self.commandQueue.set(parent: self)
        self.peripheral.delegate = self.peripheralDelegate

        guard let sdk = try? ActiveLookSDK.shared() else {
            fatalError("Cannot retrieve SDK Singleton")
        }

        self.sdk = sdk
    }


    internal convenience init(discoveredGlasses: DiscoveredGlasses)
    {
        self.init(
            name: discoveredGlasses.name,
            identifier: discoveredGlasses.identifier,
            manufacturerId: discoveredGlasses.manufacturerId,
            peripheral: discoveredGlasses.peripheral,
            centralManager: discoveredGlasses.centralManager
        )
        self.disconnectionCallback = discoveredGlasses.disconnectionCallback
    }


    // MARK: - Internal methods

    internal func resetPeripheralDelegate()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        self.peripheral.delegate = self.peripheralDelegate
    }

    internal func setPeripheralDelegate(to delegate: CBPeripheralDelegate)
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        self.peripheral.delegate = delegate
    }

    internal func areConnected() -> Bool {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        return self.peripheral.state == .connected
    }


    // MARK: - Private methods
    
    private func getNextQueryId() -> UInt8
    {
        queryId = (queryId + 1) % 255
        return queryId
    }

    private func sendCommand(id commandId: CommandID,
                             withData data: [UInt8]? = [],
                             callback: ((CommandResponseData) -> Void)? = nil )
    {
        let header: UInt8 = 0xFF, footer: UInt8 = 0xAA
        let queryId = getNextQueryId()
        
        let defaultLength: Int = 5 // Header + CommandId + CommandFormat + Command length (one byte) + Footer
        let queryLength: Int = 1 // Query ID is used internally and always encoded on 1 byte
        let dataLength: Int = data?.count ?? 0
        var totalLength: Int = defaultLength + queryLength + dataLength
        
        if totalLength > 255 {
            totalLength += 1 // We must add one byte to encode length on 2 bytes
        }
    
        let commandFormat: UInt8 = UInt8((totalLength > 255 ? 0x10 : 0x00) | queryLength)

        var bytes = [header, commandId.rawValue, commandFormat]
        
        if totalLength > 255 {
            bytes.append(contentsOf: Int16(totalLength).asUInt8Array) // Encode on 2 bytes
        } else {
            bytes.append(UInt8(totalLength))
        }
        
        bytes.append(queryId)
        if (data != nil) { bytes.append(contentsOf: data!) }
        bytes.append(footer)
        
        if callback != nil {
            pendingQueries[queryId] = callback
        }
        
        commandQueue.enqueue(bytes)
    }
    
    private func sendCommand(id: CommandID, withValue value: Bool)
    {
        sendCommand(id: id, withData: value ? [0x01] : [0x00])
    }
    
    private func sendCommand(id: CommandID, withValue value: UInt8)
    {
        sendCommand(id: id, withData: [value])
    }

    /// sends the bytes queued in commandQueue
    private func sendBytes()
    {
        if flowControlState != FlowControlState.on { return }

        if rxCharacteristicState == .busy { return }
        
        guard let value = commandQueue.dequeue() else {
            if isUpdating {
                dlog(message: "Config ALooK updated",
                     line: #line, function: #function, file: #fileID)

                isUpdating = false
                currentProgress = 0
                successClosure?()
            }
            return
        }

        if isUpdating {
            let elementsLeft = commandQueue.count
            dlog(message: "\(elementsLeft) left",
                 line: #line, function: #function, file: #fileID)
            let progress = Double(100 - (elementsLeft * 99) / configSize)
            if progress > currentProgress {
                currentProgress = progress
                sdk?.updateParameters.notify(.updatingConfig, progress)
            }
        }

        peripheral.writeValue(value, for: rxCharacteristic!, type: .withResponse)

        rxCharacteristicState = .busy
    }
    
    private func handleTxNotification(withData data: Data) {
        let bytes = [UInt8](data)
        //print("received notification for tx characteristic with data: \(bytes)")
        
        if responseBuffer != nil { // If we're currently filling up the response buffer, handle differently
            handleChunkedResponse(withData: bytes)
            return
        }

        // TODO: Raise error
        guard data.count >= 6 else { return } // Header + CommandID + CommandFormat + QueryID + Length + Footer

        let handledCommandIDs: [UInt8] = [
            CommandID.battery, CommandID.vers, CommandID.settings, CommandID.imgList,
            CommandID.pixelCount, CommandID.getChargingCounter, CommandID.getChargingTime,
            CommandID.rConfigID, CommandID.cfgRead, CommandID.cfgList, CommandID.cfgGetNb,
            CommandID.cfgFreeSpace, CommandID.fontList, CommandID.pageGet, CommandID.pageList
        ].map({$0.rawValue})
        
        let commandId = bytes[1]
        let commandFormat = bytes[2]

        guard handledCommandIDs.contains(commandId) else { return } // TODO Log
        guard commandFormat == 0x01 || commandFormat == 0x11 else { return } // TODO Log
        
        let totalLength: Int = commandFormat == 0x01 ? Int(bytes[3]) : Int.fromUInt16ByteArray(bytes: [bytes[3], bytes[4]])
        
        if totalLength == data.count {
            handleCompleteResponse(withData: bytes)
        } else {
            expectedResponseBufferLength = totalLength
            handleChunkedResponse(withData: bytes)
        }
    }
    
    private func handleCompleteResponse(withData data: [UInt8])
    {
        // TODO: Raise error
        guard data.count >= 6 else { return } // Header + CommandID + CommandFormat + QueryID + Length + Footer

        let header = data[0]
        let footer = data[data.count - 1]
        guard header == 0xFF else { return } // TODO Raise error
        guard footer == 0xAA else { return } // TODO Raise error

        let commandFormat = data[2]
        let queryId = commandFormat == 0x01 ? data[4] : data[5]
        
        var commandData: [UInt8] = []
        let commandDataStartIndex = commandFormat == 0x01 ? 5 : 6
        
        if commandDataStartIndex <= (data.count - 1 - 1) { // Else there is no data
            commandData = Array(data[commandDataStartIndex...(data.count - 1 - 1)])
        }

        if let callback = pendingQueries[queryId] {
            callback(commandData)
            pendingQueries[queryId] = nil
        }
    }
    
    // Handle chuncked responses (Glasses will answer as 20 bytes chunks if response is longer)
    //
    // We cannot reliably check for the presence of headers and footers as each chunk may contain any data.
    // Instead, we're adding every chunk of data we receive to a buffer until the expected response length is reached.
    //
    // If some chunks are dropped / never received, we will, for now, incorrectly push data to the response buffer until
    // the expected response length is reached.
    private func handleChunkedResponse(withData data: [UInt8]) {
        if responseBuffer == nil { responseBuffer = [] } // Create response buffer if first chunk

        responseBuffer!.append(contentsOf: data)
                
        guard responseBuffer!.count <= expectedResponseBufferLength else {
            print("buffer overflow error: \(data)") // TODO Raise error
            return
        }

        if responseBuffer!.count == expectedResponseBufferLength {

            guard responseBuffer![0] == 0xFF, responseBuffer![responseBuffer!.count - 1] == 0xAA else {
                print("buffer format error") // TODO Raise error
                return
            }

            let completeData = responseBuffer!
            handleCompleteResponse(withData: completeData)
            responseBuffer = nil
            expectedResponseBufferLength = 0
        }
    }


    // MARK: - Public methods

    /// Disconnect from the glasses.
    public func disconnect() {
        isIntentionalDisconnect = true
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    /// Set the callback to be called when the connection to the glasses is lost.
    /// - Parameter disconnectionCallback: A callback called asynchronously when the device is disconnected.
    public func onDisconnect(_ disconnectionCallback: (() -> Void)?) {
        self.disconnectionCallback = disconnectionCallback
    }


    public func discoverSpotaChars() {
        self.peripheral.discoverCharacteristics(nil, for: spotaService!)
    }

    /// Get information relative to the device as published over Bluetooth.
    /// - Returns: The current information about the device, including its manufacturer name, model number, serial number, hardware version, software version and firmware version.
    public func getDeviceInformation() -> DeviceInformation {
        guard let di = deviceInformationService else {
            return DeviceInformation()
        }
        
        return DeviceInformation(
            di.getCharacteristic(forUUID: CBUUID.ManufacturerNameCharacteristic)?.valueAsUTF8,
            di.getCharacteristic(forUUID: CBUUID.ModelNumberCharacteristic)?.valueAsUTF8,
            di.getCharacteristic(forUUID: CBUUID.SerialNumberCharateristic)?.valueAsUTF8,
            di.getCharacteristic(forUUID: CBUUID.HardwareVersionCharateristic)?.valueAsUTF8,
            di.getCharacteristic(forUUID: CBUUID.FirmwareVersionCharateristic)?.valueAsUTF8,
            di.getCharacteristic(forUUID: CBUUID.SoftwareVersionCharateristic)?.valueAsUTF8
        )
    }


    /// Returns a `SerializedGlasses` object of the glasses
    ///
    /// The `SerializedGlasses` type can be stored easily to allow for automatic reconnect later on.
    ///
    /// This object can then be used with `sdk.shared().connect(using: ...)` to reconnect to the glasses
    ///  without having to go through the whole `scan() -> discover() -> connect()` process.
    ///
    /// - returns: `SerializedGlasses`
    /// - throws: `ActiveLookError.serializeError` if the serialization fails
    ///
    /// Usage:
    ///
    ///     let sg: SerializedGlasses = glasses.getSerializedGlasses()
    ///     UserDefaults.standard.set(sg, forKey: "SerializedGlasses")
    ///
    ///     // then to reconnect:
    ///     let sg = UserDefaults.standard.object(forKey: "SerializedGlasses") as SerializedGlasses
    ///     sdk.connect(using: sg)
    ///
    public func getSerializedGlasses() throws -> SerializedGlasses
    {
        return try UnserializedGlasses(id: identifier.description, name: name, manId: manufacturerId).serialize()
    }

    // MARK: - Utility commands
    
    /// Check if firmware is at least
    /// - Parameter version: the version to compare to
    public func isFirmwareAtLeast(version: String) -> Bool {
        let gVersion = self.getDeviceInformation().firmwareVersion
        guard gVersion != nil else { return false }
        if (gVersion ?? "" >= "v\(version).0b") {
            return true
        } else {
            return false
        }
    }

    /// Compare the firmware against a certain version
    /// - Parameter version: the version to compare to
    public func compareFirmwareAtLeast(version: String) -> ComparisonResult {
        let gVersion = self.getDeviceInformation().firmwareVersion
        return (gVersion ?? "").compare("v\(version).0b")
    }
    
    /// load a configuration file
    public func loadConfiguration(cfg: [String]) -> Void {
        for line in cfg {
            commandQueue.enqueue(line.hexaBytes)
        }
    }

    /// load a configuration file with closures for feedback
    public func loadConfigurationWithClosures(cfg: String,
                                              onSuccess successClosure: @escaping () -> (),
                                              onError errorClosure: @escaping () -> () ) -> Void
    {
        // FIXME: temp. fix. Might not be needed after correct implementation, using only GlassesUpdateParameters
        isUpdating = true
        self.successClosure = successClosure
        self.errorClosure = errorClosure

        commandQueue.enqueueFile(cfg)
    }

    // MARK: - General commands
    
    /// Power the device on or off.
    /// - Parameter on: on if true, off otherwise
    public func power(on: Bool) {
        sendCommand(id: .power, withValue: on)
    }
    
    /// Clear the whole screen.
    public func clear() {
        sendCommand(id: .clear)
    }
    
    /// /// Set the whole display to the corresponding grey level
    /// - Parameter level: The grey level between 0 and 15
    public func grey(level: UInt8) {
        sendCommand(id: .grey, withValue: level)
    }
    
    /// Display the demonstration pattern
    public func demo() {
        sendCommand(id: .demo)
    }
    
    /// Display the test pattern from demo command fw 4.0
    /// - Parameter pattern: The demo pattern. 0: Fill screen. 1: Rectangle with a cross in it. 2: Image
    public func demo(pattern: DemoPattern) {
        sendCommand(id: .demo, withValue: pattern.rawValue)
    }
    
    /// Display the test pattern
    /// - Parameter pattern: The demo pattern. 0: Fill screen. 1: Rectangle with a cross in it
    public func test(pattern: DemoPattern) {
        sendCommand(id: .demo, withValue: pattern.rawValue)
    }
    
    /// Get the battery level
    /// - Parameter callback: A callback called asynchronously when the device answers
    public func battery(_ callback: @escaping (Int) -> Void) {
        sendCommand(id: .battery, withData: nil) { (commandResponseData) in
            guard commandResponseData.count >= 1 else { return }
            callback(Int(commandResponseData[0]))
        }
    }
    
    /// Get the glasses version parameters such as device ID and firmware version
    /// - Parameter callback: A callback called asynchronously when the device answers
    public func vers(_ callback: @escaping (GlassesVersion) -> Void) {
        sendCommand(id: .vers, withData: nil) { (commandResponseData) in
            callback(GlassesVersion.fromCommandResponseData(commandResponseData))
        }
    }

    /// Set the state of the green LED
    /// - Parameter state: The led state between off, on, toggle and blinking
    public func led(state: LedState) {
        sendCommand(id: .led, withValue: state.rawValue)
    }
    
    /// Shift all subsequent displayed object of (x,y) pixels
    /// - Parameters:
    ///   - x: The horizontal shift, between -128 and 127
    ///   - y: The vertical shift, between -128 and 127
    public func shift(x: Int16, y: Int16) {
        var data: [UInt8] = []
        data.append(contentsOf: x.asUInt8Array)
        data.append(contentsOf: y.asUInt8Array)

        sendCommand(id: .shift, withData: data)
    }
    
    /// Get the glasses settings such as screen shift, luma and sensor information
    /// - Parameter callback: A callback called asynchronously when the device answers
    public func settings(_ callback: @escaping (GlassesSettings) -> Void) {
        sendCommand(id: .settings, withData: nil) { (commandResponseData) in
            callback(GlassesSettings.fromCommandResponseData(commandResponseData))
        }
    }
    
    // MARK: - Luma commands
    
    /// Set the display luminance to the corresponding level
    /// - Parameter level: The luma level between 0 and 15
    public func luma(level: UInt8) {
        sendCommand(id: .luma, withValue: level)
    }
    
    // MARK: - Optical sensor commands
    
    /// Turn on/off the auto brightness adjustment and gesture detection
    /// - Parameter enabled: enabled if true, disabled otherwise
    public func sensor(enabled: Bool) {
        sendCommand(id: .sensor, withValue: enabled)
    }
    
    /// Turn on/off the gesture detection
    /// - Parameter enabled: enabled if true, disabled otherwise
    public func gesture(enabled: Bool) {
        sendCommand(id: .gesture, withValue: enabled)
    }
    
    /// Turn on/off the auto brightness adjustment
    /// - Parameter enabled: enabled if true, disabled otherwise
    public func als(enabled: Bool) {
        sendCommand(id: .als, withValue: enabled)
    }
    
    // MARK: - Graphics commands
    
    /// Sets the grey level used to draw the next graphical element
    /// - Parameter level: The grey level to be used between 0 and 15
    public func color(level: UInt8) {
        sendCommand(id: .color, withValue: level)
    }
    
    /// Set a pixel on at the corresponding coordinates
    /// - Parameters:
    ///   - x: The x coordinate
    ///   - y: The y coordinate
    public func point(x: Int16, y: Int16) {
        var data: [UInt8] = []
        
        data.append(contentsOf: x.asUInt8Array)
        data.append(contentsOf: y.asUInt8Array)

        sendCommand(id: .point, withData: data)
    }

    // TODO: CHANGE SIGNATURE TO MATCH [API DOC](https://gitlab.com/microoled/activelook-api-documentation/-/blob/master/ActiveLook_API.md#Graphicscommands)
    /// Draw a line at the corresponding coordinates
    /// - Parameters:
    ///   - x0: The x coordinate of the start of the line
    ///   - x1: The x coordinate of the end of the line
    ///   - y0: The y coordinate of the start of the line
    ///   - y1: The y cooridnate of the end of the line
    public func line(x0: Int16, x1: Int16, y0: Int16, y1: Int16) {
        var data: [UInt8] = []
        
        data.append(contentsOf: x0.asUInt8Array)
        data.append(contentsOf: y0.asUInt8Array)
        data.append(contentsOf: x1.asUInt8Array)
        data.append(contentsOf: y1.asUInt8Array)

        sendCommand(id: .line, withData: data)
    }

    // TODO: CHANGE SIGNATURE TO MATCH [API DOC](https://gitlab.com/microoled/activelook-api-documentation/-/blob/master/ActiveLook_API.md#Graphicscommands)
    /// Draw an empty rectangle at the corresponding coordinates
    /// - Parameters:
    ///   - x0: The x coordinate of the bottom left part of the rectangle
    ///   - x1: The x coordinate of the top right part of the rectangle
    ///   - y0: The y coordinate of the bottom left part of the rectangle
    ///   - y1: The y coordinate of the top right part of the rectangle
    public func rect(x0: Int16, x1: Int16, y0: Int16, y1: Int16) {
        var data: [UInt8] = []
        
        data.append(contentsOf: x0.asUInt8Array)
        data.append(contentsOf: y0.asUInt8Array)
        data.append(contentsOf: x1.asUInt8Array)
        data.append(contentsOf: y1.asUInt8Array)

        sendCommand(id: .rect, withData: data)
    }

    // TODO: CHANGE SIGNATURE TO MATCH [API DOC](https://gitlab.com/microoled/activelook-api-documentation/-/blob/master/ActiveLook_API.md#Graphicscommands)
    /// Draw a full rectangle at the corresponding coordinates
    /// - Parameters:
    ///   - x0: The x coordinate of the bottom left part of the rectangle
    ///   - x1: The x coordinate of the top right part of the rectangle
    ///   - y0: The y coordinate of the bottom left part of the rectangle
    ///   - y1: The y coordinate of the top right part of the rectangle
    public func rectf(x0: Int16, x1: Int16, y0: Int16, y1: Int16) {
        var data: [UInt8] = []
        
        data.append(contentsOf: x0.asUInt8Array)
        data.append(contentsOf: y0.asUInt8Array)
        data.append(contentsOf: x1.asUInt8Array)
        data.append(contentsOf: y1.asUInt8Array)

        sendCommand(id: .rectf, withData: data)
    }
    
    /// Draw an empty circle at the corresponding coordinates
    /// - Parameters:
    ///   - x: The x coordinate of the center of the circle
    ///   - y: The y coordinate of the center of the circle
    ///   - radius: The circle radius in pixels
    public func circ(x: Int16, y: Int16, radius: UInt8) {
        var data: [UInt8] = []
        
        data.append(contentsOf: x.asUInt8Array)
        data.append(contentsOf: y.asUInt8Array)
        data.append(radius)
        
        sendCommand(id: .circ, withData: data)
    }
    
    /// Draw a full circle at the corresponding coordinates
    /// - Parameters:
    ///   - x: The x coordinate of the center of the circle
    ///   - y: The y coordinate of the center of the circle
    ///   - radius: The circle radius in pixels
    public func circf(x: Int16, y: Int16, radius: UInt8) {
        var data: [UInt8] = []
        
        data.append(contentsOf: x.asUInt8Array)
        data.append(contentsOf: y.asUInt8Array)
        data.append(radius)
        
        sendCommand(id: .circf, withData: data)
    }
    
    /// Write the specified string at the specified coordinates, with rotation, font size and color
    /// - Parameters:
    ///   - x: The x coordinate of the start of the string
    ///   - y: The y coordinate of the start of the string
    ///   - rotation: The rotation of the drawn text
    ///   - font: The id of the font used to draw the string
    ///   - color: The color used to draw the string, between 0 and 15
    ///   - string: The string to draw
    public func txt(x: Int16, y: Int16, rotation: TextRotation, font: UInt8, color: UInt8, string: String) {
        var data: [UInt8] = []
        
        data.append(contentsOf: x.asUInt8Array)
        data.append(contentsOf: y.asUInt8Array)
        data.append(rotation.rawValue)
        data.append(font)
        data.append(color)
        data.append(contentsOf: string.asNullTerminatedUInt8Array)
        
        sendCommand(id: .txt, withData: data)
    }


    /// Draw a multiple connected lines at the corresponding coordinates.
    /// - Parameters:
    ///  - points: array of uint16 tuples (x, y).
    public func polyline(points: [Point]) {

        var data: [UInt8] = []

        for point in points {
            data.append(contentsOf:point.x.asUInt8Array)
            data.append(contentsOf:point.y.asUInt8Array)
        }

        sendCommand(id: .polyline, withData: data)
    }

    
    // MARK: - Bitmap commands

    /// List all images saved on the device.
    /// - Parameter callback: A callback called asynchronously when the device answers
    public func imgList(_ callback: @escaping ([ImageInfo]) -> Void) {
        sendCommand(id: .imgList, withData: nil) { (commandResponseData) in
            guard commandResponseData.count % 5 == 0 else {
                print("response format error for imgList command") // TODO Raise error
                return
            }
            
            var images: [ImageInfo] = []
            let chunkedData = commandResponseData.chunked(into: 5)

            for data in chunkedData {
                images.append(ImageInfo.fromCommandResponseData(data))
            }
            
            callback(images)
        }
    }
    
    /// Save a 4bpp image of the specified width.
    /// - Parameter imageData: The data representing the image to save
    public func imgSave(id: UInt8, imageData: ImageData) {
        var firstChunkData: [UInt8] = [id]
        firstChunkData.append(contentsOf: imageData.size.asUInt8Array)
        firstChunkData.append(contentsOf: imageData.width.asUInt8Array)
        
        sendCommand(id: .imgSave, withData: firstChunkData)
        
        // TODO Should be using bigger chunk size (505) but not working on 3.7.4b
        let chunkedImageData = imageData.data.chunked(into: 121) // 128 - ( Header + CmdID + CmdFormat + QueryId + Length on 2 bytes + Footer)
                
        for chunk in chunkedImageData {
            sendCommand(id: .imgSave, withData: chunk) // TODO This will probably cause unhandled overflow if the image is too big
        }
    }
    
    /// Display the image corresponding to the specified id at the specified position
    /// - Parameters:
    ///   - id: The id of the image to display
    ///   - x: The x coordinate of the image to display
    ///   - y: The y coordinate of the image to display
    public func imgDisplay(id: UInt8, x: Int16, y: Int16) {
        var data: [UInt8] = [id]
        data.append(contentsOf: x.asUInt8Array)
        data.append(contentsOf: y.asUInt8Array)
        sendCommand(id: .imgDisplay, withData: data)
    }

    /// Delete the specified image
    /// - Parameter id: The id of the image to delete
    public func imgDelete(id: UInt8) {
        sendCommand(id: .imgDelete, withValue: id)
    }

    /// Delete all images
    public func imgDeleteAll() {
        sendCommand(id: .imgDelete, withValue: 0xFF)
    }

    /// WARNING: NOT TESTED / NOT FULLY IMPLEMENTED
    public func imgStream(imageData: ImageData, x: Int16, y: Int16) {
        // TODO Infer size from data length
        // TODO Create command and send command
    }

    /// WARNING: NOT TESTED / NOT FULLY IMPLEMENTED
    public func imgSave1bpp(imageData: ImageData) {
        // TODO Create command and send command
    }
    
    
    // MARK: - Font commands
    
    /// WARNING: CALLBACK NOT WORKING as of 3.7.4b
    // FIXME: is malfunction still occuring? (4.2 - 2022/03/17)
    public func fontlist(_ callback: @escaping ([FontInfo]) -> Void) {
        sendCommand(id: .fontList) { (commandResponseData: [UInt8]) in
            callback(FontInfo.fromCommandResponseData(commandResponseData))
        }
    }

    /// Save a font to the specified font id
    /// - Parameters:
    ///   - id: The id of the font to save
    ///   - fontData: The encoded font data
    public func fontSave(id: UInt8, fontData: FontData) {
        var firstChunkData: [UInt8] = []
        firstChunkData.append(id)
        firstChunkData.append(contentsOf: UInt16(fontData.data.count).asUInt8Array)

        sendCommand(id: .fontSave, withData: firstChunkData)
        
        // TODO Should be using bigger chunk size (505) but not working on 3.7.4b
        let chunkedCommandData = fontData.data.chunked(into: 121) // 128 - ( Header + CmdID + CmdFormat + QueryId + Length on 2 bytes + Footer)

        for chunk in chunkedCommandData {
            sendCommand(id: .fontSave, withData: chunk) // TODO This will probably cause unhandled overflow if the image is too big
        }
    }

    /// Select font which will be used for followings txt commands
    /// - Parameter id: The id of the font to select
    public func fontSelect(id: UInt8) {
        sendCommand(id: .fontSelect, withValue: id)
    }

    /// Delete the font corresponding to the specified font id if present
    /// - Parameter id: The id of the font to delete
    public func fontDelete(id: UInt8) {
        sendCommand(id: .fontDelete, withValue: id)
    }

    /// Delete all the fonts
    public func fontDeleteAll() {
        sendCommand(id: .fontDelete, withValue: 0xFF)
    }

    
    // MARK: - Layout commands
    
    /// Save a new layout according to the specified layout parameters.
    /// - Parameter layout: The parameters of the layout to save
    public func layoutSave(parameters: LayoutParameters) {
        sendCommand(id: .layoutSave, withData: parameters.toCommandData())
    }

    /// Delete the specified layout
    /// - Parameter id: The id of the layout to delete
    public func layoutDelete(id: UInt8) {
        sendCommand(id: .layoutDelete, withValue: id)
    }

    /// Delete all layouts
    public func layoutDeleteAll() {
        sendCommand(id: .layoutDelete, withValue: 0xFF)
    }

    /// Display the specified layout with the specified text as its value
    /// - Parameters:
    ///   - id: The id of the layout to display
    ///   - text: The text value of the layout
    public func layoutDisplay(id: UInt8, text: String) {
        var data: [UInt8] = [id]
        data.append(contentsOf: text.asNullTerminatedUInt8Array)
        sendCommand(id: .layoutDisplay, withData: data)
    }

    /// Clear the layout area corresponding to the specified layout id
    /// - Parameter id: The id of the layout to clear
    public func layoutClear(id: UInt8) {
        sendCommand(id: .layoutClear, withValue: id)
    }

    /// Get the list of layouts
    /// - Parameter callback: A callback called asynchronously when the device answers
    public func layoutList(_ callback: @escaping ([Int]) -> Void) {
        sendCommand(id: .layoutList) { (commandResponseData: [UInt8]) in
            var results: [Int] = []
            commandResponseData.forEach { b in
                results.append(Int(b & 0x00FF))
            }
            callback(results)
        }
    }

    /// Redefine the position of a layout. The new position is saved.
    /// - Parameters:
    ///   - id: The id of the layout to reposition
    ///   - x: The x coordinate of the new position
    ///   - y: The y coordinate of the new position
    public func layoutPosition(id: UInt8, x: UInt16, y: UInt8) {
        var data: [UInt8] = [id]
        data.append(contentsOf: x.asUInt8Array)
        data.append(y) // y is only encoded on 1 byte

        sendCommand(id: .layoutPosition, withData: data)
    }

    /// Display the specified layout at the specified position with the specified value. Position is not saved
    /// - Parameters:
    ///   - id: The id of the layout to display
    ///   - x: The x coordinate of the position of the layout
    ///   - y: The y coordinate of the position of the layout
    ///   - text: The text value of the layout
    public func layoutDisplayExtended(id: UInt8, x: UInt16, y: UInt8, text: String) {
        var data: [UInt8] = [id]
        data.append(contentsOf: x.asUInt8Array)
        data.append(y) // y is only encoded on 1 byte
        data.append(contentsOf: text.asNullTerminatedUInt8Array)
        
        sendCommand(id: .layoutDisplayExtended, withData: data)
    }

    /// Get a layout
    /// - Parameters:
    ///   - id: The id of the layout to get
    ///   - callback: A callback called asynchronously when the device answers
    public func layoutGet(id: UInt8, _ callback: @escaping (LayoutParameters) -> Void) {
        sendCommand(id: .layoutGet, withData: [id]) { (commandResponseData: [UInt8]) in
            callback(LayoutParameters.fromCommandResponseData(commandResponseData))
        }
    }
    
    
    // MARK: - Gauge commands
    
    /// Display the specified gauge with the specified value
    /// - Parameters:
    ///   - id: The gauge to display. It should have been created beforehand with the gaugeSave() command.
    ///   - value: The value of the gauge.
    public func gaugeDisplay(id: UInt8, value: UInt8) {
        sendCommand(id: .gaugeDisplay, withData: [id, value])
    }

    /// Save a gauge for the specified id with the specified parameters.
    ///
    /// ⚠ The `cfgWrite` command is required before any gauge upload.
    ///
    /// - Parameters:
    ///   - id: The id of the gauge
    ///   - x: The horizontal position of the gauge on the screen
    ///   - y: The vertical position of the gauge on the screen
    ///   - externalRadius: The radius of the outer bound of the gauge, in pixels
    ///   - internalRadius: The radius of the inner bound of the gauge, in pixels
    ///   - start: The start segment of the gauge, between 1 and 16
    ///   - end: The end segment of the gauge, between 1 and 16
    ///   - clockwise: Whether the gauge should be drawn clockwise or anti-clockwise
    public func gaugeSave(id: UInt8, x: UInt16, y: UInt16, externalRadius: UInt16, internalRadius: UInt16, start: UInt8, end: UInt8, clockwise: Bool) {
        var data: [UInt8] = [id]
        
        data.append(contentsOf: x.asUInt8Array)
        data.append(contentsOf: y.asUInt8Array)
        data.append(contentsOf: externalRadius.asUInt8Array)
        data.append(contentsOf: internalRadius.asUInt8Array)
        
        data.append(contentsOf: [start, end, clockwise ? 0x01 : 0x00])
        
        sendCommand(id: .gaugeSave, withData: data)
    }

    /// Delete the specified gauge
    /// - Parameter id: The id of the gauge to delete
    public func gaugeDelete(id: UInt8) {
        sendCommand(id: .gaugeDelete, withValue: id)
    }

    /// Delete all gauge
    public func gaugeDeleteAll() {
        sendCommand(id: .gaugeDelete, withValue: 0xFF)
    }

    /// Get the list of gauge
    /// - Parameter callback: A callback called asynchronously when the device answers
    public func gaugeList(_ callback: @escaping ([Int]) -> Void) {
        sendCommand(id: .gaugeList) { (commandResponseData: [UInt8]) in
            var results: [Int] = []
            commandResponseData.forEach { b in
                results.append(Int(b & 0x00FF))
            }
            callback(results)
        }
    }

    /// Get a gauge
    /// - Parameters:
    ///   - id: The id of the gauge to get
    ///   - callback: A callback called asynchronously when the device answers
    public func gaugeGet(id: UInt8, _ callback: @escaping (GaugeInfo) -> Void) {
        sendCommand(id: .gaugeGet, withData: [id]) { (commandResponseData: [UInt8]) in
            callback(GaugeInfo.fromCommandResponseData(commandResponseData))
        }
    }
    
    // MARK: - Page commands
    /// Save a page
    public func pageSave(id: UInt8, layoutIds: [UInt8], xs: [Int16], ys: [UInt8]) {
        let pi = PageInfo(id, layoutIds, xs, ys)
        sendCommand(id: .pageSave, withData: pi.payload)
    }

    /// Get a page
    /// - Parameters:
    ///   - id: The id of the page to get
    ///   - callback: A callback called asynchronously when the device answers
    public func pageGet(id: UInt8, _ callback: @escaping (PageInfo) -> Void) {
        sendCommand(id: .pageGet, withData: [id]) { (commandResponseData: [UInt8]) in
            callback(PageInfo.fromCommandResponseData(commandResponseData))
        }
    }

    /// Delete a page
    public func pageDelete(id: UInt8) {
        sendCommand(id: .pageDelete, withValue: id)
    }
    
    /// Delete all pages
    public func pageDeleteAll() {
        sendCommand(id: .pageDelete, withValue: 0xFF)
    }


    /// Display a page
    public func pageDisplay(id: UInt8, texts: [String]) {
        var withData: [UInt8] = [id]
        texts.forEach { text in
            withData += text.asNullTerminatedUInt8Array
        }
        sendCommand(id: .pageDisplay, withData: withData)
    }

    /// Clear a page
    public func pageClear(id: UInt8) {
        sendCommand(id: .pageClear, withValue: id)
    }

    /// List a page
    public func pageList(_ callback: @escaping ([Int]) -> Void) {
        sendCommand(id: .pageList) { (commandResponseData: [UInt8]) in
            var results: [Int] = []
            commandResponseData.forEach { b in
                results.append(Int(b & 0x00FF))
            }
            callback(results)
        }
    }
    
    
    // MARK: - Statistics commands
    /// Get number of pixel activated on display
    /// - Parameter callback: A callback called asynchronously when the device answers
    public func pixelCount(_ callback: @escaping (Int) -> Void) {
        sendCommand(id: .pixelCount, withData: nil) { (commandResponseData: [UInt8]) in
            let pixelCount = Int.fromUInt32ByteArray(bytes: commandResponseData)
            callback(pixelCount)
        }
    }

    /// Get total number of charging cycles
    /// - Parameter callback: A callback called asynchronously when the device answers
    public func getChargingCounter(_ callback: @escaping (Int) -> Void) {
        sendCommand(id: .getChargingCounter, withData: nil) { (commandResponseData: [UInt8]) in
            let chargingCount = Int.fromUInt32ByteArray(bytes: commandResponseData)
            callback(chargingCount)
        }
    }

    /// Get total number of charging minutes
    /// - Parameter callback: A callback called asynchronously when the device answers
    public func getChargingTime(_ callback: @escaping (Int) -> Void) {
        sendCommand(id: .getChargingTime, withData: nil) { (commandResponseData: [UInt8]) in
            let chargingTime = Int.fromUInt32ByteArray(bytes: commandResponseData)
            callback(chargingTime)
        }
    }
    
    /// Reset charging counter and charging time values
    public func resetChargingParam() {
        sendCommand(id: .resetChargingParam)
    }
    
    
    // MARK: - Configuration commands
    
    /// Write configuration. The configuration id is used to track which config is on the device
    /// - Parameters:
    ///   - number: The configuration number
    ///   - configID: The configuration ID
    public func writeConfigID(configuration: Configuration) {
        sendCommand(id: .wConfigID, withData: configuration.toCommandData())
    }

    /// Read configuration.
    /// - Parameter number: The number of the configuration to read
    ///   - callback:  A callback called asynchronously when the device answers
    public func readConfigID(number: UInt8, callback: @escaping (Configuration) -> Void) {
        sendCommand(id: .rConfigID, withData: [number]) { (commandResponseData) in
            callback(Configuration.fromCommandResponseData(commandResponseData))
        }
    }
    
    /// Set current configuration to display images, layouts and fonts.
    /// - Parameter number: The number of the configuration to read
    public func setConfigID(number: UInt8) {
        sendCommand(id: .setConfigID, withValue: number)
    }
    
    /// Write a new configuration
    public func cfgWrite(name: String, version: Int, password: UInt32) {
        let withData = name.asNullTerminatedUInt8Array + version.asUInt8Array + password.asUInt8Array
        sendCommand(id: .cfgWrite, withData: withData)
    }

    /// Read a configuration
    public func cfgRead(name: String, callback: @escaping (ConfigurationElementsInfo) -> Void) {
        sendCommand(id: .cfgRead, withData: name.asNullTerminatedUInt8Array) { (commandResponseData) in
            callback(ConfigurationElementsInfo.fromCommandResponseData(commandResponseData))
        }
    }

    /// Set the configuration
    public func cfgSet(name: String) {
        sendCommand(id: .cfgSet, withData: name.asNullTerminatedUInt8Array)
    }

    /// List of configuration
    public func cfgList(callback: @escaping ([ConfigurationDescription]) -> Void) {
        sendCommand(id: .cfgList) { (commandResponseData) in
            callback(ConfigurationDescription.fromCommandResponseData(commandResponseData))
        }
    }

    /// Rename a configuration
    public func cfgRename(oldName: String, newName: String, password: UInt32) {
        let withData = oldName.asNullTerminatedUInt8Array + newName.asNullTerminatedUInt8Array + password.asUInt8Array
        sendCommand(id: .cfgRename, withData: withData)
    }

    /// Delete a configuration
    public func cfgDelete(name: String) {
        sendCommand(id: .cfgDelete, withData: name.asNullTerminatedUInt8Array)
    }

    /// Delete least used configuration
    public func cfgDeleteLessUsed() {
        sendCommand(id: .cfgDeleteLessUsed)
    }

    /// get available free space
    public func cfgFreeSpace(callback: @escaping (FreeSpace) -> Void) {
        sendCommand(id: .cfgFreeSpace) { (commandResponseData) in
            callback(FreeSpace.fromCommandResponseData(commandResponseData))
        }
    }

    /// get number of configuration
    public func cfgGetNb(callback: @escaping (Int) -> Void) {
        sendCommand(id: .cfgGetNb) { (commandResponseData) in
            callback(Int(commandResponseData[0]))
        }
    }


    // MARK: - Device Commands
    
    /// Shutdown the device
    /// Shutdown is not allowed while USB powered.
    public func shutdown() {
        sendCommand(id: .shutdown, withData: [0x6F, 0x7F, 0xC4, 0xEE])
    }


    // MARK: - Notifications
    
    /// Subscribe to battery level notifications. The specified callback will return the battery value about once every thirty seconds.
    /// - Parameter batteryLevelUpdateCallback: A callback called asynchronously when the device sends a battery level notification.
    public func subscribeToBatteryLevelNotifications(onBatteryLevelUpdate batteryLevelUpdateCallback: @escaping (Int) -> (Void)) {
        peripheral.setNotifyValue(true, for: batteryLevelCharacteristic!)
        self.batteryLevelUpdateCallback = batteryLevelUpdateCallback
    }
    
    /// Subscribe to flow control notifications. The specified callback will be called whenever the flow control state changes.
    /// - Parameter flowControlUpdateCallback: A callback called asynchronously when the device sends a flow control update.
    public func subscribeToFlowControlNotifications(onFlowControlUpdate flowControlUpdateCallback: @escaping (FlowControlState) -> (Void)) {
        self.flowControlUpdateCallback = flowControlUpdateCallback
    }
    
    /// Subscribe to sensor interface notifications. The specified callback will be called whenever a gesture has been detected.
    /// - Parameter sensorInterfaceTriggeredCallback: A callback called asynchronously when the device detects a gesture.
    public func subscribeToSensorInterfaceNotifications(onSensorInterfaceTriggered sensorInterfaceTriggeredCallback: @escaping () -> (Void)) {
        peripheral.setNotifyValue(true, for: sensorInterfaceCharacteristic!)
        self.sensorInterfaceTriggeredCallback = sensorInterfaceTriggeredCallback
    }
    
    /// Unsubscribe from battery level notifications.
    public func unsubscribeFromBatteryLevelNotifications() {
        peripheral.setNotifyValue(false, for: batteryLevelCharacteristic!)
        batteryLevelUpdateCallback = nil
    }
    
    /// Unsubscribe from flow control notifications.
    public func unsubscribeFromFlowControlNotifications() {
        flowControlUpdateCallback = nil
    }
    
    /// Unsubscribe from sensor interface notifications.
    public func unsubscribeFromSensorInterfaceNotifications() {
        peripheral.setNotifyValue(false, for: sensorInterfaceCharacteristic!)
        sensorInterfaceTriggeredCallback = nil
    }

    
    // MARK: - CBPeripheralDelegate

    /// Internal class to allow Glasses to not inherit from NSObject and to hide CBPeripheralDelegate methods
    fileprivate class PeripheralDelegate: NSObject, CBPeripheralDelegate {

        weak var parent: Glasses?


        public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
            guard error == nil else {
                print("error while updating notification state : \(error!.localizedDescription) for characteristic: \(characteristic.uuid)")
                return
            }

            print("peripheral did update notification state for characteristic: \(characteristic) in: \(#fileID)")
        }


        public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            guard error == nil else {
                // TODO Raise error
                print("error while updating value : \(error!.localizedDescription) for characteristic: \(characteristic.uuid)")
                return
            }

            //print("peripheral did update value for characteristic: ", characteristic.uuid)
            
            switch characteristic.uuid {
            case CBUUID.ActiveLookTxCharacteristic:
                if let data = characteristic.value {
                    parent?.handleTxNotification(withData: data)
                }

            case CBUUID.BatteryLevelCharacteristic:
                parent?.batteryLevelUpdateCallback?(characteristic.valueAsInt)

            case CBUUID.ActiveLookSensorInterfaceCharacteristic:
                parent?.sensorInterfaceTriggeredCallback?()

            case CBUUID.ActiveLookFlowControlCharacteristic:
              if let flowControlState = FlowControlState(rawValue: characteristic.valueAsInt)
              {
                  if (flowControlState == FlowControlState.on ||
                      flowControlState == FlowControlState.off) {
                      // ON and OFF notifications are only used for internally
                      parent?.flowControlState = flowControlState
                  } else {
                      // Other notifications are sent to the callback, if provided
                      parent?.flowControlUpdateCallback?(flowControlState)
                  }
              }

            default:
                break
            }
        }


        public func peripheral(_ peripheral: CBPeripheral,
                               didWriteValueFor characteristic: CBCharacteristic,
                               error: Error?)
        {
            guard error == nil else {
                // TODO Raise error
                print("error while writing value : \(error!.localizedDescription) for characteristic: \(characteristic.uuid)")
                return
            }
            
            switch characteristic.uuid {
            
            case CBUUID.ActiveLookRxCharacteristic:
                parent?.rxCharacteristicState = .available

            default:
                break
            }
            
            //print("peripheral did write value for characteristic: ", characteristic.uuid)
        }
    }

    
    // MARK: - DataStructure

    fileprivate struct ConcurrentDataQueue
    {
        weak var parent: Glasses?

        private let dispatchQueue = DispatchQueue(label: "com.activelook.queueOperations",
                                                  attributes: .concurrent)
        private var mtu: Int
        private var elements: [Data]
        
        var isEmpty: Bool { return elements.isEmpty }
        var count: Int { return elements.count }

        
        init( using mtu: Int = 20,
              with elements: [Data] = [] )
        {
            dlog(message: "mtu: \(mtu)", 
                 line: #line, function: #function, file: #fileID)

            self.mtu = mtu
            self.elements = elements
        }


        mutating func set( parent: Glasses )
        {
            self.parent = parent
        }


        mutating func enqueue(_ values: [UInt8])
        {
            dispatchQueue.sync(flags: .barrier)
            {
                elements.append(Data(values))
            }
        }


        // this function is called only when loading configuration, so isUpdating always true
        mutating func enqueueFile(_ file: String)
        {
            dispatchQueue.sync(flags: .barrier)
            {
                guard let isUpdating = parent?.isUpdating else { return }

                var tempQueue: [Data] = []

                let comps = file.components(separatedBy: "\n")

                for line in comps {
                    tempQueue.append(line.hexaData)
                }

                if isUpdating
                {
                    // we are setting configSize to provide progression
                    parent?.configSize = tempQueue.count
                    dlog(message: "configSize: \(elements.count)",
                         line: #line, function: #function, file: #fileID)
                }

                elements.append(contentsOf: tempQueue)
            }
        }

        mutating func dequeue() -> Data?
        {
            return dispatchQueue.sync(flags: .barrier)
            {
                guard !self.elements.isEmpty else
                {
                    return nil
                }

                let first = self.elements.removeFirst()

                if first.count <= mtu {
                    return first
                }

                let firstHead = Data(first[0...mtu-1])
                let firstTail = Data(first[mtu...first.count-1])

                self.elements.insert(firstTail, at: 0)

                return firstHead
            }
        }


        var head: Data?
        {
            return dispatchQueue.sync
            {
                return elements.first
            }
        }


        var tail: Data?
        {
            return dispatchQueue.sync
            {
                return elements.last
            }
        }
    }
}
