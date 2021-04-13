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
        glasses.readConfigID(number: 1, callback: { (config: Configuration) in
            let alert = UIAlertController(title: "Configuration info", message: "Number: \(config.number)\nConfig ID: \(config.id)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        })
    }
    
    func writeTestConfig() {
        let testConfig = Configuration(number: 3, id: 1234)
        glasses.writeConfigID(configuration: testConfig)
    }
    
    func readTestConfig() {
        glasses.readConfigID(number: 3, callback: { (config: Configuration) in
            let alert = UIAlertController(title: "Configuration info", message: "Number: \(config.number)\nConfig ID: \(config.id)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        })
    }
    
    func setTestConfig() {
        glasses.setConfigID(number: 3)
    }
    
    func setDefaultConfig() {
        glasses.setConfigID(number: 1)
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
