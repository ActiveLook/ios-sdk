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
#if canImport(Heatshrink)
import Heatshrink
#endif

internal class ImageConverter {
    
    internal func getImageData(img: UIImage, fmt: ImgSaveFmt) -> ImageData{
        let matrix : [[Int]] = convert(img: img, fmt: fmt)
        let width : Int = matrix[0].count
        var cmds : [UInt8] = []
        
        switch fmt {
        case .MONO_4BPP:
            cmds = getCmd4Bpp(matrix: matrix)
            return ImageData(width: UInt16(width), data: cmds)
        case .MONO_4BPP_HEATSHRINK, .MONO_4BPP_HEATSHRINK_SAVE_COMP:
            let encodedImg = getCmd4Bpp(matrix: matrix)
            let matrixData = Data(bytes: encodedImg, count: encodedImg.count)
            cmds = getCmdCompress4BppHeatshrink(encodedImg: matrixData)
            return ImageData(width: UInt16(width), data: cmds, size: UInt32(encodedImg.count))
        default:
            print("Unknown image format")
            break
        }
        
        return ImageData()
    }
    
    internal func getImageData1bpp(img: UIImage, fmt: ImgSaveFmt) -> ImageData1bpp{
        let matrix : [[Int]] = convert(img: img, fmt: fmt)
        let width : Int = matrix[0].count
        var cmds : [[UInt8]] = [[]]
        
        switch fmt {
        case .MONO_1BPP:
            cmds = getCmd1Bpp(matrix: matrix)
            break
        default:
            print("Unknown image format")
            break
        }
        
        return ImageData1bpp(width: UInt16(width), data: cmds)
    }
    
    internal func getImageDataStream1bpp(img: UIImage, fmt: ImgStreamFmt) -> ImageData1bpp{
        let matrix : [[Int]] = convertStream(img: img, fmt: fmt)
        let width : Int = matrix[0].count
        var cmds : [[UInt8]] = [[]]
        
        switch fmt {
        case .MONO_1BPP:
            cmds = getCmd1Bpp(matrix: matrix)
            break
        default:
            print("Unknown image format")
            break
        }
        
        return ImageData1bpp(width: UInt16(width), data: cmds)
    }
    
    internal func getImageDataStream4bpp(img: UIImage, fmt: ImgStreamFmt) -> ImageData{
        let matrix : [[Int]] = convertStream(img: img, fmt: fmt)
        let width : Int = matrix[0].count
        var cmds : [UInt8] = []
        
        switch fmt {
        case .MONO_4BPP_HEATSHRINK:
            let encodedImg = getCmd4Bpp(matrix: matrix)
            let matrixData = Data(bytes: encodedImg, count: encodedImg.count)
            cmds = getCmdCompress4BppHeatshrink(encodedImg: matrixData)
            return ImageData(width: UInt16(width), data: cmds, size: UInt32(encodedImg.count))
        default:
            print("Unknown image format")
            break
        }
        
        return ImageData()
    }

    //MARK: - Convert pixels to specific format without compression
    private func convert(img: UIImage, fmt: ImgSaveFmt) -> [[Int]]{
        var convert : [[Int]] = [[]]
        
        switch fmt {
        case .MONO_1BPP:
            convert = ImageMDP05().convert1Bpp(image: img)
            break
        case .MONO_4BPP:
            convert = ImageMDP05().convertDefault(image: img)
            break
        case .MONO_4BPP_HEATSHRINK, .MONO_4BPP_HEATSHRINK_SAVE_COMP:
            convert = ImageMDP05().convertDefault(image: img)
            break
        }
        
        return convert;
    }
    
    private func convertStream(img: UIImage, fmt: ImgStreamFmt) -> [[Int]]{
        var convert : [[Int]] = [[]]
        
        switch fmt {
        case .MONO_1BPP:
            convert = ImageMDP05().convert1Bpp(image: img)
            break
        case .MONO_4BPP_HEATSHRINK:
            convert = ImageMDP05().convertDefault(image: img)
            break
        }
        
        return convert;
    }
    
   
    //MARK: - Prepare command to save image
    private func getCmd4Bpp(matrix : [[Int]]) -> [UInt8]{
        let height = matrix.count
        let width = matrix[0].count
        
        //Compresse img 4 bit per pixel
        var encodedImg : [UInt8] = []
        
        for y in 0 ..< height{
            var b : UInt8 = 0;
            var shift : UInt8 = 0;
            for x in 0 ..< width {
                let pxl : UInt8 = UInt8(matrix[y][x])
                //compress 4 bit per pixel
                b += pxl << shift
                shift += 4
                
                if (shift == 8){
                    encodedImg.append(b)
                    b = 0;
                    shift = 0;
                }
            }
            if (shift != 0){
                encodedImg.append(b)
            }
        }
        return  encodedImg
    }
    
    private func getCmdCompress4BppHeatshrink(encodedImg: Data) -> [UInt8]{
        let encoder = RNHeatshrinkEncoder(windowSize: 8, andLookaheadSize: 4)
        return [UInt8](encoder.encode(encodedImg))
    }
    
    private func getCmd1Bpp(matrix : [[Int]]) -> [[UInt8]]{
        let height = matrix.count
        let width = matrix[0].count

        //Compress img 1 bit per pixel
        var encodedImg : [[UInt8]] = [[]]
        
        for y in 0 ..< height{
            var byte : UInt8 = 0
            var shift : UInt8 = 0
            var encodedLine : [UInt8] = []
            
            for x in 0 ..< width {
                let pxl : UInt8 = UInt8(matrix[y][x])
                
                //compress 1 bit per pixel
                byte += pxl << shift
                shift += 1
                if(shift == 8){
                    encodedLine.append(byte)
                    byte = 0
                    shift = 0
                }
            }
            if(shift != 0){
                encodedLine.append(byte)
            }
            encodedImg.insert(encodedLine, at: y)
        }
        
        encodedImg.removeLast()
        return encodedImg
    }
}
