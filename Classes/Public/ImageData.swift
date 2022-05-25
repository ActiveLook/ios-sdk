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

/// Data describing an image that can be saved on the device.
public class ImageData {
    
    /// The width of the image
    public let width: UInt16
    
    /// The encoded data representing the image
    public let data: [UInt8]
    
    public let size: UInt32
    
    public init(width: UInt16, data: [UInt8]) {
        self.width = width
        self.data = data
        self.size = UInt32(data.count)
    }
}
