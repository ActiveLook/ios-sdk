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

class StatisticsCommandsViewController : CommandsTableViewController {
    

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Statistics commands"
        
        commandNames = [
            "Get pixel count",
            "Get charging counter",
            "Get charging time",
            "Get max pixel value",
            "Set max pixel value to half",
            "Reset max pixel value",
            "Reset charging param"
        ]
        
        commandActions = [
            self.getPixelCount,
            self.getChargingCounter,
            self.getChargingTime,
            self.getMaxPixelValue,
            self.setMaxPixelValueHalf,
            self.resetMaxPixelValue,
            self.resetChargingParam
        ]
    }
    
    
    // MARK: - Actions
    
    func getPixelCount() {
        glasses.pixelCount { pixelCount in
            let alert = UIAlertController(title: "Current pixel count", message: "\(pixelCount)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func getChargingCounter() {
        glasses.getChargingCounter { chargingCount in
            let alert = UIAlertController(title: "Charging count", message: "\(chargingCount)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func getChargingTime() {
        glasses.getChargingTime { chargingTime in
            let alert = UIAlertController(title: "Charging time", message: "\(chargingTime)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func getMaxPixelValue() {
        glasses.getMaxPixelValue { maxPixelValue in
            let alert = UIAlertController(title: "Max pixel value", message: "\(maxPixelValue)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func setMaxPixelValueHalf() {
        glasses.setPixelValue(77824 / 2)
    }
    
    func resetMaxPixelValue() {
        glasses.setPixelValue(77824)
    }
    
    func resetChargingParam() {
        glasses.resetChargingParam()
    }
}
