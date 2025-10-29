# MAGE iOS

11/04/2015

This is the MAGE client for iOS devices.  Depends on the [MAGE iOS SDK](https://github.com/ngageoint/mage-ios-sdk).

## About

MAGE provides mobile situational awareness capabilities. The MAGE app on your mobile device allows you to create geotagged field reports that contain media such as photos, videos, and voice recordings and share them instantly with who you want. Using the GPS in your mobile device, MAGE can also track users locations in real time. Your locations can be automatically shared with the other members of your team.

The app remains functional if your mobile device loses its network connection, and will upload its local content when a connection is re-established. When disconnected from the network, MAGE will use local data layers to continue to provide relevant GEOINT. Data layers, including map tiles and vector data, can stored on your mobile device and are available at all times.

MAGE is very customizable and can be tailored for your situation.

MAGE iOS was developed at the National Geospatial-Intelligence Agency (NGA) in collaboration with BIT Systems. The government has "unlimited rights" and is releasing this software to increase the impact of government investments by providing developers with the opportunity to take things in new directions. The software use, modification, and distribution rights are stipulated within the Apache license.

## Pull Requests

If you'd like to contribute to this project, please make a pull request. We'll review the pull request and discuss the changes. All pull request contributions to this project will be released under the Apache license.

Software source code previously released under an open source license and then modified by NGA staff is considered a "joint work" (see 17 USC § 101); it is partially copyrighted, partially public domain, and as a whole is protected by the copyrights of the non-government authors and must be released according to the terms of the original open source license.

## Install

* Mage iOS uses both Cocoapods and Swift Package Manager (SPM) to build. Cocoapods is being phased out, but is still required. 
* You can run Mage on an iOS Simulator without Apple developer credentials.
* You need an Apple developer account to run Mage on an iPhone.

```
brew install cocoapods
git clone https://github.com/ngageoint/mage-ios.git

# Setup Cocopods dependencies
cd mage-ios
pod install

# Open the Xcode Workspace (Used with Cocoapods)
open MAGE.xcworkspace
```

## Build Issues

When you switch branches and dependencies change, it can break the build (either Cocoapods or Swift Package Manager (SPM). Try these workarounds to fix any build issues:

* If you get a PIF build error (Related to SPM). Try one of these steps:
    * Close/reopen Xcode
    * Use the Menu: File > Packages > Reset Package Caches
* If switching branches has altered the cocoapods dependencies, you may need to close the project, run `pod install`, and reopen the Xcode project.
    * The benefit of this fix is that you usually do not need to rebuild everything (fast).
* Sometimes you need to Clean the Build Folder: `Command + Shift + K`. This will make your next build rebuild everything from scratch (slow).
* Rarely do you need to delete the DerivedData folder (or delete a build/ folder if using SPM)

## License

Copyright 2015 BIT Systems

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
