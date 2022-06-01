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
public typealias UpdateAvailableClosureSignature = (SdkGlassesUpdate) -> Bool
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
    ///     - onUpdateAvailableCallback: callback asynchronously called when an update is available.
    ///         - returns: `true` for the update to be performed.
    ///         - returns: `false` for not performing the update, and the glasses are not connected.
    ///     - onUpdateProgress:  callback asynchronously called when an update progress.
    ///     - onUpdateSuccess:  callback asynchronously called when an update succeed.
    ///     - onUpdateError:  callback asynchronously called when an update fails.
    ///
    ///  - returns: the `ActiveLookSDK`'s singleton
    ///
    ///  - important: if the token is invalid, the glasses will not be connected.
    ///
    public static func shared(token: String? = nil,
                              onUpdateStartCallback: StartClosureSignature? = nil,
                              onUpdateAvailableCallback: UpdateAvailableClosureSignature? = nil,
                              onUpdateProgressCallback: ProgressClosureSignature? = nil,
                              onUpdateSuccessCallback: SuccessClosureSignature? = nil,
                              onUpdateFailureCallback: FailureClosureSignature? = nil) throws -> ActiveLookSDK
    {

        var updateParameters: GlassesUpdateParameters? = nil

        if token != nil,
           onUpdateStartCallback != nil,
           onUpdateAvailableCallback != nil,
           onUpdateProgressCallback != nil,
           onUpdateSuccessCallback != nil,
           onUpdateFailureCallback != nil
        {
            updateParameters = GlassesUpdateParameters(token!,
                                                       onUpdateStartCallback!,
                                                       onUpdateAvailableCallback!,
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
    /// without having to `scan() → discover()` before connecting.
    ///
    /// - parameters:
    ///     - serializedGlasses: the glasses to attempt to connect to
    ///     - connectionCallback: callback called asynchronously when the glasses are connected. It returns the connected glasses
    ///     - disconnectionCallback: callback called asynchronously when the connection to the device is lost.
    ///     - connectionErrorCallback: callback called asynchronously when a connection error occurs. It returns either:
    ///       - `ActiveLookError.unserializeError` : if the method cannot unserialize the parameter
    ///       - `ActiveLookError.alreadyConnected` : if the glasses are already connected
    ///       - `ActiveLookError.cannotRetrieveGlasses` : if the glasses cannot be retrieved. Need to `scan() -> ...`
    ///
    /// - important: If the `CBCentralManager.state` is not `.poweredOn` when the method is called, the call is cached and
    ///     will be processed once the manager is available.
    ///
    /// Usage:
    ///
    ///     let sg: SerializedGlasses = try glasses.getSerializedGlasses()
    ///
    ///     sdk.shared().connect(using: sg,
    ///             onGlassesConnected: connectCbck,
    ///          onGlassesDisconnected: discoCbck,
    ///              onConnectionError: errorCbck)
    ///
    public func connect(using serializedGlasses: SerializedGlasses,
                        onGlassesConnected connectionCallback: @escaping (Glasses) -> Void,
                        onGlassesDisconnected disconnectionCallback: @escaping () -> Void,
                        onConnectionError connectionErrorCallback: @escaping (Error) -> Void,
                        _ caller: String? = nil)
    {
        guard centralManager.state == .poweredOn else {
            if self.didAskForSerializedGlassesReconnect == nil && caller == nil {
                self.didAskForSerializedGlassesReconnect = (serializedGlasses,
                                                            connectionCallback,
                                                            disconnectionCallback,
                                                            connectionErrorCallback)
            } else {
                connectionErrorCallback(ActiveLookError.connectUsingAlreadyCalled)
            }
            return
        }

        self.didAskForSerializedGlassesReconnect = nil

        // FIXME: fix to prevent uninitialized updater, but not optimal. Find where to initialize it CORRECTLY!
        if updater == nil {
            updater = GlassesUpdater()
        }

        guard let usG = try? serializedGlasses.unserialize()
        else {
            connectionErrorCallback(ActiveLookError.unserializeError)
            return
        }

        guard let gUuid = UUID(uuidString: usG.id) else {
            connectionErrorCallback(ActiveLookError.unserializeError)
            return
        }

        if let _ = connectedGlassesArray.first(where: { $0.identifier == gUuid }) {
            connectionErrorCallback(ActiveLookError.alreadyConnected)
            return
        }

        var dGlasses: DiscoveredGlasses

        if let dg = discoveredGlassesArray.first(where: { $0.identifier == gUuid }) {
            // the peripheral is still stored in the discoveredGlasses array
            dGlasses = dg
        }
        else if let dg = DiscoveredGlasses(with: serializedGlasses, centralManager: centralManager) {
            // the peripheral is still cached in CoreBluetooth's cache
            dGlasses = dg
            discoveredGlassesArray.append(dGlasses)
        } else {
            // we cannot reconstruct a discoveredGlasses from the SerializedGlasses
            // -> reconnect as if new peripheral
            connectionErrorCallback(ActiveLookError.cannotRetrieveGlasses)
            return
        }

        dGlasses.connect(onGlassesConnected: connectionCallback,
                         onGlassesDisconnected: disconnectionCallback,
                         onConnectionError: connectionErrorCallback)
    }


    /// Cancel a pending connection to `discoveredGlasses`.
    ///
    /// - parameter discoveredGlasses: the glasses to cancel pending connection to.
    ///
    /// - throws
    ///     - `ActiveLookError.alreadyConnected`: if glasses are already connected
    ///
    /// - important: if a `glasses` object has already been returned, you need to
    /// use `glasses.disconnect()` instead.
    ///
    /// Usage:
    ///
    ///     sdk.cancelConnection(discoveredGlasses)
    ///
    public func cancelConnection(_ discoveredGlasses: DiscoveredGlasses) throws
    {
        let dgUUID = discoveredGlasses.identifier

        let connectedDevices = retrieveBLEConnectedGlasses()

        if nil != connectedDevices.first(where: { $0.identifier == dgUUID }) {
            throw ActiveLookError.alreadyConnected
        }

        centralManager.cancelPeripheralConnection(discoveredGlasses.peripheral)
    }


    /// Cancel a pending connection to `serializedGlasses`.
    ///
    /// - parameter serializedGlasses: the glasses to cancel pending connection to.
    ///
    /// - throws
    ///     - `ActiveLookError.unserializeError`: if the method cannot unserialize the parameter
    ///     - `ActiveLookError.alreadyConnected`: if glasses are already connected.
    ///
    /// - important: if `glasses` are connected, use `glasses.disconnect()`.
    /// - important: it is impossible to cancel a connection while an update is ongoing.
    ///
    /// Usage:
    ///
    ///     sdk.cancelConnection(serializedGlasses)
    ///
    public func cancelConnection(_ serializedGlasses: SerializedGlasses) throws
    {
        guard let usG = try? serializedGlasses.unserialize()
        else {
            throw ActiveLookError.unserializeError
        }

        guard let gUUID = UUID(uuidString: usG.id) else {
            throw ActiveLookError.unserializeError
        }

        let connectedDevices = retrieveBLEConnectedGlasses()

        if nil != connectedDevices.first(where: { $0.identifier == gUUID }) {
            // the glasses are already connected -> use glasses.disconnect() instead
            throw ActiveLookError.alreadyConnected
        }

        guard let rp = centralManager.retrievePeripherals(withIdentifiers: [gUUID]).first
        else {
            throw ActiveLookError.cannotRetrieveGlasses
        }

        centralManager.cancelPeripheralConnection(rp)
    }

    // MARK: - Private methods
    
    private func peripheralIsActiveLookGlasses(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data, manufacturerData.count >= 2 {
            return manufacturerData[0] == 0xFA && manufacturerData[1] == 0xDA
        }
        return false
    }

    private func retrieveBLEConnectedGlasses() -> [CBPeripheral] {
        let gas = CBUUID.GenericAccessService
        let dis = CBUUID.DeviceInformationService
        let bs = CBUUID.BatteryService

        let connectedDevices = centralManager.retrieveConnectedPeripherals(withServices: [gas, dis, bs])

        return connectedDevices
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


    private func updateInitializedGlasses(_ glasses: Glasses)
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        // TODO: check if glasses already in connected array...
        if let index = connectedGlassesArray.firstIndex(where: { cGlasses in
            glasses.peripheral.identifier == cGlasses.peripheral.identifier
        }) {
            connectedGlassesArray.remove(at: index)
        }

        connectedGlassesArray.append(glasses)

        guard let discoveredGlasses = discoveredGlasses(fromPeripheral: glasses.peripheral)
        else {
            fatalError("discoveredGlasses not found")
        }

        updater?.update(
            glasses,
            onReboot:
                { delay in
                    dlog(message: "Firmware update Succeeded. Glasses are rebooting.",
                         line: #line, function: #function, file: #fileID)

                    // stopping scan to ensure state
                    self.centralManager.stopScan()

                    DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(delay)) {
                        self.centralManager.connect(glasses.peripheral, options: nil)
                    }
                },
            onSuccess:
                {
                    dlog(message: "UPDATER DONE",
                         line: #line, function: #function, file: #fileID)

                    discoveredGlasses.connectionCallback?(glasses)
                    self.updateParameters.notify(.upToDate)
                    self.updateParameters.reset()   // FIXME: can trigger warning '[connection] nw_resolver_start_query_timer_block_invoke [C1] Query fired: did not receive all answers in time for... in Downloader.swift'
                },
            onError:
                { error in
                    dlog(message: "UPDATER ERROR: \(error.localizedDescription)",
                         line: #line, function: #function, file: #fileID)

                    switch error {
                    case .networkUnavailable:
                        // network not available. Update not possible, but glasses are still usable.

                        discoveredGlasses.connectionCallback?(glasses)
                        self.updateParameters.notify(.updateFailed)

                    case .connectionLost:
                        // connection lost while updating -> reconnect asap
                        self.centralManager.connect(glasses.peripheral)

                    default:
                        discoveredGlasses.connectionErrorCallback?(ActiveLookError.sdkUpdateFailed)
                        self.updateParameters.notify(.updateFailed)
                    }
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

            guard let parent = parent else {
                fatalError("cannot retrieve parent instance")
            }

            guard central.state == .poweredOn
            else {
                parent.didAskForScan?.scanErrorCallback(
                    ActiveLookError.bluetoothErrorFromState( state: central.state) )
                return
            }

            if let connectedGlasses = parent.connectedGlassesArray.first {
                // a pair of glasses was connected when bluetooth was turned of. Reconnect...
                central.connect(connectedGlasses.peripheral)
                return
            }

            if let didAskForSGReconnect = parent.didAskForSerializedGlassesReconnect {
                parent.connect(using: didAskForSGReconnect.serializedGlasses,
                                onGlassesConnected: didAskForSGReconnect.connectionCallback,
                                onGlassesDisconnected: didAskForSGReconnect.disconnectionCallback,
                                onConnectionError: didAskForSGReconnect.connectionErrorCallback,
                                "centralManagerDidUpdateState()")
                return
            }

            if let didAskForScan = parent.didAskForScan {
                parent.startScanning(onGlassesDiscovered: didAskForScan.glassesDiscoveredCallback,
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
            guard let parent = parent else {
                fatalError("cannot retrieve parent instance")
            }
            guard parent.peripheralIsActiveLookGlasses(peripheral: peripheral,
                                                       advertisementData: advertisementData)
            else {
                // print("ignoring non ActiveLook peripheral")
                return
            }

            let discoveredGlasses = DiscoveredGlasses(peripheral: peripheral,
                                                      centralManager: central,
                                                      advertisementData: advertisementData)

            guard parent.discoveredGlasses(fromPeripheral: peripheral) == nil
            else {
                print("glasses already discovered")
                return
            }

            parent.discoveredGlassesArray.append(discoveredGlasses)
            parent.glassesDiscoveredCallback?(discoveredGlasses)
        }

        
        public func centralManager(_ central: CBCentralManager,
                                   didConnect peripheral: CBPeripheral)
        {
            guard let parent = parent else {
                fatalError("cannot retrieve parent instance")
            }

            guard let discoveredGlasses: DiscoveredGlasses = parent.discoveredGlasses(fromPeripheral: peripheral)
            else {
                print("connected to unknown glasses") // TODO: Raise error ?
                return
            }

            central.stopScan()

            // FIXME: / TODO DOES USING `retrievePeripheral(with: [])` DISPENSE US FROM RE-INITIALIZING THE PERIPHERAL ?
            // retrievedPeripheral has all the services cached, exact?
            // -> create another `glassesInitializer.initialize()` to reconstruct the object from cache
            // and get rid of the discover/didDiscover dance?

            let glasses = Glasses(discoveredGlasses: discoveredGlasses)

            let glassesInitializer = GlassesInitializer()
            glassesInitializer.initialize( glasses,
                                           onSuccess:
                                            {
                print("central manager did connect to glasses \(discoveredGlasses.name)")
                parent.updateInitializedGlasses(glasses)
            },
                                           onError:
                                            { (error) in
                dlog(message: "INITIALIZER ERROR",
                     line: #line, function: #function, file: #fileID)

                discoveredGlasses.connectionErrorCallback?(error)

                discoveredGlasses.connectionCallback = nil
                discoveredGlasses.disconnectionCallback = nil
                discoveredGlasses.connectionErrorCallback = nil
            } )
        }


        public func centralManager(_ central: CBCentralManager,
                                   didDisconnectPeripheral peripheral: CBPeripheral,
                                   error: Error?)
        {
            guard let parent = parent else {
                fatalError("cannot retrieve parent instance")
            }

            guard let glasses = parent.connectedGlasses(fromPeripheral: peripheral) else {
                print("disconnected from unknown glasses")
                if parent.updateParameters.isUpdating() {
                    parent.updater?.abort()
                    parent.updateParameters.notify(.updateFailed)
                    parent.updateParameters.reset()
                }
                return
            }

            if let index = parent.connectedGlassesArray.firstIndex(
                where: { $0.identifier == glasses.identifier } )
            {
                parent.connectedGlassesArray.remove(at: index)
            }

            print("central manager did disconnect from glasses \(glasses.name)")

            glasses.disconnectionCallback?()

            if parent.updateParameters.isUpdating()
            {
                parent.updater?.abort()
                parent.updateParameters.notify(.updateFailed)
                parent.updateParameters.reset()
            }

            if !glasses.isIntentionalDisconnect {
                print("unwanted disconnect: reconnecting as soon as possible")
                central.connect(peripheral)
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
