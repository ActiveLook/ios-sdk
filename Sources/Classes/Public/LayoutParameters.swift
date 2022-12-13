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
public class LayoutParameters {

    /// The layout ID
    public let id: UInt8

    /// The x coordinate of the start position (upper left) of the layout area
    public let x: UInt16

    /// The y coordinate of the start position (upper left) of the layout area
    public let y: UInt8

    /// The width of the layout area
    public let width: UInt16

    /// The height of the layout area
    public let height: UInt8

    /// The foreground color of the layout area from 0 to 15
    public let foregroundColor: UInt8

    /// The background color of the layout area from 0 to 15
    public let backgroundColor: UInt8

    /// The font used to draw the text value of the layout
    public let font: UInt8

    /// Define if the argument of the layout is displayed using text
    public let textValid: Bool

    /// Define the x coordinate of the position of the text value in the layout area
    public let textX: UInt16

    /// Define the y coordinate of the position of the text value in the layout area
    public let textY: UInt8

    /// Define the text  rotation
    public let textRotation: TextRotation

    /// Define the argument opacity(on/off)
    public let textOpacity: Bool

    // TODO Add additional commands
    public var subCommands: [UInt8]

    public init(
        id: UInt8,
        x: UInt16,
        y: UInt8,
        width: UInt16,
        height: UInt8,
        foregroundColor: UInt8,
        backgroundColor: UInt8,
        font: UInt8,
        textValid: Bool,
        textX: UInt16,
        textY: UInt8,
        textRotation: TextRotation,
        textOpacity: Bool) {

        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.font = font
        self.textValid = textValid
        self.textX = textX
        self.textY = textY
        self.textRotation = textRotation
        self.textOpacity = textOpacity
        self.subCommands = []
    }

    public func addSubCommandBitmap(id: UInt8, x: Int16, y: Int16) -> LayoutParameters {
        self.subCommands.append(0x00)
        self.subCommands.append(id)
        self.subCommands += x.asUInt8Array
        self.subCommands += y.asUInt8Array
        return self
    }

    public func addSubCommandCirc(x: UInt16, y: UInt16, r: UInt16) -> LayoutParameters {
        self.subCommands.append(0x01)
        self.subCommands += x.asUInt8Array
        self.subCommands += y.asUInt8Array
        self.subCommands += r.asUInt8Array
        return self
    }

    public func addSubCommandCircf(x: UInt16, y: UInt16, r: UInt16) -> LayoutParameters {
        self.subCommands.append(0x02)
        self.subCommands += x.asUInt8Array
        self.subCommands += y.asUInt8Array
        self.subCommands += r.asUInt8Array
        return self
    }

    public func addSubCommandColor(c: UInt8) -> LayoutParameters {
        self.subCommands.append(0x03)
        self.subCommands.append(c)
        return self
    }

    public func addSubCommandFont(f: UInt8) -> LayoutParameters {
        self.subCommands.append(0x04)
        self.subCommands.append(f)
        return self
    }

    public func addSubCommandLine(x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16) -> LayoutParameters {
        self.subCommands.append(0x05)
        self.subCommands += x1.asUInt8Array
        self.subCommands += y1.asUInt8Array
        self.subCommands += x2.asUInt8Array
        self.subCommands += y2.asUInt8Array
        return self
    }

    public func addSubCommandPoint(x: UInt8, y: UInt16) -> LayoutParameters {
        self.subCommands.append(0x06)
        self.subCommands.append(x)
        self.subCommands += y.asUInt8Array
        return self
    }

    public func addSubCommandRect(x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16) -> LayoutParameters {
        self.subCommands.append(0x07)
        self.subCommands += x1.asUInt8Array
        self.subCommands += y1.asUInt8Array
        self.subCommands += x2.asUInt8Array
        self.subCommands += y2.asUInt8Array
        return self
    }

    public func addSubCommandRectf(x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16) -> LayoutParameters {
        self.subCommands.append(0x08)
        self.subCommands += x1.asUInt8Array
        self.subCommands += y1.asUInt8Array
        self.subCommands += x2.asUInt8Array
        self.subCommands += y2.asUInt8Array
        return self
    }

    public func addSubCommandText(x: UInt16, y: UInt16, txt: String) -> LayoutParameters {
        self.subCommands.append(0x09)
        self.subCommands += x.asUInt8Array
        self.subCommands += y.asUInt8Array
        self.subCommands.append(UInt8(txt.count))
        self.subCommands += Array(txt.asNullTerminatedUInt8Array)
        return self
    }

    public func addSubCommandGauge(gaugeId: UInt8) -> LayoutParameters {
        self.subCommands.append(0x0A)
        self.subCommands.append(gaugeId)
        return self
    }


    public func toCommandData() -> [UInt8] {
        var data: [UInt8] = []

        data.append(self.id)
        data.append(UInt8(self.subCommands.count))
        data.append(contentsOf: self.x.asUInt8Array)
        data.append(self.y)
        data.append(contentsOf: self.width.asUInt8Array)
        data.append(self.height)
        data.append(self.foregroundColor)
        data.append(self.backgroundColor)
        data.append(self.font)
        data.append(self.textValid ? 0x01 : 0x00)
        data.append(contentsOf: self.textX.asUInt8Array)
        data.append(self.textY)
        data.append(self.textRotation.rawValue)
        data.append(self.textOpacity ? 0x01 : 0x00)
        data.append(contentsOf: self.subCommands)

        return data
    }

    internal static func fromCommandResponseData(_ data: CommandResponseData) -> LayoutParameters {
        guard data.count >= 10 else { return LayoutParameters(id: 0, x: 0, y: 0, width: 0, height: 0, foregroundColor: 0, backgroundColor: 0, font: 0, textValid: false, textX: 0, textY: 0, textRotation: .topLR, textOpacity: false) }

        let id = 0
        let x = UInt16.fromUInt16ByteArray(bytes: Array(data[1...2]))
        let y = data[3]
        let width = UInt16.fromUInt16ByteArray(bytes: Array(data[4...5]))
        let height = data[6]
        let foregroundColor = data[7]
        let backgroundColor = data[8]
        let font = data[9]
        let textValid = data[10] != 0x00
        let textX = UInt16.fromUInt16ByteArray(bytes: Array(data[11...12]))
        let textY = data[13]
        let textRotation = TextRotation(rawValue: data[12]) ?? .topLR
        let textOpacity = data[15] != 0x00

        return LayoutParameters(id: UInt8(id), x: x, y: y, width: width, height: height, foregroundColor: foregroundColor, backgroundColor: backgroundColor, font: font, textValid: textValid, textX: textX, textY: textY, textRotation: textRotation, textOpacity: textOpacity)
    }

    // MARK: - Defined for non-native integration
    @objc public func toString() -> NSString {
         var str: String = ""
         str.append("\(self.id)")
         str.append("\(self.subCommands.count)")
         str.append("\(self.x.asUInt8Array)")
         str.append("\(self.y)")
         str.append("\(self.width.asUInt8Array)")
         str.append("\(self.height)")
         str.append("\(self.foregroundColor)")
         str.append("\(self.backgroundColor)")
         str.append("\(self.font)")
         str.append("\(self.textValid ? 0x01 : 0x00)")
         str.append("\(self.textX.asUInt8Array)")
         str.append("\(self.textY)")
         str.append("\(self.textRotation.rawValue)")
         str.append("\(self.textOpacity ? 0x01 : 0x00)")
         str.append("\(self.subCommands)")
         return NSString.init(string: str)
     }
}
