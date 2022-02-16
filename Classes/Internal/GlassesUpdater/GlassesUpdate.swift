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

protocol GlassesUpdate {
    func getDiscoveredGlasses() -> DiscoveredGlasses
    func getState() -> State
    func getProgress() -> Int
    func getSourceFirmwareVersion() -> String
    func getTargetFirmwareVersion() -> String
    func getSourceConfigurationVersion() -> String
    func getTargetConfigurationVersion() -> String
}

internal enum State {
    case DOWNLOADING_FIRMWARE
    case UPDATING_FIRMWARE
    case DOWNLOADING_CONFIGURATION
    case UPDATING_CONFIGURATION
    case ERROR_UPDATE_FAIL
    case ERROR_UPDATE_FORBIDDEN // UNAVAILABLE
    case ERROR_DOWNGRADE_FORBIDDEN
}

//public class GlassesUpdate {
//
//    private var discoveredGlasses: DiscoveredGlasses
//    private var state
//    func getDiscoveredGlasses() -> DiscoveredGlasses {
//    }
//    func getState() -> State {}
//    func getProgress() -> Int {}
//    func getSourceFirmwareVersion() -> String {}
//    func getTargetFirmwareVersion() -> String {}
//    func getSourceConfigurationVersion() -> String {}
//    func getTargetConfigurationVersion() -> String {}
//}
//
//public enum State {
//    case DOWNLOADING_FIRMWARE
//    case UPDATING_FIRMWARE
//    case DOWNLOADING_CONFIGURATION
//    case UPDATING_CONFIGURATION
//    case ERROR_UPDATE_FAIL
//    case ERROR_UPDATE_FORBIDDEN // UNAVAILABLE
//    case ERROR_DOWNGRADE_FORBIDDEN
//}
