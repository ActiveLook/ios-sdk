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

import UIKit
import ActiveLookSDK

class NotificationsViewController: UIViewController {

    @IBOutlet weak var batteryLevelLabel: UILabel!
    @IBOutlet weak var batteryLevelSubscribeButton: UIButton!
    @IBOutlet weak var flowControlSubscribeButton: UIButton!
    @IBOutlet weak var sensorInterfaceSubscribeButton: UIButton!


    // MARK: - Public properties

    public var glasses: Glasses!
    

    // MARK: - Private properties

    private var activeLook: ActiveLookSDK = ActiveLookSDK.shared
    
    private var isSubscribedToBatteryLevelNotifications = false
    private var isSubscribedToFlowControlNotifications = false
    private var isSubscribedToSensorInterfaceNotifications = false
    

    // MARK: - Life cycle

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        glasses.onDisconnect { [weak self] in
            guard let self = self else { return }
            print("glasses disconnected:  \(self.glasses.name)")

            let alert = UIAlertController(title: "Glasses disconnected", message: "Connection to glasses lost", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                self.navigationController?.popToRootViewController(animated: true)
            }))

            self.present(alert, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        unsubscribeFromBatteryLevelNotifications()
        unsubscribeFromFlowControlNotifications()
        unsubscribeFromSensorInterfaceNotifications()
    }


    // MARK: - Private methods
    
    private func updateBatteryLevel(_ batteryLevel: Int) {
        batteryLevelLabel.text = "Battery level: \(batteryLevel) %"
    }
    
    private func subscribeToBatteryLevelNotifications() {
        glasses.subscribeToBatteryLevelNotifications(onBatteryLevelUpdate: { (batteryLevel) -> (Void) in
            print("battery level update: \(batteryLevel)")
            self.updateBatteryLevel(batteryLevel)
        })

        isSubscribedToBatteryLevelNotifications = true
        batteryLevelSubscribeButton.setTitle("Unsubscribe", for: .normal)
    }
    
    private func unsubscribeFromBatteryLevelNotifications() {
        glasses.unsubscribeFromBatteryLevelNotifications()
        
        isSubscribedToBatteryLevelNotifications = false
        batteryLevelSubscribeButton.setTitle("Subscribe", for: .normal)
    }
    
    private func subscribeToFlowControlNotifications() {
        glasses.subscribeToFlowControlNotifications(onFlowControlUpdate: { (flowControlState) -> (Void) in
            print("flow control state update: \(flowControlState)")
        })

        isSubscribedToFlowControlNotifications = true
        flowControlSubscribeButton.setTitle("Unsubscribe", for: .normal)
    }
    
    private func unsubscribeFromFlowControlNotifications() {
        glasses.unsubscribeFromFlowControlNotifications()
        
        isSubscribedToFlowControlNotifications = false
        flowControlSubscribeButton.setTitle("Subscribe", for: .normal)
    }
    
    private func subscribeToSensorInterfaceNotifications() {
        glasses.subscribeToSensorInterfaceNotifications(onSensorInterfaceTriggered: { () -> (Void) in
            print("sensor interface triggered")
        })

        isSubscribedToSensorInterfaceNotifications = true
        sensorInterfaceSubscribeButton.setTitle("Unsubscribe", for: .normal)
    }
    
    private func unsubscribeFromSensorInterfaceNotifications() {
        glasses.unsubscribeFromSensorInterfaceNotifications()
        
        isSubscribedToSensorInterfaceNotifications = false
        sensorInterfaceSubscribeButton.setTitle("Subscribe", for: .normal)
    }

    
    // MARK: - Actions
        
    @IBAction func onSubscribeToBatteryLevelNotificationsButtonTap(_ sender: Any) {
        isSubscribedToBatteryLevelNotifications ? unsubscribeFromBatteryLevelNotifications() : subscribeToBatteryLevelNotifications()
    }
    
    @IBAction func onSubscribeToFlowControlNotificationsButtonTap(_ sender: Any) {
        isSubscribedToFlowControlNotifications ? unsubscribeFromFlowControlNotifications() : subscribeToFlowControlNotifications()
    }
    
    @IBAction func onSubscribeToSensorInterfaceNotificationsButtonTap(_ sender: Any) {
        isSubscribedToSensorInterfaceNotifications ? unsubscribeFromSensorInterfaceNotifications() : subscribeToSensorInterfaceNotifications()
    }
}
