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

final internal class UpdateProgress: GlassesUpdate {

    private let discoveredGlasses: DiscoveredGlasses
    private let state: State
    private let progress: UInt8
    private let sourceFirmwareVersion: String
    private let targetFirmwareVersion: String
    private let sourceConfigurationVersion: String
    private let targetConfigurationVersion: String

    init( _ discoveredGlasses: DiscoveredGlasses,
          _ state: State,
          _ progress: UInt8,
          _ sourceFirmwareVersion: String,
          _ targetFirmwareVersion: String,
          _ sourceConfigurationVersion: String,
          _ targetConfigurationVersion: String ) {

        self.discoveredGlasses = discoveredGlasses
        self.state = state
        self.progress = progress
        self.sourceFirmwareVersion = sourceFirmwareVersion
        self.targetFirmwareVersion = targetFirmwareVersion
        self.sourceConfigurationVersion = sourceConfigurationVersion
        self.targetConfigurationVersion = targetConfigurationVersion
    }

    func withStatus( state : State ) -> UpdateProgress {
        return UpdateProgress(
            discoveredGlasses, state, progress,
            sourceFirmwareVersion, targetFirmwareVersion,
            sourceConfigurationVersion, targetConfigurationVersion)
    }

    func withProgress( progress : UInt8 ) -> UpdateProgress {
        return UpdateProgress(
            discoveredGlasses, state, progress,
            sourceFirmwareVersion, targetFirmwareVersion,
            sourceConfigurationVersion, targetConfigurationVersion)
    }

    func withSourceFirmwareVersion( sourceFirmwareVersion : String ) -> UpdateProgress {
        return UpdateProgress(
            discoveredGlasses, state, progress,
            sourceFirmwareVersion, targetFirmwareVersion,
            sourceConfigurationVersion, targetConfigurationVersion);
    }

    func withTargetFirmwareVersion( targetFirmwareVersion: String ) -> UpdateProgress {
        return UpdateProgress(
            discoveredGlasses, state, progress,
            sourceFirmwareVersion, targetFirmwareVersion,
            sourceConfigurationVersion, targetConfigurationVersion);
    }

    func withSourceConfigurationVersion( sourceConfigurationVersion : String ) -> UpdateProgress {
        return UpdateProgress(
            discoveredGlasses, state, progress,
            sourceFirmwareVersion, targetFirmwareVersion,
            sourceConfigurationVersion, targetConfigurationVersion);
    }

    func withTargetConfigurationVersion( targetConfigurationVersion : String) -> UpdateProgress {
        return UpdateProgress(
            discoveredGlasses, state, progress,
            sourceFirmwareVersion, targetFirmwareVersion,
            sourceConfigurationVersion, targetConfigurationVersion);
    }

    func getDiscoveredGlasses() -> DiscoveredGlasses {
        return self.discoveredGlasses;
    }


    func getState() -> State {
        return self.state;
    }


    func getProgress() -> UInt8 {
        return self.progress;
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
