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
import UIKit

extension UIImage{
    
    internal func getPixels() -> [[Pixel]]{
        guard let cgImage = self.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            fatalError("Couldn't access image data")
        }
        assert(cgImage.colorSpace?.model == .rgb)
        
        let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent
        
        var PixelsArray : [[Pixel]] = [[Pixel]](repeating: [Pixel](repeating: Pixel.init(), count: cgImage.width), count: cgImage.height)
        for y in 0 ..< cgImage.height {
            for x in 0 ..< cgImage.width {
                let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
                let pixel : Pixel = Pixel.init(r: bytes[offset], g: bytes[offset + 1], b: bytes[offset + 2])
                PixelsArray[y][x] = pixel
            }
        }
        
        return PixelsArray
    }
    
    
    internal func getRotatedPixels_180() -> [[Pixel]]{
        let Pixels = self.getPixels()
        let height = Pixels.count
        let width = Pixels[0].count
        
        var PixelsArray : [[Pixel]] = [[Pixel]](repeating: [Pixel](repeating: Pixel.init(), count: width), count: height)
        
        for y in 0 ..< height {
            for x in 0 ..< width {
                PixelsArray[height - y - 1][width - x - 1] = Pixels[y][x]
            }
        }
        return PixelsArray
    }
}
