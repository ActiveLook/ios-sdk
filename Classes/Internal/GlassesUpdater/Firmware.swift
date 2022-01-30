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


// MARK: - Internal Typealiases

internal typealias Chunck = [UInt8]
internal typealias Block = (size: Int, bytes: [Chunck])
internal typealias Blocks = [Block]


// MARK: - Internal Enum

internal enum FirmwareError: Error {
    case firmwareNullChunksize
}


// MARK: - Firmware Structure

internal struct Firmware {

    private var bytes: [UInt8]

    init(with content : Data) {
        bytes = []

        content.forEach( { byte in
            bytes.append(byte)
        } )

        bytes.append(0x00)

        // used for the CRC
        guard bytes.count == (content.count + 1) else {
            return
        }

        // basic CRC of the firmware, as defined by SUOTA
        for index in 0 ..< content.count  {
            bytes[content.count] ^= bytes[index]
        }
}


    func getSuotaBlocks(_ blockSize: Int, _ chunkSize: Int) throws -> Blocks {

        guard chunkSize > 0 else {
            throw FirmwareError.firmwareNullChunksize
        }

        let blockSize = min(bytes.count, max(blockSize, chunkSize))
        let chunkSize = min(blockSize, chunkSize)

        var blocks: Blocks = []

        var blockOffset = 0

        while blockOffset < bytes.count {
            let currentBlockSize = min(blockSize, bytes.count - blockOffset)

            var block: [[UInt8]] = []
            var chunkOffset = 0

            while chunkOffset < currentBlockSize {

                let currentChunkSize = min(chunkSize, currentBlockSize - chunkOffset)
                var chunk: Chunck = []

                let startIndex = blockOffset + chunkOffset
                let endIndex = startIndex + currentChunkSize

                chunk = Array(bytes[startIndex...endIndex])
                block.append(chunk)
                chunkOffset += currentChunkSize
            }

            blocks.append(Block(size: currentBlockSize, bytes: block))
            blockOffset += currentBlockSize
        }
        return blocks
    }

    func description() -> String {
        return String("firmare: \(bytes[0...5]) of size: \(bytes.count)")
    }
}
