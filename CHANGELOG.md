# CHANGELOG

## Version 4.2.1

### New features
- Add an up to date state

### Changes
- Make progress a double instead of an integer

### Fixes
- Calls to progress update callbacks

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
fix: change imgList command ID, and ImageInfo implementation to return correct img ID
fix: implement polyline()
fix: set hardware in glasses initializer, and dispatch result on main if update not available
changes the way the MTU for BLE is calculated
fix: update CommandID's imgDelete to 0x46
fix: add lists commands to handled commands

### Changes
- Minimum iOS version upgrade to 13
