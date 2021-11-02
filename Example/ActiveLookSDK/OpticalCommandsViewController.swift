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

class OpticalCommandsViewController : CommandsTableViewController {
    

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Optical commands"
        
        commandNames = [
            "Enable sensors",
            "Disable sensors",
            "Enable gesture detection",
            "Disable gesture detection",
            "Enable auto brightness adjustment",
            "Disable auto brightness adjustment",
            "Subscribe to gesture notifications",
            "Unsubscribe from gesture notifications",
        ]

        commandActions = [
            self.enableSensors,
            self.disableSensors,
            self.enableGestureSensor,
            self.disableGestureSensor,
            self.enableBrightnessSensor,
            self.disableGestureSensor,
            self.subscribeToSensorInterfaceNotifications,
            self.unsubscribeFromSensorInterfaceNotifications
        ]
    }
    
    
    // MARK: - Actions
    
    func enableSensors() {
        glasses.sensor(enabled: true)
    }
    
    func disableSensors() {
        glasses.sensor(enabled: false)
    }
    
    func enableGestureSensor() {
        glasses.gesture(enabled: true)
    }
    
    func disableGestureSensor() {
        glasses.gesture(enabled: false)
    }
    
    func enableBrightnessSensor() {
        glasses.als(enabled: true)
    }
    
    func disableBrightnessSensor() {
        glasses.als(enabled: false)
    }

    func subscribeToSensorInterfaceNotifications() {
        glasses.subscribeToSensorInterfaceNotifications(onSensorInterfaceTriggered: { () -> (Void) in
            print("sensor interface triggered !")
        })
    }
    
    func unsubscribeFromSensorInterfaceNotifications() {
        glasses.unsubscribeFromSensorInterfaceNotifications()
    }
}
