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

/// Information about the glasses
public struct GlassesVersion {

    /// The installed firmware version
    public let firmwareVersion: String

    /// The year the glasses were manufactured
    public let manufacturingYear: Int

    /// The week the glasses were manufactured
    public let manufacturingWeek: Int

    /// The glasses serial number
    public let serialNumber: Int

    init(_ firmwareVersion: String, _ manufacturingYear: Int, _ manufacturingWeek: Int, _ serialNumber: Int) {
        self.firmwareVersion = firmwareVersion
        self.manufacturingYear = manufacturingYear
        self.manufacturingWeek = manufacturingWeek
        self.serialNumber = serialNumber
    }

    internal static func fromCommandResponseData(_ data: CommandResponseData) -> GlassesVersion {
        guard data.count >= 9 else { return GlassesVersion("unknown", 0, 0, 0) }

        let majorVersion = Int(data[0])
        let minorVersion = Int(data[1])
        let patchVersion = Int(data[2])
        let versionSuffix = String(decoding: [data[3]], as: UTF8.self)
        let versionAsString = "\(majorVersion).\(minorVersion).\(patchVersion)\(versionSuffix)"

        let manufacturingYear = Int(data[4])
        let manufacturingWeek = Int(data[5])

        let serialNumberBytes = Array(data[6...8])
        let serialNumber = Int.fromUInt24ByteArray(bytes: serialNumberBytes)

        return GlassesVersion(versionAsString, manufacturingYear, manufacturingWeek, serialNumber)
    }
}
