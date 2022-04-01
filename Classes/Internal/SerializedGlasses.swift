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

public typealias SerializedGlasses = Data

fileprivate var encoder = JSONEncoder()
fileprivate var decoder = JSONDecoder()

internal struct UnserializedGlasses: Codable {
    var id: String
    var name: String
    var manId: String

    func serialize() throws -> SerializedGlasses {
        do {
            return try encoder.encode(self)
        } catch {
            throw ActiveLookError.serializeError
        }
    }
}

extension SerializedGlasses {
    func unserialize() throws -> UnserializedGlasses {
        do {
            return try decoder.decode(UnserializedGlasses.self, from: self)
        } catch {
            throw ActiveLookError.unserializeError
        }
    }
}
