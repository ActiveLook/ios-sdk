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
    }
    
    internal func toCommandData() -> [UInt8] {
        var data: [UInt8] = []
        
        data.append(self.id)
        data.append(0x00) // Extra command data length. TODO Compute once implemented
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
        // TODO Append extra command data once implemented
        
        return data
    }
}
