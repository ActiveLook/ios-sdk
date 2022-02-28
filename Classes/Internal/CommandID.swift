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

internal enum CommandID: UInt8 {

    case power = 0x00
    case clear = 0x01
    case grey = 0x02
    case demo = 0x03
    @available(*, deprecated, renamed:"demo", message: "use demo commandID instead")
    case test = 0x04    // deprecated since 4.0.0
    case battery = 0x05
    case vers = 0x06
    case led = 0x08
    case shift = 0x09
    case settings = 0x0A

    case luma = 0x10

    case sensor = 0x20
    case gesture = 0x21
    case als = 0x22

    case color = 0x30
    case point = 0x31
    case line = 0x32
    case rect = 0x33
    case rectf = 0x34
    case circ = 0x35
    case circf = 0x36
    case txt = 0x37
    case polyline = 0x38

    case imgSave = 0x41
    case imgDisplay = 0x42
    case imgStream = 0x44
    case imgSave1bpp = 0x45
    case imgDelete = 0x46
    case imgList = 0x47

    case fontList = 0x50
    case fontSave = 0x51
    case fontSelect = 0x52
    case fontDelete = 0x53

    case layoutSave = 0x60
    case layoutDelete = 0x61
    case layoutDisplay = 0x62
    case layoutClear = 0x63
    case layoutList = 0x64
    case layoutPosition = 0x65
    case layoutDisplayExtended = 0x66
    case layoutGet = 0x67

    case gaugeDisplay = 0x70
    case gaugeSave = 0x71
    case gaugeDelete = 0x72
    case gaugeList = 0x73
    case gaugeGet = 0x74

    case pageSave = 0x80
    case pageGet = 0x81
    case pageDelete = 0x82
    case pageDisplay = 0x83
    case pageClear = 0x84
    case pageList = 0x85

    case pixelCount = 0xA5
    case getChargingCounter = 0xA7
    case getChargingTime = 0xA8
    case resetChargingParam = 0xAA

    case wConfigID = 0xA1
    case rConfigID = 0xA2
    case setConfigID = 0xA3

    case cfgWrite = 0xD0
    case cfgRead = 0xD1
    case cfgSet = 0xD2
    case cfgList = 0xD3
    case cfgRename = 0xD4
    case cfgDelete = 0xD5
    case cfgDeleteLessUsed = 0xD6
    case cfgFreeSpace = 0xD7
    case cfgGetNb = 0xD8

    case shutdown = 0xE0
}
