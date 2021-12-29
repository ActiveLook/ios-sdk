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

/// Information about a page.
public class PageInfo {

    /// The page id
    public let id: UInt8

    /// The page payload
    public let payload: [UInt8]

    init(_ id: UInt8, _ layoutIds: [UInt8], _ xs: [Int16], _ ys: [UInt8]) {
        self.id = id
        var payload: [UInt8] = [id]
        for i in (0..<layoutIds.count) {
            payload.append(layoutIds[i])
            payload += xs[i].asUInt8Array
            payload.append(ys[i])
        }
        self.payload = payload
    }

    init(_ payload: [UInt8]) {
        self.id = payload[0]
        self.payload = payload
    }

    internal static func fromCommandResponseData(_ data: CommandResponseData) -> PageInfo {
        guard data.count >= 1 else { return PageInfo(0, [], [], []) }
        return PageInfo(data)
    }
}
