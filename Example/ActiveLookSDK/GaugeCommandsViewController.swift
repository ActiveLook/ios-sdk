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

class GaugeCommandsViewController : CommandsTableViewController {
    

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Gauge commands"
        
        commandNames = [
            "Create gauge",
            "Display gauge at 30%",
            "Display gauge at 70%",
            "Display gauge at 100%",
        ]
        commandActions = [
            self.createGauge,
            self.displayGauge30,
            self.displayGauge70,
            self.displayGauge100
        ]
    }
    
    
    // MARK: - Actions
    
    func createGauge() {
        glasses.cfgWrite(name: "DemoApp", version: 1, password: 42)
        glasses.gaugeSave(id: 1, x: 152, y: 128, externalRadius: 40, internalRadius: 20, start: 2, end: 14, clockwise: true)
    }
    
    func displayGauge30() {
        glasses.cfgSet(name: "DemoApp")
        glasses.clear()
        glasses.gaugeDisplay(id: 1, value: 30)
    }
    
    func displayGauge70() {
        glasses.cfgSet(name: "DemoApp")
        glasses.clear()
        glasses.gaugeDisplay(id: 1, value: 70)
    }
    
    func displayGauge100() {
        glasses.cfgSet(name: "DemoApp")
        glasses.clear()
        glasses.gaugeDisplay(id: 1, value: 100)
    }
}
