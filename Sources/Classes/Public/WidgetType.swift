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

//Format of the widget
@objc public enum WidgetSize: UInt8 {
    case large = 0 //Dimensions 244px * 122px
    case thin  = 1 //Dimensions 244px * 61px
    case half  = 2 //Dimensions 122px * 61px
 }

//Format of the shownValue
@objc public enum WidgetValueType: UInt8 {
     case text = 0 //Doesn't change shownValue
     case number = 1 //Add thousands separator : "1234567" → "1 234 567"Split the decimals on "." or ",". Ex : "12.34" → "12." + "34
     case duration_hms = 2 //Split in 3 on ":". Ex : "0:55:35" → "0:" + "55:" + "35"
     case duration_hm = 3 //Split in 2 on ":". Ex : "0:55" → "0:" + "55"
     case duration_ms = 4 //Split in 2 on ":". Ex : "55:35" → "55:" + "35"
}
