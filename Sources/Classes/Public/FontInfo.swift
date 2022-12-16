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

/// Data describing a font that can be saved on the device.
public class FontInfo {

    /// The id of the font
    public let id: UInt8

    /// The height of characters in pixels
    public let height: UInt8

    public init(id: UInt8, height: UInt8) {
        self.id = id
        self.height = height
    }

    internal static func fromCommandResponseData(_ data: CommandResponseData) -> [FontInfo] {
        var results: [FontInfo] = []
        var offset = 0
        while offset < data.count {
            results.append(FontInfo(id: data[offset], height: data[offset+1]))
            offset += 2
        }
        return results
    }
}
