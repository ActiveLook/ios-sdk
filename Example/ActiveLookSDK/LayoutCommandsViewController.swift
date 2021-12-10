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
import ActiveLookSDK

class LayoutCommandsViewController : CommandsTableViewController {
    

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Layout commands"
        
        commandNames = [
//            "List layouts",
            "Display time layout",
            "Display chrono layout",
            "Display distance layout",
            "Display average speed layout",
            "Display elevation layout",
            "Clear time layout area",
            "Clear chrono layout area",
            "Change time layout position",
            "Reset time layout position",
            "Display time layout at bottom of the screen",
            "Save custom layout",
            "Display custom layout",
            "Delete custom layout",
            "Clear",
        ]

        commandActions = [
//            self.listLayouts,
            self.displayTimeLayout,
            self.displayChronoLayout,
            self.displayDistanceLayout,
            self.displayAverageSpeedLayout,
            self.displayElevationLayout,
            self.clearTimeLayoutArea,
            self.clearChronoLayoutArea,
            self.changeTimeLayoutPosition,
            self.resetTimeLayoutPosition,
            self.displayTimeAtBottomOfScreen,
            self.saveCustomLayout,
            self.displayCustomLayout,
            self.deleteCustomLayout,
            self.clear
        ]
    }
    
    
    // MARK: - Actions
    
//    func listLayouts() {
//        glasses.layoutList()
//    }
    
    func displayTimeLayout() {
        glasses.layoutDisplay(id: 10, text: "15:36")
    }
    
    func displayChronoLayout() {
        glasses.layoutDisplay(id: 11, text: "00:00:10")
    }
    
    func displayDistanceLayout() {
        glasses.layoutDisplay(id: 12, text: "12.5")
    }
    
    func displayAverageSpeedLayout() {
        glasses.layoutDisplay(id: 14, text: "10.2")
    }
    
    func displayElevationLayout() {
        glasses.layoutDisplay(id: 19, text: "804")
    }
    
    func clearTimeLayoutArea() {
        glasses.layoutClear(id: 10)
    }
    
    func clearChronoLayoutArea() {
        glasses.layoutClear(id: 11)
    }
    
    func changeTimeLayoutPosition() {
        glasses.layoutPosition(id: 10, x: 10, y: 10)
    }
    
    func resetTimeLayoutPosition() {
        glasses.layoutPosition(id: 10, x: 20, y: 200)
    }
    
    func displayTimeAtBottomOfScreen() {
        glasses.layoutDisplayExtended(id: 10, x: 20, y: 0, text: "15:36")
    }
    
    func saveCustomLayout() {
        let layoutParameters = LayoutParameters(
            id: 30,
            x: 0,
            y: 0,
            width: 304,
            height: 50,
            foregroundColor: 15,
            backgroundColor: 0,
            font: 2,
            textValid: true,
            textX: 152,
            textY: 50,
            textRotation: .bottomRL,
            textOpacity: true
        ).addSubCommandLine(x1: 0, y1: 0, x2: 200, y2: 50)
        glasses.cfgWrite(name: "DemoApp", version: 1, password: 42)
        glasses.layoutSave(parameters: layoutParameters)
    }
    
    func displayCustomLayout() {
        glasses.layoutDisplay(id: 30, text: "12.4")
    }
    
    func deleteCustomLayout() {
        glasses.layoutDelete(id: 30)
    }
}
