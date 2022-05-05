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

public protocol GlassesUpdate {
    func getDiscoveredGlasses() -> DiscoveredGlasses
    func getState() -> State
    func getProgress() -> Double
    func getSourceFirmwareVersion() -> String
    func getTargetFirmwareVersion() -> String
    func getSourceConfigurationVersion() -> String
    func getTargetConfigurationVersion() -> String
}


@objc public enum State: Int {
    case DOWNLOADING_FIRMWARE
    case UPDATING_FIRMWARE  // ALSO sent in onUpdateAvailable()
    case DOWNLOADING_CONFIGURATION
    case UPDATING_CONFIGURATION // ALSO sent in onUpdateAvailable()
    case ERROR_UPDATE_FAIL
    case ERROR_UPDATE_FAIL_LOW_BATTERY
    case ERROR_UPDATE_FORBIDDEN
    case ERROR_DOWNGRADE_FORBIDDEN  // TODO: ASANA task "Check glasses FW version <= SDK version" – https://app.asana.com/0/1201639829815358/1202209982822311 – 220504
}


public class SdkGlassesUpdate: GlassesUpdate {

    private var discoveredGlasses: DiscoveredGlasses?
    private var state: State
    private var progress: Double
    private var sourceFirmwareVersion: String
    private var targetFirmwareVersion: String
    private var sourceConfigurationVersion: String
    private var targetConfigurationVersion: String

    internal init(for discoveredGlasses: DiscoveredGlasses?,
         state : State = .DOWNLOADING_FIRMWARE,
         progress: Double = 0,
         sourceFirmwareVersion: String = "",
         targetFirmwareVersion: String = "",
         sourceConfigurationVersion: String = "",
         targetConfigurationVersion: String = ""
    ) {
        self.discoveredGlasses = discoveredGlasses
        self.state = state
        self.progress = progress
        self.sourceFirmwareVersion = sourceFirmwareVersion
        self.targetFirmwareVersion = targetFirmwareVersion
        self.sourceConfigurationVersion = sourceConfigurationVersion
        self.targetConfigurationVersion = targetConfigurationVersion
    }

    public func getDiscoveredGlasses() -> DiscoveredGlasses {
        return discoveredGlasses!
    }

    public func getState() -> State {
        return state
    }

    public func getProgress() -> Double {
        return progress
    }

    public func getSourceFirmwareVersion() -> String {
        return sourceFirmwareVersion
    }

    public func getTargetFirmwareVersion() -> String {
        return targetFirmwareVersion
    }

    public func getSourceConfigurationVersion() -> String {
        return sourceConfigurationVersion
    }

    public func getTargetConfigurationVersion() -> String {
        return targetConfigurationVersion
    }

    public func description() -> String {
        return "state: \(state) - progress: \(progress)"
    }
}
