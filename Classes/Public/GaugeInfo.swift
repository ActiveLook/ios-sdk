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
public class GaugeInfo {

    /// The x coordinate of the gauge
    public let x: Int

    /// The y coordinate of the gauge
    public let y: Int

    /// The radius of the gauge
    public let r: UInt16

    /// The internal radius of the gauge
    public let rin: UInt16

    /// The start angle of the gauge
    public let start: UInt8

    /// The end angle of the gauge
    public let end: UInt8

    /// The orientation of the gauge
    public let clockwise: Bool

    init(_ x: Int, _ y: Int, _ r: UInt16, _ rin: UInt16, _ start: UInt8, _ end: UInt8, _ clockwise: Bool) {
        self.x = x
        self.y = y
        self.r = r
        self.rin = rin
        self.start = start
        self.end = end
        self.clockwise = clockwise
    }

    internal static func fromCommandResponseData(_ data: CommandResponseData) -> GaugeInfo {
        guard data.count >= 10 else { return GaugeInfo(0, 0, 0, 0, 0, 0, false) }

        let x = Int.fromUInt16ByteArray(bytes: Array(data[0...1]))
        let y = Int.fromUInt16ByteArray(bytes: Array(data[2...3]))
        let r = UInt16.fromUInt16ByteArray(bytes: Array(data[4...5]))
        let rin = UInt16.fromUInt16ByteArray(bytes: Array(data[6...7]))
        let start = data[8]
        let end = data[9]
        let clockwise = data[10] != 0

        return GaugeInfo(x, y, r, rin, start, end, clockwise)
    }
}
