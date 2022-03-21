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

    private var rebootingGlasses: Glasses?


    // MARK: - Internal properties

    // TODO: make networkMonitor private
    internal var networkMonitor: NetworkMonitor!

    internal var centralManager: CBCentralManager!
    internal var centralManagerDelegate: CentralManagerDelegate // TODO: internal or private ?

    internal var updater: GlassesUpdater? // TODO: internal or private ?
    internal var updateParameters: GlassesUpdateParameters!


    // MARK: - LifeCycle

    private init(with parameters: GlassesUpdateParameters) {

        self.updateParameters = parameters
        self.centralManagerDelegate = CentralManagerDelegate()

        ActiveLookSDK._shared = self

        self.centralManagerDelegate.parent = self
        self.networkMonitor = NetworkMonitor.shared

        self.didAskForScan = nil

        // TODO: Use a specific queue
        centralManager = CBCentralManager(delegate: self.centralManagerDelegate, queue: nil)
        networkMonitor.startMonitoring()
    }


    // MARK: - Public methods

    // This is the method used to initialize the `ActiveLookSDK` singleton **and** access it later on.
    // To initialize it, this function is called with all parameters set.
    // To access it afterwards, just call it without any arguments: `ActiveLookSDK.shared()`
    // - throws:
    //     - `ActiveLookError.sdkInitMissingParameters`
    //     if the function is called with incomplete parameters.
    //     - `ActiveLookError.sdkCannotChangeParameters`
    //     if the function is called more than once during the application's lifetime, with all the parameters correctly set.
    // - parameters:
    //     - token: The token used for authenticating with the firmware repository.
    //     - onUpdateStart             Registered callback for update start event notification
    //     - onUpdateProgress      Registered callback for update progress event notification.
    //     - onUpdateSuccess       Registered callback for update success event notification.
    //     - onUpdateError             Registered callback for update error event notification.
    //  - returns: the `ActiveLookSDK`'s singleton
    //
    public static func shared(token: String,
                              onUpdateStartCallback: @escaping StartClosureSignature,
                              onUpdateProgressCallback: @escaping ProgressClosureSignature,
                              onUpdateSuccessCallback: @escaping SuccessClosureSignature,
                              onUpdateFailureCallback: @escaping FailureClosureSignature) throws -> ActiveLookSDK {
        guard _shared == nil else { throw ActiveLookError.sdkCannotChangeParameters }

        _shared = ActiveLookSDK(
            with: GlassesUpdateParameters(
                token,
                onUpdateStartCallback,
                onUpdateProgressCallback,
                onUpdateSuccessCallback,
                onUpdateFailureCallback
            )
        )
        return _shared
    }
    
    public static func shared() throws -> ActiveLookSDK {
        guard let _shared = _shared else { throw ActiveLookError.sdkInitMissingParameters }
        return _shared
    }


    // Start scanning for ActiveLook glasses. Will keep scanning until `stopScanning()` is called.
    // - Parameters:
    //   - glassesDiscoveredCallback: A callback called asynchronously when glasses are discovered.
    //   - scanErrorCallback: A callback called asynchronously when an scanning error occurs.
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


    // Check whether the ActiveLookSDK is currently scanning.
    // - Returns: true if currently scanning, false otherwise.
    public func isScanning() -> Bool {
        return centralManager.isScanning
    }


    // Stop scanning for ActiveLook glasses.
    public func stopScanning() {
        if centralManager.isScanning {
            print("stopping scan")
            centralManager.stopScan()
        }
    }


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


    private func updateGlasses() {

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

                self.rebootingGlasses = glasses

                // stopping scan to ensure state
                self.centralManager.stopScan()
                self.centralManager.scanForPeripherals(withServices: nil,
                                                       options:
                                                        [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            },
            onSuccess:
                {
                    dlog(message: "UPDATER DONE",
                         line: #line, function: #function, file: #fileID)

                    discoveredGlasses.connectionCallback?(glasses)
                    discoveredGlasses.connectionCallback = nil
                    discoveredGlasses.connectionErrorCallback = nil

                    let sdkGU = SdkGlassesUpdate(for: discoveredGlasses,
                                                    state: State.UPDATING_CONFIGURATION,
                                                    progress: 100,
                                                    sourceFirmwareVersion: "sFwV",
                                                    targetFirmwareVersion: "tFwV",
                                                    sourceConfigurationVersion: "sCfgV",
                                                    targetConfigurationVersion: "tCfgV")

                    self.updateParameters.successClosure(sdkGU)
                    self.updateParameters.reset()
                },
            onError:
                { error in
                    dlog(message: "UPDATER ERROR: \(error.localizedDescription)",
                         line: #line, function: #function, file: #fileID)

                    switch error {
                    case .networkUnavailable:
                        // network not available. No update possible, but glasses are still usable.
                        discoveredGlasses.connectionCallback?(glasses)
                        discoveredGlasses.connectionCallback = nil
                        discoveredGlasses.connectionErrorCallback = nil

                        let sdkGU = SdkGlassesUpdate(for: discoveredGlasses,
                                                        state: State.UPDATING_CONFIGURATION,
                                                        progress: 100,
                                                        sourceFirmwareVersion: "sFwV",
                                                        targetFirmwareVersion: "tFwV",
                                                        sourceConfigurationVersion: "sCfgV",
                                                        targetConfigurationVersion: "tCfgV")

                        self.updateParameters.successClosure(sdkGU)
                        self.updateParameters.reset()

                    default:
                        discoveredGlasses.connectionErrorCallback?(ActiveLookError.sdkUpdateFailed)
                        discoveredGlasses.connectionCallback = nil
                        discoveredGlasses.connectionErrorCallback = nil
                    }
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
            
            guard let didAskForScan = parent?.didAskForScan
            else {
                return
            }
            
            parent?.startScanning(onGlassesDiscovered: didAskForScan.glassesDiscoveredCallback,
                                  onScanError: didAskForScan.scanErrorCallback,
                                  "centralManagerDidUpdateState()")
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
                if let rebootingGlasses = parent?.rebootingGlasses,
                   rebootingGlasses.peripheral.identifier == peripheral.identifier
                {
                    dlog(message: "glasses are updating and have rebooted",
                         line: #line, function: #function, file: #fileID)
                    parent?.rebootingGlasses = nil
                    parent?.stopScanning()

                    central.connect(peripheral, options: nil)
                }
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
                self.parent?.connectedGlassesArray.append(glasses)
                self.parent?.updateGlasses()
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


            if let index = parent?.connectedGlassesArray.firstIndex(
                where: { $0.identifier == glasses.identifier } )
            {
                parent?.connectedGlassesArray.remove(at: index)
            }

            // glasses are rebooting. Will reconnect shorter...
            guard let updateParameters = parent?.updateParameters, updateParameters.state != .rebooting
            else {
                if let index = parent?.connectedGlassesArray.firstIndex(
                    where: { $0.identifier == glasses.identifier } )
                {
                    print("removed connected glasses...")
                    parent?.connectedGlassesArray.remove(at: index)
                }
                return
            }

            glasses.disconnectionCallback?()
            glasses.disconnectionCallback = nil

            if let index = parent?.connectedGlassesArray.firstIndex(
                where: { $0.identifier == glasses.identifier } )
            {
                parent?.connectedGlassesArray.remove(at: index)
            }
            print("central manager did disconnect from glasses \(glasses.name)")
            print("with error \(String(describing: error))")
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
