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

class PageCommandsViewController : CommandsTableViewController {
    

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Page commands"
        
        commandNames = [
            "List pages",
            "Save page",
            "Display page",
            "Delete page"
        ]
        commandActions = [
            self.listPages,
            self.pageSave,
            self.pageDisplay,
            self.pageDelete
        ]
    }
    
    
    // MARK: - Actions
    
    func listPages() {
        glasses.pageList() { (pages: [Int]) in
            let alert = UIAlertController(title: "Page count", message: "\(pages.count)   ", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func pageSave() {
        glasses.cfgWrite(name: "DemoApp", version: 1, password: 42)
        glasses.pageSave(id: 1, layoutIds: [1, 2], xs: [0, 50], ys: [0, 50])
    }

    func pageDisplay() {
        glasses.cfgSet(name: "DemoApp")
        glasses.pageDisplay(id: 1, texts: ["AA", "BB"])
    }

    func pageDelete() {
        glasses.cfgSet(name: "DemoApp")
        glasses.cfgWrite(name: "DemoApp", version: 1, password: 42)
        glasses.pageDelete(id: 1)
    }
}
