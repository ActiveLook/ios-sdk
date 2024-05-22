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

/// Supported image saving format
@objc public enum ImgSaveFmt: UInt8 {
    case MONO_4BPP = 0  ///4bpp
    case MONO_1BPP = 1  ///1bpp, transformed into 4bpp by the firmware before saving
    case MONO_4BPP_HEATSHRINK = 2 ///4bpp with Heatshrink compression, decompressed into 4bpp by the firmware before saving
    case MONO_4BPP_HEATSHRINK_SAVE_COMP = 3 ///4bpp with Heatshrink compression, stored compressed, decompressed into 4bpp before display
}

/// Supported image streaming format
@objc public enum ImgStreamFmt: UInt8 {
    case MONO_1BPP = 1  ///1bpp
    case MONO_4BPP_HEATSHRINK = 2 ///4bpp with Heatshrink compression
}
