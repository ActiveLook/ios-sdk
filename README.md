# ActiveLookSDK

## Requirements

In order to use the ActiveLook SDK for iOS, you should have XCode installed together
with [cocoapods](https://cocoapods.org).

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

### Info.plist
To access Core Bluetooth APIs on apps linked on or after iOS 13, include the
`NSBluetoothAlwaysUsageDescription` key in your app's `Info.plist`.

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

It is possible to subscribe to three types of notifications that the glasses will send over Bluetooth:
* Battery level updates (periodically, every 30 seconds)
* Gesture detection sensor triggered
* Flow control events (when the state of the flow control changes)

```swift
glasses.subscribeToBatteryLevelNotifications(onBatteryLevelUpdate: { (batteryLevel: Int) -> (Void) in
    print("battery level update: \(batteryLevel)")
})

glasses.subscribeToFlowControlNotifications(onFlowControlUpdate: { (flowControlState: FlowControlState) -> (Void) in
    print("flow control state update: \(flowControlState)")
})

glasses.subscribeToSensorInterfaceNotifications(onSensorInterfaceTriggered: { () -> (Void) in
    print("sensor interface triggered")
})
```

## Disconnect

When done interacting with ActiveLook glasses, simply call the `disconnect()` method:

```swift
glasses.disconnect()
```
