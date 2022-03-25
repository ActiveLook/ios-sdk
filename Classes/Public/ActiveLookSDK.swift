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


// MARK: -  Type Alias

public typealias StartClosureSignature = (SdkGlassesUpdate) -> Void
public typealias ProgressClosureSignature = (SdkGlassesUpdate) -> Void
public typealias SuccessClosureSignature = (SdkGlassesUpdate) -> Void
public typealias FailureClosureSignature = (SdkGlassesUpdate) -> Void


/* The main entry point to interacting with ActiveLook glasses.

 The ActiveLookSDK class should be used as a singleton, and can be accessed via the `shared()` function.

 It uses the CBCentralManager to interact with ActiveLook glasses over Bluetooth and sets itself as its delegate.
*/

// MARK: -
public class ActiveLookSDK {


    // MARK: - Private properties

    private static var _shared: ActiveLookSDK!

    private var discoveredGlassesArray: [DiscoveredGlasses] = []
    private var glassesDiscoveredCallback: ((DiscoveredGlasses) -> Void)?
    private var connectedGlassesArray: [Glasses] = []

    private var didAskForScan: (glassesDiscoveredCallback: (DiscoveredGlasses) -> Void,
                                scanErrorCallback: (Error) -> Void)?

    private var didAskForSerializedGlassesReconnect: (serializedGlasses: SerializedGlasses,
                                                      timeoutDuration: Int16,
                                                      connectionCallback: (Glasses) -> Void,
                                                      disconnectionCallback: () -> Void,
                                                      connectionErrorCallback: (Error) -> Void)?

    private var updater: GlassesUpdater?
    private var networkMonitor: NetworkMonitor!

    // MARK: - Internal properties


    internal var centralManager: CBCentralManager!
    internal var centralManagerDelegate: CentralManagerDelegate // TODO: internal or private ?

    // TODO: SEPARATE GUP in SDKUpdateParameters and GUP (tied to a glasses object?) ? (220317)
    internal var updateParameters: GlassesUpdateParameters!


    // MARK: - LifeCycle

    private init(with parameters: GlassesUpdateParameters) {

        self.updateParameters = parameters
        self.centralManagerDelegate = CentralManagerDelegate()

        ActiveLookSDK._shared = self

        self.centralManagerDelegate.parent = self
        self.networkMonitor = NetworkMonitor.shared

        self.didAskForScan = nil
        self.didAskForSerializedGlassesReconnect = nil

        // TODO: Use a specific queue
        centralManager = CBCentralManager(delegate: self.centralManagerDelegate, queue: nil)
        networkMonitor.startMonitoring()
    }


    // MARK: - Public methods

    /// This is the method used to initialize the `ActiveLookSDK` singleton **and** access it later on.
    /// To initialize it, this function is called with all parameters set.
    /// To access it afterwards, just call it without any arguments: `ActiveLookSDK.shared()`
    ///
    /// - throws:
    ///     - `ActiveLookError.sdkInitMissingParameters`
    ///     if the function is called with incomplete parameters.
    ///     - `ActiveLookError.sdkCannotChangeParameters`
    ///     if the function is called more than once during the application's lifetime, with all the parameters correctly set.
    ///
    /// - parameters:
    ///     - token:  token used for authenticating with the update server.
    ///     - onUpdateStart:  callback asynchronously called when an update starts.
    ///     - onUpdateProgress:  callback asynchronously called when an update progress.
    ///     - onUpdateSuccess:  callback asynchronously called when an update succeed.
    ///     - onUpdateError:  callback asynchronously called when an update fails.
    ///
    ///  - returns: the `ActiveLookSDK`'s singleton
    ///
    public static func shared(token: String? = nil,
                              onUpdateStartCallback: StartClosureSignature? = nil,
                              onUpdateProgressCallback: ProgressClosureSignature? = nil,
                              onUpdateSuccessCallback: SuccessClosureSignature? = nil,
                              onUpdateFailureCallback: FailureClosureSignature? = nil) throws -> ActiveLookSDK
    {

        var updateParameters: GlassesUpdateParameters? = nil

        if token != nil,
           onUpdateStartCallback != nil,
           onUpdateProgressCallback != nil,
           onUpdateSuccessCallback != nil,
           onUpdateFailureCallback != nil
        {
            updateParameters = GlassesUpdateParameters(token!,
                                                       onUpdateStartCallback!,
                                                       onUpdateProgressCallback!,
                                                       onUpdateSuccessCallback!,
                                                       onUpdateFailureCallback!)
        }

        switch (_shared, updateParameters) {
        case let (i?, nil):
            return i

        case _ where (_shared != nil) && (updateParameters != nil):
            throw ActiveLookError.sdkCannotChangeParameters

        case _ where (_shared == nil) && (updateParameters != nil):
            _shared = ActiveLookSDK(with: updateParameters!)
            return _shared

        default:
            throw ActiveLookError.sdkInitMissingParameters
        }
    }


    /// Start scanning for ActiveLook glasses. Will keep scanning until `stopScanning()` is called.
    ///
    /// - Parameters:
    ///   - glassesDiscoveredCallback: A callback called asynchronously when glasses are discovered.
    ///   - scanErrorCallback: A callback called asynchronously when an scanning error occurs.
    ///
    public func startScanning(onGlassesDiscovered glassesDiscoveredCallback: @escaping (DiscoveredGlasses) -> Void,
                              onScanError scanErrorCallback: @escaping (Error) -> Void,
                              _ caller: String? = nil)
    {
        guard centralManager.state == .poweredOn else {
            if self.didAskForScan == nil && caller == nil {
                self.didAskForScan = (glassesDiscoveredCallback, scanErrorCallback)
            } else {
                scanErrorCallback(ActiveLookError.startScanningAlreadyCalled)
            }
            return
        }

        guard !centralManager.isScanning else {
            print("already scanning")
            return
        }

        if updater == nil {
            updater = GlassesUpdater()
        }

        self.didAskForScan = nil
        self.discoveredGlassesArray.removeAll()

        self.glassesDiscoveredCallback = glassesDiscoveredCallback
        print("starting scan")

        // Scanning with services list not working
        centralManager.scanForPeripherals(withServices: nil,
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }


    /// Check whether the ActiveLookSDK is currently scanning.
    /// - Returns: true if currently scanning, false otherwise.
    public func isScanning() -> Bool {
        return centralManager.isScanning
    }


    /// Stop scanning for ActiveLook glasses.
    public func stopScanning() {
        if centralManager.isScanning {
            print("stopping scan")
            centralManager.stopScan()
        }
    }


    /// Connect to `SerializedGlasses`
    ///
    /// Using this method, the `SDK` will connect directly to the serialized glasses,
    /// without having to go through the whole  `scan() → discover() → connect()` process.
    ///
    /// - parameters:
    ///     - serializedGlasses:   the glasses to attempt to connect to
    ///     - timeoutDuration:  **(optional)**   time in seconds before cancelling connection and calling `connectionErrorCallBack()`
    ///     - connectionCallback: A callback called asynchronously when the connection is successful. It returns the connected glasses
    ///     - disconnectionCallback: A callback called asynchronously when the connection to the device is lost.
    ///     - connectionErrorCallback: A callback called asynchronously when a connection error occurs. It returns either:
    ///
    ///       - `ActiveLookError.unserializeError`: if the method cannot unserialize the parameter
    ///
    ///       - `ActiveLookError.alreadyConnected`: if the glasses are already connected
    ///
    /// - important: If the `CBCentralManager.state` is not `.poweredOn` when the method is called, the call is cached and will be processed once the manager is available.
    /// - important: The timeout will start ticking once the `CBCentralManager.state` is `.poweredOn`.
    /// - important: The attempt to connect will **time out after 10 seconds by default** if no value is provided for the `timeoutDuration` argument, and no glasses have been connected.
    ///
    /// Usage:
    ///
    ///     let sg: SerializedGlasses = try glasses.getSerializedGlasses()
    ///
    ///     // will timeout after 10 seconds
    ///     sdk.shared().connect(using: sg,
    ///             onGlassesConnected: connectCbck,
    ///          onGlassesDisconnected: discoCbck,
    ///              onConnectionError: errorCbck)
    ///
    ///     // will timeout after 2 minutes
    ///     sdk.shared().connect(using: sg,
    ///                                 120,
    ///             onGlassesConnected: connectCbck,
    ///          onGlassesDisconnected: discoCbck,
    ///              onConnectionError: errorCbck)
    ///
    public func connect(using serializedGlasses: SerializedGlasses,
                        _ timeoutDuration: Int16 = 10,
                        onGlassesConnected connectionCallback: @escaping (Glasses) -> Void,
                        onGlassesDisconnected disconnectionCallback: @escaping () -> Void,
                        onConnectionError connectionErrorCallback: @escaping (Error) -> Void,
                        _ caller: String? = nil)
    {
        guard centralManager.state == .poweredOn else {
            if self.didAskForSerializedGlassesReconnect == nil && caller == nil {
                self.didAskForSerializedGlassesReconnect = (serializedGlasses,
                                                            timeoutDuration,
                                                            connectionCallback,
                                                            disconnectionCallback,
                                                            connectionErrorCallback)
            } else {
                connectionErrorCallback(ActiveLookError.connectUsingAlreadyCalled)
            }
            return
        }

        self.didAskForSerializedGlassesReconnect = nil

        if updater == nil {
            updater = GlassesUpdater()
        }

        var usGlasses: UnserializedGlasses

        do {
            usGlasses = try serializedGlasses.unserialize()
        } catch {
            connectionErrorCallback(ActiveLookError.unserializeError)
            return
        }

        guard let glassesUuid = UUID(uuidString: usGlasses.id) else {
            connectionErrorCallback(ActiveLookError.unserializeError)
            return
        }

        if let _ = connectedGlassesArray.first(where: { $0.identifier == glassesUuid }) {
            connectionErrorCallback(ActiveLookError.alreadyConnected)
            return
        }

        // the peripheral is still stored in the discoveredGlasses array
        if let dg = discoveredGlassesArray.first(where: { $0.identifier == glassesUuid })
        {
            centralManager.stopScan()

            dg.connect(onGlassesConnected: connectionCallback,
                       onGlassesDisconnected: disconnectionCallback,
                       onConnectionError: connectionErrorCallback)

            DispatchQueue.main.asyncAfter(deadline: .now() + Double(timeoutDuration)) {
                if dg.peripheral.state != .connected {
                    self.centralManager.cancelPeripheralConnection(dg.peripheral)
                    dg.connectionErrorCallback!(ActiveLookError.connectionTimeoutError)
                }
            }
            return
        }


        if let peripheral = centralManager.retrievePeripherals(withIdentifiers: [ glassesUuid ]).first
        {
            // the peripheral is still cached in CoreBluetooth's cache
            let dg = DiscoveredGlasses(peripheral: peripheral,
                                       centralManager: centralManager,
                                       name: usGlasses.name,
                                       manufacturerId: usGlasses.manId)

            discoveredGlassesArray.append(dg)
            centralManager.stopScan()

            dg.connect(onGlassesConnected: connectionCallback,
                       onGlassesDisconnected: disconnectionCallback,
                       onConnectionError: connectionErrorCallback)

            DispatchQueue.main.asyncAfter(deadline: .now() + Double(timeoutDuration)) {
                if dg.peripheral.state != .connected {
                    dg.connectionErrorCallback!(ActiveLookError.connectionTimeoutError)
                    self.centralManager.cancelPeripheralConnection(dg.peripheral)
                }
            }
            return
        }

        // we cannot reconstruct a discoveredGlasses from the SerializedGlasses
        // -> reconnect as if new peripheral
        connectionErrorCallback(ActiveLookError.cannotRetrieveGlasses)
    }


    #if DEBUG
    // NOT TO BE USED IN PRODUCTION! TO TEST AUTORECONNECT...
    public func cancelConnection() {
        let glasses = connectedGlassesArray.first!
        self.centralManager.cancelPeripheralConnection(glasses.peripheral)
    }
    #endif

    // MARK: - Private methods
    
    private func peripheralIsActiveLookGlasses(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data, manufacturerData.count >= 2 {
            return manufacturerData[0] == 0xFA && manufacturerData[1] == 0xDA
        }
        return false
    }


    private func discoveredGlasses(fromPeripheral peripheral: CBPeripheral) -> DiscoveredGlasses?
    {
        for glasses in discoveredGlassesArray {
            if glasses.peripheral == peripheral {
                return glasses
            }
        }
        return nil
    }


    private func connectedGlasses(fromPeripheral peripheral: CBPeripheral) -> Glasses?
    {
        for glasses in connectedGlassesArray
        {
            if glasses.peripheral == peripheral {
                return glasses
            }
        }
        return nil
    }


    private func updateGlasses()
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        guard let glasses = connectedGlassesArray.first
        else {
            fatalError("no glasses connected...")
        }

        guard let discoveredGlasses = discoveredGlasses(fromPeripheral: glasses.peripheral)
        else {
            fatalError("discoveredGlasses not found")
        }

        updater?.update(
            glasses,
            onReboot:
                {
                    dlog(message: "Firmware update Succeeded. Glasses are rebooting.",
                         line: #line, function: #function, file: #fileID)

                    // stopping scan to ensure state
                    self.centralManager.stopScan()

                    self.centralManager.connect(glasses.peripheral, options: nil)
                },
            onSuccess:
                {
                    dlog(message: "UPDATER DONE",
                         line: #line, function: #function, file: #fileID)

                    discoveredGlasses.connectionCallback?(glasses)

                    self.updateParameters.update(.upToDate)
                    self.updateParameters.reset()   // FIXME: can trigger warning '[connection] nw_resolver_start_query_timer_block_invoke [C1] Query fired: did not receive all answers in time for... in Downloader.swift'
                },
            onError:
                { error in
                    dlog(message: "UPDATER ERROR: \(error.localizedDescription)",
                         line: #line, function: #function, file: #fileID)

                    switch error {
                    case .networkUnavailable:
                        // network not available. No update possible, but glasses are still usable.
                        discoveredGlasses.connectionCallback?(glasses)

                        self.updateParameters.update(.updateFailed)

                    default:
                        discoveredGlasses.connectionErrorCallback?(ActiveLookError.sdkUpdateFailed)
                    }
                    discoveredGlasses.connectionCallback = nil
                    discoveredGlasses.connectionErrorCallback = nil
                    self.updateParameters.reset()   // FIXME: can trigger warning '[connection] nw_resolver_start_query_timer_block_invoke [C1] Query fired: did not receive all answers in time for... in Downloader.swift'
                })
    }


    // MARK: - CBCentralManagerDelegate
    
    internal class CentralManagerDelegate: NSObject, CBCentralManagerDelegate
    {
        weak var parent: ActiveLookSDK?

        public func centralManagerDidUpdateState(_ central: CBCentralManager)
        {
            print("central manager did update state: ", central.state.rawValue)
            
            guard central.state == .poweredOn
            else {
                parent?.didAskForScan?.scanErrorCallback(
                    ActiveLookError.bluetoothErrorFromState( state: central.state) )
                return
            }

            if let didAskForSGReconnect = parent?.didAskForSerializedGlassesReconnect {
                parent?.connect(using: didAskForSGReconnect.serializedGlasses,
                                didAskForSGReconnect.timeoutDuration,
                                onGlassesConnected: didAskForSGReconnect.connectionCallback,
                                onGlassesDisconnected: didAskForSGReconnect.disconnectionCallback,
                                onConnectionError: didAskForSGReconnect.connectionErrorCallback,
                                "centralManagerDidUpdateState()")
                return
            }

            if let didAskForScan = parent?.didAskForScan {
                parent?.startScanning(onGlassesDiscovered: didAskForScan.glassesDiscoveredCallback,
                                      onScanError: didAskForScan.scanErrorCallback,
                                      "centralManagerDidUpdateState()")
                return
            }
        }


        public func centralManager(_ central: CBCentralManager,
                                   didDiscover peripheral: CBPeripheral,
                                   advertisementData: [String: Any],
                                   rssi RSSI: NSNumber)
        {
            guard parent != nil,
                    parent!.peripheralIsActiveLookGlasses(peripheral: peripheral,
                                                          advertisementData: advertisementData)
            else {
                // print("ignoring non ActiveLook peripheral")
                return
            }

            let discoveredGlasses = DiscoveredGlasses(peripheral: peripheral,
                                                      centralManager: central,
                                                      advertisementData: advertisementData)

            guard parent?.discoveredGlasses(fromPeripheral: peripheral) == nil
            else {
                print("glasses already discovered")
                return
            }

            parent?.discoveredGlassesArray.append(discoveredGlasses)
            parent?.glassesDiscoveredCallback?(discoveredGlasses)
        }

        
        public func centralManager(_ central: CBCentralManager,
                                   didConnect peripheral: CBPeripheral)
        {
            guard let discoveredGlasses = parent?.discoveredGlasses(fromPeripheral: peripheral)
            else {
                print("connected to unknown glasses") // TODO Raise error ?
                return
            }

            central.stopScan()

            print("central manager did connect to glasses \(discoveredGlasses.name)")

            let glasses = Glasses(discoveredGlasses: discoveredGlasses)

            let glassesInitializer = GlassesInitializer()
            glassesInitializer.initialize( glasses,
                                           onSuccess:
                                            {
                if self.parent!.connectedGlassesArray.contains(where: { glasses in
                    guard glasses.peripheral == peripheral else { return false }
                    guard glasses.isIntentionalDisconnect == false else { return false }
                    return true})
                {
                    // auto-reconnect from unexpected disconnect

                    // change peripheral in connected glasses
                    let gl: Glasses = self.parent!.connectedGlassesArray.first!
                    gl.replacePeripheral(with: peripheral)
                    self.parent!.connectedGlassesArray.removeFirst()
                    self.parent?.connectedGlassesArray.append(gl)

                    // change peripheral in discovered glasses
                    let dg:DiscoveredGlasses = self.parent!.discoveredGlasses(fromPeripheral: peripheral)!
                    dg.replacePeripheral(with: peripheral)

                    // send new object to application
                    dg.connectionCallback?(glasses)

                } else {
                    self.parent?.connectedGlassesArray.append(glasses)
                    self.parent?.updateGlasses()
                }
            },
                                           onError:
                                            { (error) in
                dlog(message: "INITIALIZER ERROR",
                     line: #line, function: #function, file: #fileID)

                discoveredGlasses.connectionErrorCallback?(error)
                discoveredGlasses.connectionCallback = nil
                discoveredGlasses.connectionErrorCallback = nil
            } )
        }


        public func centralManager(_ central: CBCentralManager,
                                   didDisconnectPeripheral peripheral: CBPeripheral,
                                   error: Error?)
        {
            guard let glasses = parent?.connectedGlasses(fromPeripheral: peripheral) else {
                print("disconnected from unknown glasses")
                return
            }

            if glasses.isIntentionalDisconnect {
                // need to set to false in the event of reconnecting while glasses are still in memory
                glasses.isIntentionalDisconnect = false

                if let index = parent?.connectedGlassesArray.firstIndex(
                    where: { $0.identifier == glasses.identifier } )
                {
                    parent?.connectedGlassesArray.remove(at: index)
                }

                glasses.disconnectionCallback?()
                glasses.disconnectionCallback = nil

                print("central manager did disconnect from glasses \(glasses.name)")
                return
            }

            if let rp = central.retrievePeripherals(withIdentifiers: [peripheral.identifier]).first {
                dlog(message: "accidental disconnect - reconnecting shortly",
                     line: #line, function: #function, file: #fileID)
                central.connect(rp)
            }
        }


        public func centralManager(_ central: CBCentralManager,
                                   didFailToConnect peripheral: CBPeripheral,
                                   error: Error?)
        {
            guard let glasses = parent?.discoveredGlasses(fromPeripheral: peripheral)
            else {
                print("failed to connect to unknown glasses")
                return
            }
            
            print("central manager did fail to connect to glasses \(glasses.name) with error: ",
                  error?.localizedDescription ?? "")

            glasses.connectionErrorCallback?(error ?? ActiveLookError.unknownError)
            glasses.connectionErrorCallback = nil
        }
    }
}
