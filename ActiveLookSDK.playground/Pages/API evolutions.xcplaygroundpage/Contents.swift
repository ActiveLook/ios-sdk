import Foundation
import ActiveLookSDK

// - Glasses protection (in case of disconnect)

// MARK - SDK updates public

public protocol SerializedData: Codable {
}

public extension ActiveLookSDK {
    func retrieveLastDiscoveredGlasses(from serializedData: SerializedData) -> DiscoveredGlasses? {
        return nil
    }

    func connect(
        onGlassesConnected connectionCallback: @escaping (Glasses) -> Void,
        onGlassesDisconnected disconnectionCallback: @escaping (UUID) -> Void, // Addition of argument. Glasses or UUID ?
        onConnectionError connectionErrorCallback: @escaping (Error) -> Void
    ) { }
}

public extension DiscoveredGlasses {
    // internal implementation
    var serializedData: some SerializedData { identifier.uuidString }
}

// internal implementation
extension String: SerializedData { }


// MARK: - Retrieve SDK

var activeLookSDK: ActiveLookSDK?

do {
    // swiftlint:disable:next multiline_arguments
    activeLookSDK = try ActiveLookSDK.shared(token: "") { _ in
        // TODO (Pierre Rougeot) 01/03/2022 Implement Firmware Update
    } onUpdateProgressCallback: { _ in
        // TODO (Pierre Rougeot) 01/03/2022 Implement Firmware Update
    } onUpdateSuccessCallback: { _ in
        // TODO (Pierre Rougeot) 01/03/2022 Implement Firmware Update
    } onUpdateFailureCallback: { _ in
        // TODO (Pierre Rougeot) 01/03/2022 Implement Firmware Update
    }
} catch {
    activeLookSDK = nil
}








// MARK: - Retrieve last discovered glasses

var lastDiscoveredGlasses: DiscoveredGlasses?
var lastDiscoveredGlassesPersistentSerializedData: SerializedData? // from user defaults

func retrieveLastDiscoveredGlasses() -> DiscoveredGlasses? {
    var glasses: DiscoveredGlasses?
    if let discoveredGlasses = lastDiscoveredGlasses {
        glasses = discoveredGlasses
    } else if let data = lastDiscoveredGlassesPersistentSerializedData {
        glasses = activeLookSDK?.retrieveLastDiscoveredGlasses(from: data)
    }
    lastDiscoveredGlasses = glasses
    lastDiscoveredGlassesPersistentSerializedData = glasses?.serializedData
    return glasses
}








// MARK: - Scan for new glasses

func scan(timeout: TimeInterval, _ completion: @escaping (DiscoveredGlasses?) -> Void) {
    activeLookSDK?.startScanning { discoveredGlasses in
        completion(discoveredGlasses)
    } onScanError: { error in
        print(error)
        completion(nil)
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
        activeLookSDK?.stopScanning()
    }
}






// MARK: - Connect to discovered glasses

let scanTimeout: TimeInterval = 30
var connectedGlasses: Glasses?

func connect(scanTimeOut: TimeInterval, _ completion: @escaping (Glasses?) -> Void) {
    if let discoveredGlasses = retrieveLastDiscoveredGlasses() {
        process(discoveredGlasses: discoveredGlasses, with: completion)
    } else {
        scan(timeout: scanTimeOut) { discoveredGlasses in
            process(discoveredGlasses: discoveredGlasses, with: completion)
        }
    }
}

func process(discoveredGlasses: DiscoveredGlasses?, with completion: @escaping (Glasses?) -> Void) {
    discoveredGlasses?.connect { glasses in
        connectedGlasses = glasses
        completion(glasses)
    } onGlassesDisconnected: {
        guard let glasses = connectedGlasses else { return }
        connectedGlasses = nil
        onGlassesDisconnection(glasses, completion: completion)
    } onConnectionError: { error in
        print(error)
        completion(nil)
    }
}

func onGlassesDisconnection(_ connectedGlasses: Glasses, completion: @escaping (Glasses?) -> Void) {
    // if relevant
    connect(scanTimeOut: scanTimeout, completion)
}

func onGlassesError(_ connectedGlasses: Glasses, completion: @escaping (Glasses?) -> Void) {
    // if relevant
    connect(scanTimeOut: scanTimeout, completion)
}



// MARK: - App Life Cycle

class ExtensionDelegate: NSObject /*, WKExtensionDelegate, ObservableObject */ {

    func applicationDidFinishLaunching() {
    }

    func applicationDidBecomeActive() {
        // if in preparation mode
        connect(scanTimeOut: scanTimeout) { _ in }
    }

    func applicationWillResignActive() {
        // if in preparation mode
        connectedGlasses?.disconnect()
        connectedGlasses = nil
    }

    func applicationDidEnterBackground() {
    }

    func applicationWillEnterForeground() {
    }
}

connect(scanTimeOut: 5) { glasses in
    guard let identifier = glasses?.identifier else { return }
    print(identifier)
}
