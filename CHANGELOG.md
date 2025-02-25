# CHANGELOG

## Version 4.5.5

### Fixes

- Skip update if we can assume local network without internet
  
## Version 4.5.4

### Breaking Change

- SDK init token parameter changed
  
### Fixes

- FW update issue
  
## Version 4.5.3

### Fixes

- Dispatch firmware & config download error closure on main thread

## Version 4.5.2

### Fixes
- Check battery level before glasses update
- Block config update if battery level < 10%
- Empty config line are not anymore queued
- Fix `cancelConnection` on `DiscoveredGlasses` & `serializedGlasses`
  
## Version 4.5.1

### Fixes
- `addSubCommandText` : add Null Terminated char to string length
- `widgetTargetLeft`: workaround to fix bmp position outside of the widget
- change FW API URL
  
## Version 4.5.0

### New features
- New commands :
  - `holdFlush` : When held, new display commands are stored in memory and are displayed when the graphic engine is flushed.
  - `layoutDisplayExtended`  & `layoutClearAndDisplayExtended` with `ExtraCmd`:  Extra commands allow you to add elements to an existing layout without saving the modification.
  - `anim` : delete, clear, display saved animations
  - `ImgSaveFmt`: new image save format `4bpp HeatShrink Save Comp`
  - `widget` : still under development, for debugging purpose (requirement : FW >= 4.11)
  
## Version 4.4.2

### Fixes
- Don't need anymore stuffing byte to flush glasses stack
  
## Version 4.4.1

### Fixes
- Hotfixe init TimeOutDuration

## Version 4.4.0

### New features
- Stack commands before sending to eyewear
- New commands :
  - `layoutClearAndDisplayExtended` : clear a layout before displaying it at a position
  - `layoutClearAndDisplay` : clear a layout before displaying it
  - `layoutClearExtended` : clear a layout at a position
  - `pageClearAndDisplay` : clear a page before displaying it
  - `imgSave` : save image in new format
  - `streamImg` : display an image without saving it
  - `polyline` : choose the thickness of your polyline

## Version 4.3.0

### Breaking changes
- Use an anonymous function to accept update

### Fixes
- Auto-reconnect of glasses after turning Bluetooth OFF/ON in Settings.app
- Firmware comparison using also major number
- Firmware comparison using .numeric Strings' compare option
- Connected to unknown glasses

## Version 4.2.5

### New features
- Display update ongoing while updating
- Do a cfgSet("ALooK") as first command.

### Fixes
- Fix not empty stack on connection in glasses
- Firmware update progress precision
- Configuration update progress precision
- Low battery error before update started
- Increase reboot delay
- Solve a reconnection issue involving phone's BLE activity change
- Make disconnect upon firmware update intentional
- Notify only onUpdateFailureCallback() if disconnect happens during glasses update
- Call disconnectionCallback() upon Bluetooth being powered off

### Changes
- Refactor .rebooting case
- Change notifications to align with android ones
- Change rebooting state to updatingFirmware = 100
- Initialize connection callbacks no more upon glasses initializer error

---

## Version 4.2.4.1

### Fixes
- fix: add a delay before reconnecting to FW until 4.3.2
- fix: generate configuration download path with full version

---

## Version 4.2.4

### New features
- During the update process, possibility to accept or deny an update if available, using the SDK's closure `onUpdateAvailableCallback() -> Bool`

### Changes
- If the given `token` is invalid, the update is aborted and the glasses are not connected.

---

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
