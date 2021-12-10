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

class GraphicsCommandsViewController : CommandsTableViewController {
    

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Graphics commands"
        
        commandNames = [
            "Draw point",
            "Draw line",
            "Draw circle",
            "Draw square",
            "Draw full circle",
            "Draw full square",
            "Draw text",
            "Set color to black",
            "Set color to medium",
            "Set color to max"
        ]

        commandActions = [
            self.drawPoint,
            self.drawLine,
            self.drawCircle,
            self.drawSquare,
            self.drawFullCircle,
            self.drawFullSquare,
            self.drawText,
            self.setColorBlack,
            self.setColorMedium,
            self.setColorMax
        ]
    }
    
    
    // MARK: - Actions
    
    func drawPoint() {
        glasses.clear()
        glasses.point(x: 152, y: 128)
    }
    
    func drawLine() {
        glasses.clear()
        glasses.line(x0: 102, x1: 202, y0: 128, y1: 128)
    }
    
    func drawCircle() {
        glasses.clear()
        glasses.circ(x: 152, y: 128, radius: 50)
    }
    
    func drawSquare() {
        glasses.clear()
        glasses.rect(x0: 102, x1: 202, y0: 78, y1: 178)
    }
    
    func drawFullCircle() {
        glasses.clear()
        glasses.circf(x: 152, y: 128, radius: 50)
    }
    
    func drawFullSquare() {
        glasses.clear()
        glasses.rectf(x0: 102, x1: 202, y0: 78, y1: 178)
    }
    
    func drawText() {
        glasses.clear()
        glasses.txt(x: 102, y: 128, rotation: .bottomRL, font: 2, color: 15, string: "Hello")
    }
    
    func setColorBlack() {
        glasses.color(level: 0)
    }
    
    func setColorMedium() {
        glasses.color(level: 5)
    }
    
    func setColorMax() {
        glasses.color(level: 15)
    }
}
