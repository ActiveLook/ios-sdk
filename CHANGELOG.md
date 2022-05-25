# CHANGELOG

## Version 4.2.3

### Fixes
- Loosing connection with the glasses during a version check will not block auto-reconnect anymore (tested only on checks, no updates)
- If the device's BLE is turned off while glasses are connected, they will auto-reconnect when the BLE is back on (non persistent)
- Mirrors Android's management of FlowControl status updates
- Flow control internal management
- Fix cancel connection on disconnected glasses

### Changes
- Add reboot delay as parameters
- Retry update on every connection

---

## Version 4.2.2

### New features
- Allows cancelling connection using `glasses` object
- New `serializedGlasses` object allowing reconnecting without scanning
- Allows cancelling connection using `serializedGlasses` object

### Changes
- Upon connection loss, always trigger the `onGlassesDisconnected()` callback

### Fixes
- All connection loss will trigger an auto-reconnect attempt, unless being initiated using `glasses.disconnect()`

---

## Version 4.2.1

### New features
- Adds an `UP_TO_DATE` state

### Changes
- Changes `progress` type to `Double` instead of `Int`

### Fixes
- Calls to `onProgressUpdate()` closures

---

## Version 4.2.0

### New features
- Include firmware update
    - get latest firmware from repository
- Include configuration update
    - get latest configuration from repository
- Add compatibility for watchOS

### Caveats
- Configuration update can sometime disconnect the glasses
    - Usually with big configurations

### Fixes
- Changes `imgList` `commandID`, and `ImageInfo` implementation to return correct `img ID`
- Implements `polyline()`
- Sets hardware in glasses initializer, and dispatch result on main if update not available
- Changes the way the MTU for BLE is calculated
- Updates `CommandID`'s `imgDelete` to `0x46`
- Adds entry in list of commands to handle

### Changes
- Bumps minimum iOS version to 13
