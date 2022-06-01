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

// FIXME: IS THIS CLASS STILL NEEDED? - 220506
final internal class UpdateProgress: GlassesUpdate {

    private let discoveredGlasses: DiscoveredGlasses
    private let state: State
    private let progress: Double
    private let batteryLevel: Int?
    private let sourceFirmwareVersion: String
    private let targetFirmwareVersion: String
    private let sourceConfigurationVersion: String
    private let targetConfigurationVersion: String


    init( _ discoveredGlasses: DiscoveredGlasses,
          _ state: State,
          _ progress: Double,
          _ batteryLevel: Int?,
          _ sourceFirmwareVersion: String,
          _ targetFirmwareVersion: String,
          _ sourceConfigurationVersion: String,
          _ targetConfigurationVersion: String ) {

        self.discoveredGlasses = discoveredGlasses
        self.state = state
        self.progress = progress
        self.batteryLevel = batteryLevel
        self.sourceFirmwareVersion = sourceFirmwareVersion
        self.targetFirmwareVersion = targetFirmwareVersion
        self.sourceConfigurationVersion = sourceConfigurationVersion
        self.targetConfigurationVersion = targetConfigurationVersion
    }


    func getDiscoveredGlasses() -> DiscoveredGlasses {
        return self.discoveredGlasses;
    }


    func getState() -> State {
        return self.state;
    }


    func getProgress() -> Double {
        return self.progress;
    }

    func getBatteryLevel() -> Int? {
        return self.batteryLevel
    }


    func getSourceFirmwareVersion() -> String {
        return self.sourceFirmwareVersion;
    }


    func getTargetFirmwareVersion() -> String {
        return self.targetFirmwareVersion;
    }


    func getSourceConfigurationVersion() -> String {
        return self.sourceConfigurationVersion;
    }


    func getTargetConfigurationVersion() -> String {
        return self.targetConfigurationVersion;
    }
}
