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


public enum SoftwareClass: String {
    case firmwares
    case configurations
}

internal enum SoftwareLocation: String {
    case device
    case remote
}

public struct HardwareProperties {
    let manufacturing: Manufacturing
    let serialNumber: Int
}

public struct Manufacturing {
    let year: Int
    let week: Int
}

public protocol SoftwareClassProtocol {
    var description: String { get }
}

public struct FirmwareVersion: SoftwareClassProtocol, Equatable {
    let major: Int
    let minor: Int
    let patch: Int
    var extra: String?
    var path: String?
    var error: Error?

    public var description: String {
        get {
            return "\(major).\(minor).\(patch)\(extra ?? "")"
        }
    }

    public var version: String {
        get {
            return "\(major).\(minor).\(patch)\(extra ?? "")"
        }
    }

    public var minVersion: String {
        get {
            return "\(major).\(minor).\(patch)"
        }
    }

    public static func ==(lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }

    public static func >(lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {

        if (lhs.major > rhs.major) {
            return true
        }

        if (lhs.major == rhs.major) && (lhs.minor > rhs.minor) {
            return true
        }

        if (lhs.major == rhs.major) && (lhs.minor == rhs.minor) && (lhs.patch > rhs.patch) {
            return true
        }

        return false
    }
}

public struct ConfigurationVersion: SoftwareClassProtocol, Equatable {
    let major: Int
    var path: String?
    var error: Error?

    public var description: String {
        get {
            return "\(major)"
        }
    }

    public static func ==(lhs: ConfigurationVersion, rhs: ConfigurationVersion) -> Bool {
        return lhs.major == rhs.major
    }

    public static func >(lhs: ConfigurationVersion, rhs: ConfigurationVersion) -> Bool {
        return (lhs.major > rhs.major)
    }
}

public struct SoftwareVersions {
    var firmware: FirmwareVersion
    var configuration: ConfigurationVersion
}


/// Information about the glasses
public struct GlassesVersion {

    /// The installed firmware version
    public var firmwareVersion: String {
        get {
            return softwares.firmware.description
        }
    }

    /// The installed firmware major
    public var fwMajor: Int {
        get {
            return softwares.firmware.major
        }
    }

    /// The installed firmware minor
    public var fwMinor: Int {
        get {
            return softwares.firmware.minor
        }
    }

    /// The installed firmware patch
    public var fwPatch: Int {
        get {
            return softwares.firmware.patch
        }
    }

    /// The year the glasses were manufactured
    public var manufacturingYear: Int {
        get {
            return hardware.manufacturing.year
        }
    }

    /// The week the glasses were manufactured
    public var manufacturingWeek: Int {
        get {
            return hardware.manufacturing.week
        }
    }

    /// The glasses serial number
    public var serialNumber: Int {
        get {
            return hardware.serialNumber
        }
    }

    // The glasses' hardware manufacturing properties
    public  var hardware : HardwareProperties

    // The glasses' softwares - Firmware AND Configuration - version
    public  var softwares : SoftwareVersions

    init(_ firmwareVersion: String,
         _ manufacturingYear: Int,
         _ manufacturingWeek: Int,
         _ serialNumber: Int,
         _ major : Int,
         _ minor : Int,
         _ patch : Int,
         _ extra : String )
    {

        let manufacturing = Manufacturing(year: manufacturingYear, week: manufacturingYear)
        self.hardware = HardwareProperties(manufacturing: manufacturing,
                                 serialNumber: serialNumber)

        let firmware = FirmwareVersion(major: major, minor: minor, patch: patch, extra: extra)
        let configuration = ConfigurationVersion(major: 0)
        self.softwares = SoftwareVersions(firmware: firmware, configuration: configuration)
    }


    static func fromCommandResponseData(_ data: CommandResponseData) -> GlassesVersion {
        guard data.count >= 9 else { return GlassesVersion("unknown", 0, 0, 0, 0, 0, 0, "") }

        let major = Int(data[0])
        let minor = Int(data[1])
        let patch = Int(data[2])
        let extra = String(decoding: [data[3]], as: UTF8.self)
        let firmwareVersion = "\(major).\(minor).\(patch)\(extra)"

        let manufacturingYear = Int(data[4])
        let manufacturingWeek = Int(data[5])

        let serialNumberBytes = Array(data[6...8])
        let serialNumber = Int.fromUInt24ByteArray(bytes: serialNumberBytes)

        return GlassesVersion( firmwareVersion,
                              manufacturingYear,
                              manufacturingWeek,
                              serialNumber,
                              major,
                              minor,
                              patch,
                              extra )
    }

}
