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

class CommandsMenuTableViewController: CommandsTableViewController {

    // MARK: - Life cycle
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Commands"

        commandNames = [
            "General",
            "Display luminance",
            "Optical sensor",
            "Graphics",
            "Image",
            "Font",
            "Layout",
            "Page",
            "Gauge",
            "Statistics",
            "Configuration",
            "Notifications"
        ]

        commandActions = [
            self.showGeneralCommands,
            self.showDisplayCommands,
            self.showOpticalCommands,
            self.showGraphicsCommands,
            self.showImageCommands,
            self.showFontCommands,
            self.showLayoutCommands,
            self.showPageCommands,
            self.showGaugeCommands,
            self.showStatisticsCommands,
            self.showConfigurationCommands,
            self.showNotificationsViewController
        ]
        
        glasses.subscribeToFlowControlNotifications { (flowControlState) -> (Void) in
            print("flow control state update: \(flowControlState)")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        // Disconnect glasses when navigating back to list
        if navigationController?.viewControllers.firstIndex(of: self) == nil {
            glasses.disconnect()
        }
        
        super.viewDidDisappear(animated)
    }
    
    
    // MARK: - Navigation
    
    func showGeneralCommands() {
        navigationController?.pushViewController(GeneralCommandsViewController(glasses), animated: true)
    }
    
    func showDisplayCommands() {
        navigationController?.pushViewController(DisplayCommandsViewController(glasses), animated: true)
    }
    
    func showOpticalCommands() {
        navigationController?.pushViewController(OpticalCommandsViewController(glasses), animated: true)
    }
    
    func showGraphicsCommands() {
        navigationController?.pushViewController(GraphicsCommandsViewController(glasses), animated: true)
    }
    
    func showImageCommands() {
        navigationController?.pushViewController(ImageCommandsViewController(glasses), animated: true)
    }
    
    func showFontCommands() {
        navigationController?.pushViewController(FontCommandsViewController(glasses), animated: true)
    }
    
    func showLayoutCommands() {
        navigationController?.pushViewController(LayoutCommandsViewController(glasses), animated: true)
    }
    
    func showPageCommands() {
        navigationController?.pushViewController(PageCommandsViewController(glasses), animated: true)
    }
    
    func showGaugeCommands() {
        navigationController?.pushViewController(GaugeCommandsViewController(glasses), animated: true)
    }
    
    func showStatisticsCommands() {
        navigationController?.pushViewController(StatisticsCommandsViewController(glasses), animated: true)
    }
    
    func showConfigurationCommands() {
        navigationController?.pushViewController(ConfigurationCommandsViewController(glasses), animated: true)
    }

    func showNotificationsViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(identifier: "NotificationsViewController") as? NotificationsViewController {
            viewController.glasses = glasses
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
