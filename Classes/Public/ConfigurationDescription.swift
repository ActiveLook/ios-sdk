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
public class ConfigurationDescription {
    
    /// The configuration name
    public let name: String
    
    /// The configuration size
    public let size: UInt32
    
    /// The configuration version
    public let version: UInt32
    
    /// The configuration usage count
    public let usageCnt: UInt8
    
    /// The configuration install count
    public let installCnt: UInt8
    
    /// The configuration flag for system configuration
    public let isSystem: Bool
    
    init(_ name: String, _ size: UInt32, _ version: UInt32, _ usageCnt: UInt8, _ installCnt: UInt8, _ isSystem: Bool) {
        self.name = name
        self.size = size
        self.version = version
        self.usageCnt = usageCnt
        self.installCnt = installCnt
        self.isSystem = isSystem
    }
    
    internal static func fromCommandResponseData(_ data: CommandResponseData) -> [ConfigurationDescription] {
        var results: [ConfigurationDescription] = []
        var offset = 0
        while offset < data.count {
            let subData = Array(data.suffix(from: offset))
            let nameSize = (subData.firstIndex(of: 0) ?? 0) + 1
            
            guard subData.count >= nameSize + 11 else { return results }
            
            let name = String(cString: Array(subData[0 ... nameSize - 1]))  
            let size = UInt32.fromUInt32ByteArray(bytes: Array(subData[nameSize ... nameSize + 3]))
            let version = UInt32.fromUInt32ByteArray(bytes: Array(subData[nameSize + 4 ... nameSize + 7]))
            let usageCnt = subData[nameSize + 8]
            let installCnt = subData[nameSize + 9]
            let isSystem = subData[nameSize + 10] != 0

            results.append(ConfigurationDescription(name, size, version, usageCnt, installCnt, isSystem))
            offset += nameSize + 11
        }
        return results
    }
}
