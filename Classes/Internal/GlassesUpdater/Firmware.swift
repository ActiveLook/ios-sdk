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

typealias Block = (size: Int, bytes: [UInt8])
typealias Blocks = [Block]

enum E: Error {
    case firmwareNullChunksize
}

final class Firmware {

    private let bytes: [UInt8]

    init(with content : Data) {

        self.bytes = Array[content.count + 1]

        self.bytes = withUnsafeBytes(of: content.littleEndian) {
            Array($0)
        }

        self.bytes.last = 0

        // basic CRC of the firmware, as defined by SUOTA
        for ( int i = 0; i < content.count; i++ ) {
            self.bytes.last ^= self.bytes[i]
        }
    }


    public func getSuotaBlocks(_ blockSize: Int, _ chunkSize: Int) -> Blocks throws {

        guard chunkSize > 0 else {
            throw E.firmwareNullChunksize
        }

        blockSize = min(bytes.count, max(blockSize, chunkSize))
        chunkSize = min(blockSize, chunkSize)

        final var blocks: Blocks

        var blockOffset = 0

        while blockOffset < self.bytes.count {
            let currentBlockSize = min(blockSize, self.bytes.count - blockOffset)

            final var block: [UInt8]
            final var chunkOffset = 0

            while chunkOffset < currentBlockSize {

                let currentChunkSize = min(chunkSize, currentBlockSize - chunkOffset)
                var chunk: [UInt8] = Array[currentChunkSize]

                let startIndex = blockOffset + chunkOffset
                let endIndex = startIndex + currentChunkSize

                chunk = self.bytes[startIndex...endIndex]
                block.append(chunk)
                chunkOffset += currentChunkSize
            }

            blocks.append(Block(size: currentBlockSize, bytes: block))
            blockOffset += currentBlockSize
        }
        return blocks
    }
}
