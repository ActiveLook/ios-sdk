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

class GlassesUpdater {

    // MARK: - Private properties

    private var glasses: Glasses?
    private var updateParameters: GlassesUpdateParameters

    // MARK: - Life cycle

    internal init(with parameters: GlassesUpdateParameters) {
        self.updateParameters = parameters
    }

    // MARK: - Public methods

    public func update(glasses: Glasses) throws {

        self.glasses = glasses

        // download file

        // SUOTA upload file
        print("updateCalled")
        
        throw ActiveLookError.initializationError
    }

    // MARK: - Private methods
    
}

/*
 General SUOTA life cycle:
 . Load glasses information
 . Request API for firmware history
 . Compare with glasses firmware
 . Download latest firmware
 . Enadle glasses SUOTA notifications
 . Read glasses SUOTA characteristics
 . Write glasses SUOTA characteristics
 . Send firmware block and wait notification
 . Send end signal
 . Send reboot signal
 . Go to configuration update

 */

/*
Process (best case scenario)
 . create an object 1 (name?) with a reference to the glasses that will be passed around in this class
 . pass this newly created object 1 to the downloader (format URL, get JSON, parse JSON, download firmware file,
    append it to object 1, return object 1) — or only pass a reference ? Might be best... TBD
 . pass object 1 to the SuotaManager to transfer the firmware to the glasses
 */


/*
 GlassesUpdater.swift
 This class will be called by the glasses initializer before (upon?) connecting to the glasses.
    . WHAT is our OVERALL goal?
        . The objective of this module is to provide up-to-date glasses to the initializer.
    . HOW to do our OVERALL goal?
        . This module will need to download the firmware from the server
        . Then it will need to upload it using the SUOTA protocol.


    . what is the goal of this class?
        . this class is in charge of orchestrating all the components used to provide up-to-date glasses.
        . it is the entrypoint for upgrading the glasses
        . 1 create a firmwareUpload() object. This object holds a reference of
            . the glasses
            . the firmware

        . it will format the URL (or not – who is in charge of that?)
        . it will

    . what doest it need to reach the goal?
        . glasses
        . glasses version
        . firmware
        . SUOTA module to upload firmware

    . which component does it need to do the work?
        . firmware downloader
        . firmware uploader

    . what informations does it need access to?
        . from where?
            . glasses   – what?
            . server    – where?

    . what does it do?
        . updates firmware thru SUOTA to keep glasse updated

    . what is it responsible for?
        . orchestrate all the components to perform a seamless and least noticeable firmware update

    . what does it delegate?
        . to what component?

     . what information does it provides?
         . update progress
             . what format?
                 . download
                 . update


    . HOW DOES IT DO IT?
        . which order? concurrently? Is execution blocked until completion? Looks like it...
        . what orders are sent?
        . what orders are received?
        . how are orders sent?
        . how are orders received?
        . who is sending orders?
        . who is receiving orders?
        . how are results transmitted back to master?

FirmwareDownloader? More generic name?
    . download the file to be installed
    . who is responsible for constructing the URL?

 SuotaManager
 */
