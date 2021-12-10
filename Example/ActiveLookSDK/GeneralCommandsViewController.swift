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

class GeneralCommandsViewController : CommandsTableViewController {
    

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "General commands"
        
        commandNames = [
            "Power on",
            "Power off",
            "Clear",
            "Set low grey level",
            "Set max grey level",
            "Test pattern 1",
            "Test pattern 2",
            "Test pattern 3",
            "Get battery level",
            "Get version",
            "Toggle led",
            "Shift screen to the left",
            "Shift screen to the right",
            "Reset screen shift",
            "Get settings",
            "Change glasses name",
        ]

        commandActions = [
            self.powerOn,
            self.powerOff,
            self.clear,
            self.setLowGreyLevel,
            self.setMaxGreylevel,
            self.displayDemoPattern1,
            self.displayDemoPattern2,
            self.displayDemoPattern3,
            self.getBatteryLevel,
            self.getVersion,
            self.toggleLed,
            self.shiftToLeft,
            self.shiftToRight,
            self.resetShift,
            self.getSettings,
            self.changeGlassesName
        ]
    }
    
    
    // MARK: - Actions
    
    func powerOn() {
        glasses.power(on: true)
    }
    
    func powerOff() {
        glasses.power(on: false)
    }
    
    // clear() is declared in CommandsTableViewController and is used by several subclasses
    
    func setLowGreyLevel() {
        glasses.grey(level: 3)
    }
    
    func setMaxGreylevel() {
        glasses.grey(level: 15)
    }
        
    func displayDemoPattern1() {
        glasses.test(pattern: .fill)
    }
    
    func displayDemoPattern2() {
        glasses.test(pattern: .cross)
    }
    
    func displayDemoPattern3() {
        glasses.test(pattern: .image)
    }
    
    func getBatteryLevel() {
        glasses.battery { batteryLevel in
            let alert = UIAlertController(title: "Battery level", message: "\(batteryLevel) %", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func getVersion() {
        glasses.vers { glassesVersion in
            let v = glassesVersion
            let message = "Firmware version: \(v.firmwareVersion)\nManufaturingYear: \(v.manufacturingYear)\nManufacturingWeek: \(v.manufacturingWeek)\nSerial Number: \(v.serialNumber)"

            let alert = UIAlertController(title: "Glasses version", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func toggleLed() {
        glasses.led(state: .toggle)
    }
    
    func shiftToLeft() {
        glasses.shift(x: -50, y: 0)
    }
    
    func shiftToRight() {
        glasses.shift(x: 50, y: 0)
    }
    
    func resetShift() {
        glasses.shift(x: 0, y: 0)
    }
    
    func getSettings() {
        glasses.settings { glassesSettings in
            let s = glassesSettings

            let message = "X shift: \(s.xShift)\ny shift: \(s.yShift)\nLuma: \(s.luma)\nGesture detection enabled: \(s.gestureDetectionEnabled)\nBrightness adjustment enabled: \(s.brightnessAdjustmentEnabled)"

            let alert = UIAlertController(title: "Glasses settings", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func changeGlassesName() {
        glasses.setName("My glasses")
    }
}
