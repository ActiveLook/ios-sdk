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
public class FontData {
    
    /// The height of characters in pixels
    public let height: UInt8
    
    /// The encoded data representing the font
    public let data: [UInt8]
    
    public init(height: UInt8, data: [UInt8]) {
        self.height = height
        self.data = data
    }
}
