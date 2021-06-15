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

class DisplayCommandsViewController : CommandsTableViewController {
    

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Display commands"
        
        commandNames = ["Low luminance", "Medium luminance", "High luminance", "Dim to 20%", "Dim to 50%", "Dim to 100%"]
        commandActions = [self.lowLuma, self.mediumLuma, self.highLuma, self.dim20, self.dim50, self.dim100]
    }
    
    
    // MARK: - Actions
    
    func lowLuma() {
        glasses.luma(level: 0)
    }
    
    func mediumLuma() {
        glasses.luma(level: 7)
    }
    
    func highLuma() {
        glasses.luma(level: 15)
    }
    
    func dim20() {
        glasses.dim(level: 20)
    }
    
    func dim50() {
        glasses.dim(level: 50)
    }

    func dim100() {
        glasses.dim(level: 100)
    }

}
