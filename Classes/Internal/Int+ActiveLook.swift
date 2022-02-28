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

extension Int {

    /// Is returning the same output as `asUInt8Array`.
    /// Not tested performance wise...
    var byteArray: [UInt8] {
        withUnsafeBytes(of: self.bigEndian) {
            Array($0)
        }
    }
    
    var asUInt8Array: [UInt8] {
        let firstByte = UInt8(truncatingIfNeeded: self >> 24)
        let secondByte = UInt8(truncatingIfNeeded: self >> 16)
        let thirdByte = UInt8(truncatingIfNeeded: self >> 8)
        let fourthByte = UInt8(truncatingIfNeeded: self)
        return [firstByte, secondByte, thirdByte, fourthByte]
    }

    internal static func fromUInt16ByteArray(bytes: [UInt8]) -> Int {
        guard bytes.count >= 2 else { return 0 }

        return Int(bytes[0]) << 8 + Int(bytes[1])
    }

    internal static func fromUInt24ByteArray(bytes: [UInt8]) -> Int {
        guard bytes.count >= 3 else { return 0 }

        return Int(bytes[0]) << 16 + Int(bytes[1]) << 8 + Int(bytes[2])
    }

    internal static func fromUInt32ByteArray(bytes: [UInt8]) -> Int {
        guard bytes.count >= 4 else { return 0 }

        return Int(bytes[0]) << 24 + Int(bytes[1]) << 16 + Int(bytes[2]) << 8 + Int(bytes[3])
    }
}
