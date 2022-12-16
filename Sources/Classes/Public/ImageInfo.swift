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

/// Information about an Image. Not an actual image object.
public class ImageInfo {

    /// The image id
    public let id: Int

    /// The image width in pixels
    public let width: Int

    /// The image height in pixels
    public let height: Int

    init(_ id: Int, _ width: Int, _ height: Int) {
        self.id = id
        self.width = width
        self.height = height
    }

    internal static func fromCommandResponseData(_ data: CommandResponseData) -> ImageInfo {
        guard data.count >= 5 else { return ImageInfo(0, 0, 0) }

        let id = Int(data[0])
        let width = Int.fromUInt16ByteArray(bytes: [data[1], data[2]])
        let height = Int.fromUInt16ByteArray(bytes: [data[3], data[4]])

        return ImageInfo(id, width, height)
    }
}
