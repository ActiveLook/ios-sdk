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

/// Information about the current glasses settings
public struct GlassesSettings {

    /// The horizontal shift currently set, applied to the whole screen and to all layouts, pages etc...
    public let xShift: Int

    /// The vertical shift currently set, applied to the whole screen and to all layouts, pages etc...
    public let yShift: Int

    /// The current display luminance, as an Integer between 0 and 15
    public let luma: Int

    /// true if the auto brightness adjustment sensor is enabled, false otherwise
    public let brightnessAdjustmentEnabled: Bool

    /// true if the auto gesture detection sensor is enabled, false otherwise
    public let gestureDetectionEnabled: Bool

    init(_ xShift: Int, _ yShift: Int, _ luma: Int, _ brightnessAdjustmentEnabled: Bool, _ gestureDetectionEnabled: Bool) {
        self.xShift = xShift
        self.yShift = yShift
        self.luma = luma
        self.brightnessAdjustmentEnabled = brightnessAdjustmentEnabled
        self.gestureDetectionEnabled = gestureDetectionEnabled
    }

    internal static func fromCommandResponseData(_ data: CommandResponseData) -> GlassesSettings {
        guard data.count >= 5 else { return GlassesSettings(0, 0, 0, false, false) }

        let shiftX = Int(Int8(bitPattern: data[0]))
        let shiftY = Int(Int8(bitPattern: data[1]))
        let luma = Int(data[2])
        let brightnessAdjustmentEnabled = data[3] == 0x01
        let gestureDetectionEnabled = data[4] == 0x01
        return GlassesSettings(shiftX, shiftY, luma, brightnessAdjustmentEnabled, gestureDetectionEnabled)
    }
}
