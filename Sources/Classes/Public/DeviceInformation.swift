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

/// Device information published over BlueTooth
public struct DeviceInformation {

    /// The name of the device's manufacturer
    public var manufacturerName: String?

    /// The device's model number
    public var modelNumber: String?

    /// The device's serial number
    public var serialNumber: String?

    /// The device's hardware version
    public var hardwareVersion: String?

    /// The device's firmware version
    public var firmwareVersion: String?

    /// The device's software version
    public var softwareVersion: String?

    init() {}

    init(
        _ manufacturerName: String?,
        _ modelNumber: String?,
        _ serialNumber: String?,
        _ hardwareVersion: String?,
        _ firmwareVersion: String?,
        _ softwareVersion: String?
    ) {
        self.manufacturerName = manufacturerName
        self.modelNumber = modelNumber
        self.serialNumber = serialNumber
        self.hardwareVersion = hardwareVersion
        self.firmwareVersion = firmwareVersion
        self.softwareVersion = softwareVersion
    }
}
