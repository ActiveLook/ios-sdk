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
import CoreBluetooth

extension CBPeripheral {

    func getService(withUUID uuid: CBUUID) -> CBService? {
        if let services = self.services, let index = services.firstIndex(where: { $0.uuid == uuid }) {
            return services[index]
        }
        return nil
    }
}
