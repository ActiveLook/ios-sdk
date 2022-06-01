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


// MARK: - Definition

internal class Downloader: NSObject {

    // MARK: - Private Variables
    private var task: URLSessionDataTask?

    private var cancelOperations: Bool = false {
        didSet {
            if cancelOperations == true {
                task?.cancel()
            }
        }
    }


    // MARK: - Life Cycle
    
    override init() { }

    deinit {
        task = nil
    }


    // MARK: - Internal Methods

    internal func abort() {
        cancelOperations = true
    }

    internal func downloadFirmware(at url: URL,
                               onSuccess successClosure: @escaping ( Data ) -> (Void),
                               onError errorClosure: @escaping ( GlassesUpdateError ) -> (Void))
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)
        
        task = URLSession.shared.dataTask( with: url ) { data, response, error in
            guard error == nil else {
                errorClosure( GlassesUpdateError.downloader(
                    message: String(format: "Client error @", #line) ) )
                return
            }


            guard let httpResponse = response as? HTTPURLResponse else {
                print("invalid response")
                errorClosure(GlassesUpdateError.downloader(message: "Invalid Response"))
                return
            }

            guard httpResponse.statusCode != 403 else {
                print("403")
                errorClosure(GlassesUpdateError.invalidToken)
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else
            {
                errorClosure( GlassesUpdateError.downloader(
                    message: String(format: "Server error @", #line) ) )
                return
            }

            guard let data = data else {
                errorClosure( GlassesUpdateError.downloader(
                    message: String(format: "ERROR while downloading file @", #line) ))
                return
            }

            DispatchQueue.main.async {
                successClosure( Data(data) )
            }

        }
        task?.resume()
    }

    internal func downloadConfiguration(at url: URL,
                                        onSuccess successClosure: @escaping ( String ) -> (Void),
                                        onError errorClosure: @escaping ( GlassesUpdateError ) -> (Void))
    {
        dlog(message: "",line: #line, function: #function, file: #fileID)

        task = URLSession.shared.dataTask( with: url ) { data, response, error in
            guard error == nil else {
                errorClosure( GlassesUpdateError.downloader(
                    message: String(format: "Client error @", #line) ) )
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                errorClosure( GlassesUpdateError.downloader(
                    message: String(format: "Server error @", #line) ) )
                return
            }

            guard let data = data else {
                errorClosure( GlassesUpdateError.downloader(
                    message: String(format: "ERROR while downloading file @", #line) ))
                return
            }

            DispatchQueue.main.async {
                successClosure( String(decoding: data, as: UTF8.self) )
            }

        }
        task?.resume()
    }
}
