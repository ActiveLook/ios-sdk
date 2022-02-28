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

extension Int16 {

    /// is returning the same output as `asUInt8Array`.
    /// Not tested performance wise...
    var byteArray: [UInt8] {
        withUnsafeBytes(of: self.bigEndian) { //
            Array($0)
        }
    }
    
    var asUInt8Array: [UInt8] {
        let msb = UInt8(truncatingIfNeeded: self >> 8)
        let lsb = UInt8(truncatingIfNeeded: self)
        return [msb, lsb]
    }

}
