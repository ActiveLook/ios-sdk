# ActiveLookSDK

## Requirements

In order to use the ActiveLook SDK for iOS, you should have XCode installed together
with [cocoapods](https://cocoapods.org).
The SDK is also available using SPM.

## License

See `LICENCE`.
_TLDR:_ [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

## Installation

### CocoaPods
To integrate ActiveLookSDK into your Xcode project using CocoaPods, specify it
in your Podfile:
```
pod 'ActiveLookSDK',
    :git => 'https://github.com/ActiveLook/ios-sdk.git',
    :tag = '4.2.2'
```

Then run the command:
`pod install'

An example Podfile is included in the `demo-app` repo available on github at
[demo-app](https://github.com/ActiveLook/demo-app)

### Swift Package Manager
To integrate ActiveLookSDK into your Xcode project using SPM, add a new package with the url https://github.com/ActiveLook/ios-sdk.git using the `main` branch.

### Info.plist
To access Core Bluetooth APIs on apps linked on or after iOS 13, fill in the
`NSBluetoothAlwaysUsageDescription` key in your app's `Info.plist`.

Also, add the `App Transport Security Settings` dictionary with the `Allow Arbitrary Loads` key set to `YES`.

## Example

To test the SDK, clone the [demo-app](https://github.com/ActiveLook/demo-app):
`git clone https://github.com/ActiveLook/demo-app.git`

## Documentation

The code is commented so that the documentation can be built on your machine using Xcode's `Build configuration` command, enabling symbolic documentation.

## Initialization

To start using the SDK, first import the ActiveLookSDK module:

```swift
import ActiveLookSDK
```

Then, use its `shared` property to access the shared singleton. This can be called from anywhere within your application.

```swift
var activeLook: ActiveLookSDK = ActiveLookSDK.shared
```
Then, use its `shared` property to access the shared singleton. This can be called from anywhere within your application.

## Scanning

To scan for available ActiveLook glasses, simply use `startScanning( onGlassesDiscovered: onScanError: )`.

When a device is discovered, the `onGlassesDiscovered` callback will be called.
Upon failure, the `onScanError` callback will be called instead.

You can handle these cases by providing closures as parameters:

```swift
activeLook.startScanning(
    onGlassesDiscovered: { [weak self] (discoveredGlasses: DiscoveredGlasses) in
        print("discovered glasses: \(discoveredGlasses.name)")
        self?.addDiscoveredGlasses(discoveredGlasses)

    }, onScanError: { (error: Error) in
        print("error while scanning: \(error.localizedDescription)")
    }
)
```
To stop scanning, call `stopScanning()`.

## Connect to ActiveLook glasses

To connect to a pair of discovered glasses, use the `connect(onGlassesConnected:onGlassesDisconnected:onConnectionError:)` method on the `DiscoveredGlasses` object.

If the connection is successful, the `onGlassesConnected` callback will be called and will return a `Glasses` object, which can then be used to get information about the connected ActiveLook glasses or send commands.

If the connection fails, the `onConnectionError` callback will be called instead.

Finally, if the connection to the glasses is lost at any point, later, while the app is running, the `onGlassesDisconnected` callback will be called.

```swift
discoveredGlasses.connect(
    onGlassesConnected: { (glasses: Glasses) in
        print("glasses connected: \(glasses.name)")
}, onGlassesDisconnected: {
        print("disconnected from glasses")
}, onConnectionError: { (error: Error) in
        print("error while connecting to glasses: \(error.localizedDescription)")
})
```

If you need to share the `Glasses` object between several View Controllers, and you find it hard or inconvenient to hold onto the `onGlassesDisconnected` callback, you can reset it or provide a new one by using the `onDisconnect()` method on the `Glasses` object:

```swift
glasses.onDisconnect { [weak self] in
    guard let self = self else { return }

    let alert = UIAlertController(title: "Glasses disconnected", message: "Connection to glasses lost", preferredStyle: .alert)
    self.present(alert, animated: true)
}
```

## Device information

To get information relative to discovered glasses as published over Bluetooth, you can access the following public properties:

```swift
// Print the name of the glasses
print(discoveredGlasses.name)

// Print the glasses' manufacturer id
print(discoveredGlasses.manufacturerId)

// Print the glasses' identifier
print(discoveredGlasses.identifier)
```

Once connected, you can access more information about the device such as its firmware version, the model number etc... by using the `getDeviceInformation()` method:

```swift
// Print the model number
print(connectedGlasses.getDeviceInformation().modelNumber)
```

## Commands

All available commands are exposed as methods in the `Glasses` class. Examples are available in the Example application.

Most commands require parameters to be sent.

```swift
// Power on the glasses
glasses.power(on: true)

// Set the display luminance level
glasses.luma(level: 15)

// Draw a circle at the center of the screen
glasses.circ(x: 152, y: 128, radius: 50)

// Enable gesture detection sensor
glasses.gesture(enabled: true)
```

When a response is expected from the glasses, a closure can be provided to the callback parameter. (The callback will be called asynchronously)

```swift
glasses.battery { (batteryLevel : Int) in
    print("current battery level: \(batteryLevel)")
}
```

## Notifications

It is possible to subscribe to three types of notifications from the glasses. Once notified, the corresponding closure is called, if provided.

* Battery level updates:
```swift
glasses.subscribeToBatteryLevelNotifications(onBatteryLevelUpdate: { (batteryLevel: Int) -> (Void) in
    print("battery level update: \(batteryLevel)")
})
```
-> An update is sent periodically, every 30 second.

* Gesture detection sensor triggered
```swift
glasses.subscribeToFlowControlNotifications(onFlowControlUpdate: { (flowControlState: FlowControlState) -> (Void) in
    print("flow control state update: \(flowControlState)")
})
```

* Flow control events (when the state of the flow control changes)
```swift
glasses.subscribeToSensorInterfaceNotifications(onSensorInterfaceTriggered: { () -> (Void) in
    print("sensor interface triggered")
})
```
-> Only non-internal states are passed thru. See `Public > ActiveLookType.swift : public enum FlowControlState{}` for more information.

## Disconnect

When done interacting with ActiveLook glasses, simply call the `disconnect()` method:

```swift
glasses.disconnect()
```
