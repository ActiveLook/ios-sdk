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

internal class Pixel {
    var r : UInt8
    var g : UInt8
    var b : UInt8
    
    internal init(){
        self.r = 0
        self.g = 0
        self.b = 0
    }
    
    internal init(r: UInt8, g: UInt8, b: UInt8){
        self.r = r
        self.g = g
        self.b = b
    }
    
    internal func rgbTo8bitGrayWeightedConvertion() -> Int{
        var grayPixel : Double = Double(self.r) * 0.299
        grayPixel +=  Double(self.g) * 0.587
        grayPixel +=  Double(self.b) * 0.114
        return Int(grayPixel.rounded())
    }
    
    internal func rgbTo8bitGrayDirectConvertion() -> Int{
        var grayPixel : Double = (Double(self.r) + Double(self.g) + Double(self.b)) / 3
        return Int(grayPixel.rounded())
    }
}
