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

/// Information about a Configuration.
public class Configuration {
    
    /// The configuration number
    public let number: UInt8
    
    /// The configuration ID
    public let id: UInt32
    
    internal let deprecatedBytes: [UInt8]
    
    public init(number: UInt8, id: UInt32) {
        self.number = number
        self.id = id
        self.deprecatedBytes = [0x00, 0x00, 0x00]
    }

    internal func toCommandData() -> [UInt8] {
        var data: [UInt8] = [self.number]
        data.append(contentsOf: self.id.asUInt8Array)
        data.append(contentsOf: self.deprecatedBytes)
        
        return data
    }
    
    internal static func fromCommandResponseData(_ data: CommandResponseData) -> Configuration {
        guard data.count >= 5 else { return Configuration(number: 0, id: 0) }
        
        let d = data
        let number = d[0]
        let configID = UInt32.fromUInt32ByteArray(bytes: [d[1], d[2], d[3], d[4]])

        return Configuration(number: number, id: configID)
    }
}
