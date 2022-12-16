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

/// A representation of ActiveLook® glasses, discovered while scanning for Bluetooth devices.
///
/// Glasses can be discovered while scanning for ActiveLook® devices using the ActiveLookSDK class.
/// Once discovered, it is possible to connect to them by calling the connect(glasses:) method on the discovered object.
///
/// Once connected, the `onGlassesConnected` callback of the connect method will be called.
/// Upon error, the `onConnectionError` callback of the connect method will be called instead.
/// If the connection is lost, the `onGlassesDisconnected` callback of the connect method will be called.
///
/// Note: This callback can also be set / changed via the `onDisconnect() method`.
///
/// Once connected, the connection callback will return a `Glasses` object, which can then be used to send command to the ActiveLook® glasses.
///
public class DiscoveredGlasses {

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

    internal var connectionCallback: ((Glasses) -> Void)?
    internal var disconnectionCallback: (() -> Void)?
    internal var connectionErrorCallback: ((Error) -> Void)?

    // MARK: - Initializers

    internal init(peripheral: CBPeripheral, centralManager: CBCentralManager, advertisementData: [String: Any]) {
        self.identifier = peripheral.identifier
        self.name = (advertisementData["kCBAdvDataLocalName"] as? String) ?? "Unnamed glasses"
        self.manufacturerId = (advertisementData["kCBAdvDataManufacturerData"] as? Data)?.hexEncodedString() ?? "Unknown"

        self.peripheral = peripheral
        self.centralManager = centralManager
    }

    internal init(peripheral: CBPeripheral, centralManager: CBCentralManager, name: String, manufacturerId: String) {
        self.identifier = peripheral.identifier
        self.name = name
        self.manufacturerId = manufacturerId

        self.peripheral = peripheral
        self.centralManager = centralManager
    }

    internal init?(with serializedGlasses: SerializedGlasses, centralManager: CBCentralManager) {

        guard let usG = try? serializedGlasses.unserialize()
        else {
            // throw ActiveLookError.unserializeError
            return nil
        }

        guard let gUuid = UUID(uuidString: usG.id)
        else {
            // throw ActiveLookError.unserializeError
            return nil
        }

        guard let p = centralManager.retrievePeripherals(withIdentifiers: [ gUuid ]).first
        else {
            return nil
        }

        self.peripheral = p
        self.identifier = p.identifier

        self.name = usG.name
        self.manufacturerId = usG.manId

        self.centralManager = centralManager
    }


    // MARK: - Public methods

    /// Connect to the discovered glasses. Once the connection has been established over Buetooth,
    /// the glasses still need to be initialized before being considered as 'connected'.
    /// If this step takes too long, a timeout error will be issued via the `onConnectionError` callback.
    ///
    /// If successful, a `Glasses` object representing connected glasses is returned and can be used to
    /// send commands to ActiveLook glasses.
    ///
    ///   - connectionCallback: A callback called asynchronously when the connection is successful.
    ///   - disconnectionCallback: A callback called asynchronously when the connection to the device is lost.
    ///   - connectionErrorCallback: A callback called asynchronously when a connection error occurs.
    public func connect(
        onGlassesConnected connectionCallback: @escaping (Glasses) -> Void,
        onGlassesDisconnected disconnectionCallback: @escaping () -> Void,
        onConnectionError connectionErrorCallback: @escaping (Error) -> Void
    ) {
        self.connectionCallback = connectionCallback
        self.disconnectionCallback = disconnectionCallback
        self.connectionErrorCallback = connectionErrorCallback

        guard self.centralManager.state == .poweredOn else {
            connectionErrorCallback(ActiveLookError.bluetoothErrorFromState(state: centralManager.state))
            return
        }

        print("connecting to glasses ", name)
        centralManager.connect(peripheral, options: nil)
    }
}
