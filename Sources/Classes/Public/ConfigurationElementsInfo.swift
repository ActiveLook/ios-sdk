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

/// Information about free space.
public class ConfigurationElementsInfo {

    /// The configuration version
    public let version: UInt32

    /// The number of image in this configuration
    public let nbImg: UInt8

    /// The number of layout in this configuration
    public let nbLayout: UInt8

    /// The number of font in this configuration
    public let nbFont: UInt8

    /// The number of page in this configuration
    public let nbPage: UInt8

    /// The number of gauge in this configuration
    public let nbGauge: UInt8

    init(_ version: UInt32, _ nbImg: UInt8, _ nbLayout: UInt8, _ nbFont: UInt8, _ nbPage: UInt8, _ nbGauge: UInt8) {
        self.version = version
        self.nbImg = nbImg
        self.nbLayout = nbLayout
        self.nbFont = nbFont
        self.nbPage = nbPage
        self.nbGauge = nbGauge
    }

    internal static func fromCommandResponseData(_ data: CommandResponseData) -> ConfigurationElementsInfo {
        guard data.count >= 9 else { return ConfigurationElementsInfo(0, 0, 0, 0, 0, 0) }

        let version = UInt32.fromUInt32ByteArray(bytes: Array(data[0...3]))
        let nbImg = data[4]
        let nbLayout = data[5]
        let nbFont = data[6]
        let nbPage = data[7]
        let nbGauge = data[8]

        return ConfigurationElementsInfo(version, nbImg, nbLayout, nbFont, nbPage, nbGauge)
    }
}
