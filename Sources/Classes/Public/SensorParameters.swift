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

/// Parameters of the optical sensor.
public class SensorParameters {

    /// The ALS array to compare to when luma is changed.
    public let alsArray: [UInt16]

    /// The ALS period.
    public let alsPeriod: UInt16

    /// The ranging period.
    public let rangingPeriod: UInt16

    public init(alsArray: [UInt16], alsPeriod: UInt16, rangingPeriod: UInt16) {
        self.alsArray = alsArray
        self.alsPeriod = alsPeriod < 250 ? 250 : alsPeriod
        self.rangingPeriod = rangingPeriod < 250 ? 250 : rangingPeriod
    }

    internal static func fromCommandResponseData(_ data: CommandResponseData) -> SensorParameters {
        guard data.count >= 22 else { return SensorParameters(alsArray: [], alsPeriod: 0, rangingPeriod: 0) }

        let alsArrayData = Array(data[0...17])
        var alsArray: [UInt16] = []

        for arrayItem in alsArrayData.chunked(into: 2) {
            alsArray.append(UInt16.fromUInt16ByteArray(bytes: [arrayItem[0], arrayItem[1]]))
        }

        let alsPeriod = UInt16.fromUInt16ByteArray(bytes: [data[18], data[19]])
        let rangingPeriod = UInt16.fromUInt16ByteArray(bytes: [data[20], data[21]])

        return SensorParameters(alsArray: alsArray, alsPeriod: alsPeriod, rangingPeriod: rangingPeriod)
    }
}
