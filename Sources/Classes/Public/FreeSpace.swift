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
public class FreeSpace {

    /// The total available space
    public let totalSize: UInt32

    /// The available free space
    public let freeSpace: UInt32

    init(_ totalSize: UInt32, _ freeSpace: UInt32) {
        self.totalSize = totalSize
        self.freeSpace = freeSpace
    }

    internal static func fromCommandResponseData(_ data: CommandResponseData) -> FreeSpace {
        guard data.count >= 8 else { return FreeSpace(0, 0) }

        let totalSpace = UInt32.fromUInt32ByteArray(bytes: Array(data[0...3]))
        let freeSpace = UInt32.fromUInt32ByteArray(bytes: Array(data[4...7]))

        return FreeSpace(totalSpace, freeSpace)
    }
}
