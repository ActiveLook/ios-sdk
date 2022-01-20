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

/// The main entry point to interacting with ActiveLook glasses.
///
/// The ActiveLookSDK class should be used as a singleton, and can be accessed via the `shared()` function.
///
/// It uses the CBCentralManager to interact with ActiveLook glasses over Bluetooth and sets itself as its delegate.
///

public class ActiveLookSDK {


    // MARK: - Private properties

    private static var _shared: ActiveLookSDK!
    private var centralManager: CBCentralManager!
    private var centralManagerDelegate: CentralManagerDelegate
    private var glassesUpdater: GlassesUpdater!
    private var discoveredGlassesArray: [DiscoveredGlasses] = []
    private var connectedGlassesArray: [Glasses] = []

    private var glassesUpdateParameters: GlassesUpdateParameters!
    
    private var glassesDiscoveredCallback: ((DiscoveredGlasses) -> Void)?
    
    private var didAskForScan: (glassesDiscoveredCallback: (DiscoveredGlasses) -> Void,
                                   scanErrorCallback: (Error) -> Void)?
    
    // MARK: - Initialization

    private init(with glassesUpdateParameters: GlassesUpdateParameters) {

        self.glassesUpdateParameters = glassesUpdateParameters
        self.glassesUpdater = GlassesUpdater(with: glassesUpdateParameters)
        self.centralManagerDelegate = CentralManagerDelegate()
        self.centralManagerDelegate.parent = self
        self.didAskForScan = nil

        ActiveLookSDK._shared = self

        centralManager = CBCentralManager(delegate: self.centralManagerDelegate, queue: nil) // TODO: Use a specific queue
    }


    // MARK: - Private methods
    
    private func peripheralIsActiveLookGlasses(peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data, manufacturerData.count >= 2 {
            return manufacturerData[0] == 0xFA && manufacturerData[1] == 0xDA
        }
        return false
    }

    private func discoveredGlasses(fromPeripheral peripheral: CBPeripheral) -> DiscoveredGlasses? {
        for glasses in discoveredGlassesArray {
            if glasses.peripheral == peripheral {
                return glasses
            }
        }
        return nil
    }
    
    private func connectedGlasses(fromPeripheral peripheral: CBPeripheral) -> Glasses? {
        for glasses in connectedGlassesArray {
            if glasses.peripheral == peripheral {
                return glasses
            }
        }
        return nil
    }


    // MARK: - Public methods

    /// This is the method used to initialize the `ActiveLookSDK` singleton **and** access it later on.
    /// To initialize it, this function is called with all parameters set.
    /// To access it afterwards, just call it without any arguments: `ActiveLookSDK.shared()`
    /// - throws:
    ///     - `ActiveLookError.sdkInitMissingParameters`
    ///     if the function is called with incomplete parameters.
    ///     - `ActiveLookError.sdkCannotChangeParameters`
    ///     if the function is called more than once during the application's lifetime, with all the parameters correctly set.
    /// - parameters:
    ///     - token: The token used for authenticating with the firmware repository.
    ///     - onUpdateStart             Registered callback for update start event notification
    ///     - onUpdateProgress      Registered callback for update progress event notification.
    ///     - onUpdateSuccess       Registered callback for update success event notification.
    ///     - onUpdateError             Registered callback for update error event notification.
    ///  - returns: the `ActiveLookSDK`'s singleton
    ///
    public static func shared(token: String? = nil,
                       onUpdateStartCallback: (() -> Void)? = nil,
                       onUpdateProgressCallback: (() -> Void)? = nil,
                       onUpdateSuccessCallback: (() -> Void)? = nil,
                       onUpdateFailureCallback: (() -> Void)? = nil) throws -> ActiveLookSDK
    {

        var glassesUpdateParameters: GlassesUpdateParameters? = nil

        if token != nil,
           onUpdateStartCallback != nil,
           onUpdateProgressCallback != nil,
           onUpdateSuccessCallback != nil,
           onUpdateFailureCallback != nil
        {
            glassesUpdateParameters = GlassesUpdateParameters(token: token!,
                                                              onUpdateStartCallback: onUpdateStartCallback!,
                                                              onUpdateProgressCallback: onUpdateProgressCallback!,
                                                              onUpdateSuccessCallback: onUpdateSuccessCallback!,
                                                              onUpdateFailureCallback: onUpdateFailureCallback!)
        }

        switch (_shared, glassesUpdateParameters) {
        case let (i?, nil):
            return i
        case _ where (_shared != nil) && (glassesUpdateParameters != nil):
            throw ActiveLookError.sdkCannotChangeParameters
        case _ where (_shared == nil) && (glassesUpdateParameters != nil):
            _shared = ActiveLookSDK(with: glassesUpdateParameters!)
            return _shared
        default:
            throw ActiveLookError.sdkInitMissingParameters
        }
    }
    
    /// Start scanning for ActiveLook glasses. Will keep scanning until `stopScanning()` is called.
    /// - Parameters:
    ///   - glassesDiscoveredCallback: A callback called asynchronously when glasses are discovered.
    ///   - scanErrorCallback: A callback called asynchronously when an scanning error occurs.
    public func startScanning(onGlassesDiscovered glassesDiscoveredCallback: @escaping (DiscoveredGlasses) -> Void,
                              onScanError scanErrorCallback: @escaping (Error) -> Void,
                              _ caller: String? = nil) {

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
    

    // MARK: - CBCentralManagerDelegate
    
    internal class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
    
        weak var parent: ActiveLookSDK?
        
        public func centralManagerDidUpdateState(_ central: CBCentralManager) {
            print("central manager did update state: ", central.state.rawValue)
            
            guard central.state == .poweredOn else {
                parent?.didAskForScan?.scanErrorCallback(ActiveLookError.bluetoothErrorFromState(state: central.state))
                return
            }
            
            guard let didAskForScan = parent?.didAskForScan else {
                return
            }
            
            parent?.startScanning(onGlassesDiscovered: didAskForScan.glassesDiscoveredCallback,
                                  onScanError: didAskForScan.scanErrorCallback,
                                  "centralManagerDidUpdateState()")
        }

        public func centralManager(_ central: CBCentralManager,
                                   didDiscover peripheral: CBPeripheral,
                                   advertisementData: [String: Any],
                                   rssi RSSI: NSNumber) {
            guard parent != nil, parent!.peripheralIsActiveLookGlasses(peripheral: peripheral,
                                                                       advertisementData: advertisementData)
            else {
                print("ignoring non ActiveLook peripheral")
                return
            }
            
            guard parent?.discoveredGlasses(fromPeripheral: peripheral) == nil else {
                print("glasses already discovered")
                return
            }

            let discoveredGlasses = DiscoveredGlasses(peripheral: peripheral,
                                                      centralManager: central,
                                                      advertisementData: advertisementData)

            parent?.discoveredGlassesArray.append(discoveredGlasses)
            parent?.glassesDiscoveredCallback?(discoveredGlasses)
        }
        
        public func centralManager(_ central: CBCentralManager,
                                   didConnect peripheral: CBPeripheral) {

            parent?.centralManager.stopScan()

            guard let discoveredGlasses = parent?.discoveredGlasses(fromPeripheral: peripheral) else {
                print("connected to unknown glasses") // TODO Raise error ?
                return
            }

            print("central manager did connect to glasses \(discoveredGlasses.name)")


            let glasses = Glasses(discoveredGlasses: discoveredGlasses)
//            parent?.glassesUpdater.update(glasses: glasses)

            let glassesInitializer = GlassesInitializer(glasses: glasses)

            glassesInitializer.initialize(
            onSuccess: {
                print("glasses initialized! Updating!")
                self.parent?.glassesUpdater.update(glasses: glasses)

            },
            onError: { (error) in

            })

//            glassesInitializer.initialize(
//            onSuccess: {
//                self.parent?.connectedGlassesArray.append(glasses)
//                discoveredGlasses.connectionCallback?(glasses)
//                discoveredGlasses.connectionCallback = nil
//                discoveredGlasses.connectionErrorCallback = nil
//            },
//            onError: { (error) in
//                discoveredGlasses.connectionErrorCallback?(error)
//                discoveredGlasses.connectionCallback = nil
//                discoveredGlasses.connectionErrorCallback = nil
//            })


        }
        
        public func centralManager(_ central: CBCentralManager,
                                   didDisconnectPeripheral peripheral: CBPeripheral,
                                   error: Error?) {
            guard let glasses = parent?.connectedGlasses(fromPeripheral: peripheral) else {
                print("disconnected from unknown glasses")
                return
            }

            print("central manager did disconnect from glasses \(glasses.name)")

            glasses.disconnectionCallback?()
            glasses.disconnectionCallback = nil

            if let index = parent?.connectedGlassesArray.firstIndex(where: {$0.identifier == glasses.identifier}) {
                parent?.connectedGlassesArray.remove(at: index)
            }
        }

        public func centralManager(_ central: CBCentralManager,
                                   didFailToConnect peripheral: CBPeripheral,
                                   error: Error?) {
            guard let glasses = parent?.discoveredGlasses(fromPeripheral: peripheral) else {
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
