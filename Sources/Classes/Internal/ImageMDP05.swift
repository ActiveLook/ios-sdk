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

internal class ImageMDP05{
    
    ///convert image to MDP05 default format
    internal func convertDefault(image : UIImage) -> [[Int]]{
        let rotatedPixelsArray  : [[Pixel]] = image.getRotatedPixels_180()
        
        let height = rotatedPixelsArray.count
        let width = rotatedPixelsArray[0].count
        
        var encodedImg : [[Int]] =  [[Int]](repeating: [Int](repeating: 0, count: width), count: height)

        //reduce to 4bpp
        for y in 0 ..< height {
            for x in 0 ..< width {
                let gray8bit : Int =  rotatedPixelsArray[y][x].rgbTo8bitGrayWeightedConvertion()
                //convert gray8bit to gray4bit
                let gray4bit = Int((Double(gray8bit)/16))
                encodedImg[y][x] =  gray4bit
            }
        }
        return encodedImg
    }
    
    ///convert image to MDP05 1bpp format
    internal func convert1Bpp(image : UIImage) -> [[Int]]{
        let rotatedPixelsArray  : [[Pixel]] = image.getRotatedPixels_180()
        
        let height = rotatedPixelsArray.count
        let width = rotatedPixelsArray[0].count
        
        var encodedImg : [[Int]] =  [[Int]](repeating: [Int](repeating: 0, count: width), count: height)

        //reduce to 1 bpp
        for y in 0 ..< height {
            for x in 0 ..< width {
                //convert gray8bit in gray1bit
                if (rotatedPixelsArray[y][x].rgbTo8bitGrayWeightedConvertion() > 0){
                    encodedImg[y][x] = 1
                }else{
                    encodedImg[y][x] = 0
                }
            }
        }
        
        return encodedImg
    }
}
