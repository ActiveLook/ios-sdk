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

class ConfigurationCommandsViewController : CommandsTableViewController {
    

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Configuration commands"
        
        commandNames = [
            "Read default configuration",
            "Write test configuration",
            "Read test configuration",
            "Select test configuration",
            "Select default configuration",
//            "Get configuration count",
//            "Configuration list",
//            "Configuration space available",
        ]
        commandActions = [
            self.readDefaultConfig,
            self.writeTestConfig,
            self.readTestConfig,
            self.setTestConfig,
            self.setDefaultConfig
//            self.configCount,
//            self.configList,
//            self.configSpace,
        ]
    }
    
    
    // MARK: - Actions
    
    func readDefaultConfig() {
        glasses.cfgRead(name: "A.LooK", callback: { (config: ConfigurationElementsInfo) in
            let alert = UIAlertController(title: "Configuration info", message: "Version: \(config.version)\nnb layout: \(config.nbLayout)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        })
    }
    
    func writeTestConfig() {
        glasses.cfgWrite(name: "DemoApp", version: 1, password: "42")
    }
    
    func readTestConfig() {
        glasses.cfgRead(name: "DemoApp", callback: { (config: ConfigurationElementsInfo) in
            let alert = UIAlertController(title: "Configuration info", message: "Version: \(config.version)\nnb layout: \(config.nbLayout)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        })
    }
    
    func setTestConfig() {
        glasses.cfgSet(name: "DemoApp")
    }
    
    func setDefaultConfig() {
        glasses.cfgSet(name: "A.LooK")
    }
    
//    func configCount() {
//        // TODO Handle callback
//        glasses.cfgGetNb()
//    }
//
//    func configList() {
//        // TODO Handle callback
//        glasses.cfgList()
//    }
//
//    func configSpace() {
//        // TODO Handle callback
//        glasses.cfgFreeSpace()
//    }
}
