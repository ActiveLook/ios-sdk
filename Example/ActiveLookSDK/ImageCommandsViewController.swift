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
import ActiveLookSDK

class ImageCommandsViewController : CommandsTableViewController {
    
    let testImageWidth: UInt16 = 15

    let testImageData: [UInt8] = [0x11, 0x32, 0x43, 0x55, 0x76, 0x88, 0xA9, 0x0A, 0x21, 0x32, 0x44, 0x65, 0x77, 0x98, 0xA9, 0x0B, 0x21, 0x43, 0x54, 0x66, 0x87, 0x98, 0xBA, 0x0B, 0x32, 0x43, 0x55, 0x76, 0x88, 0xA9, 0xBA, 0x0C, 0x32, 0x44, 0x65, 0x77, 0x98, 0xA9, 0xBB, 0x0C, 0x43, 0x54, 0x66, 0x87, 0x98, 0xBA, 0xCB, 0x0D, 0x43, 0x65, 0x76, 0x88, 0xA9, 0xBA, 0xCC, 0x0D, 0x44, 0x65, 0x77, 0x98, 0xA9, 0xBB, 0xDC, 0x0E, 0x54, 0x66, 0x87, 0x98, 0xBA, 0xCB, 0xDD, 0x0E, 0x65, 0x76, 0x88, 0xA9, 0xBA, 0xCC, 0xED, 0x0E]

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Image commands"
        
        commandNames = [
            "List images",
            "Display image 1",
            "Display image 2",
            "Display image 3",
            "Display image 4",
            "Display image at the top of the screen",
            "Save test image",
            "Delete image",
            "Clear"
        ]

        commandActions = [
            self.listImages,
            self.displayImage1,
            self.displayImage2,
            self.displayImage3,
            self.displayImage4,
            self.displayImageBottomScreen,
            self.saveImage,
            self.deleteImage,
            self.clear
        ]
    }
    
    
    // MARK: - Actions
    
    func listImages() {
        glasses.imgList { (images: [ImageInfo]) in
            let alert = UIAlertController(title: "Image count", message: "\(images.count)   ", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func displayImage1() {
        glasses.imgDisplay(id: 0, x: 152, y: 128)
    }
    
    func displayImage2() {
        glasses.imgDisplay(id: 1, x: 152, y: 128)
    }
    
    func displayImage3() {
        glasses.imgDisplay(id: 2, x: 152, y: 128)
    }

    func displayImage4() {
        glasses.imgDisplay(id: 3, x: 152, y: 128)
    }
    
    func displayImageBottomScreen() {
        glasses.imgDisplay(id: 0, x: 152, y: 0)
    }
    
    func saveImage() {
        glasses.writeConfigID(configuration: Configuration(number: 1, id: 0))
        glasses.imgSave(imageData: ImageData(width: testImageWidth, data: testImageData))
    }
    
    func deleteImage() {
        glasses.writeConfigID(configuration: Configuration(number: 1, id: 0))
        glasses.imgDelete(id: 0)
    }
}
