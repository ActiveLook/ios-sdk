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
            "Set different sensor parameters",
            "Reset sensor parameters",
            "Get sensor parameters",
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
            self.setSensorParameters,
            self.resetSensorParameters,
            self.getSensorParameters,
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
    
    func setSensorParameters() {
        let alsArray: [UInt16] = [50, 250, 1000, 3000, 6000, 9000, 10000, 12000, 15000]
        let sensorParameters = SensorParameters(alsArray: alsArray, alsPeriod: 100, rangingPeriod: 20)
        glasses.setSensorParameters(mode: .ALSArray, sensorParameters: sensorParameters)
        glasses.setSensorParameters(mode: .ALSPeriod, sensorParameters: sensorParameters)
        glasses.setSensorParameters(mode: .rangingPeriod, sensorParameters: sensorParameters)
    }
    
    func resetSensorParameters() {
        let alsArray: [UInt16] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        let sensorParameters = SensorParameters(alsArray: alsArray, alsPeriod: 1, rangingPeriod: 1)
        glasses.setSensorParameters(mode: .ALSArray, sensorParameters: sensorParameters)
        glasses.setSensorParameters(mode: .ALSPeriod, sensorParameters: sensorParameters)
        glasses.setSensorParameters(mode: .rangingPeriod, sensorParameters: sensorParameters)
    }
    
    func getSensorParameters() {
        glasses.getSensorParameters({ (sensorParameters) in
            let message = "ALS array: \(sensorParameters.alsArray)\nALS period: \(sensorParameters.alsPeriod)\nRanging period: \(sensorParameters.rangingPeriod)"

            let alert = UIAlertController(title: "Sensor parameters", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        })
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
