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

/// Parameters defining a layout
public class LayoutExtraCmd {

    
    // TODO Add additional commands
    public var subCommands: [UInt8]

    public init(){
        self.subCommands = []
    }

    public func addSubCommandBitmap(id: UInt8, x: Int16, y: Int16){
        self.subCommands.append(0x00)
        self.subCommands.append(id)
        self.subCommands += x.asUInt8Array
        self.subCommands += y.asUInt8Array
    }

    public func addSubCommandCirc(x: UInt16, y: UInt16, r: UInt16){
        self.subCommands.append(0x01)
        self.subCommands += x.asUInt8Array
        self.subCommands += y.asUInt8Array
        self.subCommands += r.asUInt8Array
    }

    public func addSubCommandCircf(x: UInt16, y: UInt16, r: UInt16){
        self.subCommands.append(0x02)
        self.subCommands += x.asUInt8Array
        self.subCommands += y.asUInt8Array
        self.subCommands += r.asUInt8Array
    }

    public func addSubCommandColor(c: UInt8){
        self.subCommands.append(0x03)
        self.subCommands.append(c)
    }

    public func addSubCommandFont(f: UInt8){
        self.subCommands.append(0x04)
        self.subCommands.append(f)
    }

    public func addSubCommandLine(x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16){
        self.subCommands.append(0x05)
        self.subCommands += x1.asUInt8Array
        self.subCommands += y1.asUInt8Array
        self.subCommands += x2.asUInt8Array
        self.subCommands += y2.asUInt8Array
    }

    public func addSubCommandPoint(x: UInt8, y: UInt16){
        self.subCommands.append(0x06)
        self.subCommands.append(x)
        self.subCommands += y.asUInt8Array
    }

    public func addSubCommandRect(x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16) {
        self.subCommands.append(0x07)
        self.subCommands += x1.asUInt8Array
        self.subCommands += y1.asUInt8Array
        self.subCommands += x2.asUInt8Array
        self.subCommands += y2.asUInt8Array
    }

    public func addSubCommandRectf(x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16){
        self.subCommands.append(0x08)
        self.subCommands += x1.asUInt8Array
        self.subCommands += y1.asUInt8Array
        self.subCommands += x2.asUInt8Array
        self.subCommands += y2.asUInt8Array
    }

    public func addSubCommandText(x: UInt16, y: UInt16, txt: String) {
        self.subCommands.append(0x09)
        self.subCommands += x.asUInt8Array
        self.subCommands += y.asUInt8Array
        self.subCommands.append(UInt8(txt.asNullTerminatedUInt8Array.count))
        self.subCommands += Array(txt.asNullTerminatedUInt8Array)
    }

    public func addSubCommandGauge(gaugeId: UInt8) {
        self.subCommands.append(0x0A)
        self.subCommands.append(gaugeId)
    }

    public func addSubCommandAnim(handlerId: UInt8, id: UInt8, delay: Int16, repeatAnim: UInt8, x: Int16, y: Int16) {
        self.subCommands.append(0x0B)
        self.subCommands.append(handlerId)
        self.subCommands.append(id)
        self.subCommands += delay.asUInt8Array
        self.subCommands.append(repeatAnim)
        self.subCommands += x.asUInt8Array
        self.subCommands += y.asUInt8Array
    }


    public func toCommandData() -> [UInt8] {
        var data: [UInt8] = []
        data.append(contentsOf: self.subCommands)
        return data
    }
}
