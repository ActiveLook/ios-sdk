/*

 Copyright 2022 Microoled
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

// MARK: - Internal Enums
internal enum DownloaderError: Error {
    case DownloaderError(message: String)
}

internal class Downloader: NSObject {


    // MARK: - Private Structures


    // MARK: - FilePrivate Structures

    // MARK: - Public Variables

    // MARK: - Private Variables

    // MARK: - Initializer
    override init() { }

    // MARK: - Life Cycle

    // MARK: - Internal Methods

    internal func downloadFile(at url: URL,
                                   onSuccess successClosure: @escaping ( Data ) -> (Void),
                                   onError errorClosure: @escaping ( DownloaderError ) -> (Void))
    {
        let task = URLSession.shared.dataTask( with: url ) { data, response, error in
            guard error == nil else {
                errorClosure( DownloaderError.DownloaderError( message: "Client error" ) )
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                      errorClosure( DownloaderError.DownloaderError( message: "Server error" ) )
                      return
                  }

            guard let data = data else {
                errorClosure( DownloaderError.DownloaderError( message: "ERROR while downloading file" ))
                return
            }

            DispatchQueue.main.async {
                successClosure( Data(data) )
            }

        }
        task.resume()
    }

    // MARK: - Public Methods

    // MARK: - Private Methods

    // MARK: - CBPeripheralDelegate
}
