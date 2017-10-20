# Change Log
All notable changes to this project will be documented in this file.
Adheres to [Semantic Versioning](http://semver.org/).

---
## 1.4.4 (TBD)

* TBD

##### Features

##### Bug Fixes

## 1.4.3 (https://github.com/ngageoint/mage-ios/releases/tag/1.4.3) (10-20-2017)

##### Features

##### Bug Fixes
* iPad notifies the user when it could not get a location
* iPad toolbar separators fix for iOS 11

## 1.4.2 (https://github.com/ngageoint/mage-ios/releases/tag/1.4.2) (07-28-2017)

##### Features

##### Bug Fixes
* Allow empty date field

## 1.4.1 (https://github.com/ngageoint/mage-ios/releases/tag/1.4.1) (06-13-2017)

##### Features
* Functional improvements to observation form fields.  Users no longer have to tap the 'Done' button when moving between observation form fields.

##### Bug Fixes

## 1.4.0 (https://github.com/ngageoint/mage-ios/releases/tag/1.4.0) (05-26-2017)

##### Features
* Uses mage-sdk 1.4 which will obtain an observation id from the server before pushing observation infomation.  This will
  prevent a duplicate observation in the case that the client drops a successful create attempt and retries.
* You can view observation sync status in observation view, profile, and main application badge.
* You can manually attempt to sync observations.

##### Bug Fixes

## 1.3.2 (https://github.com/ngageoint/mage-ios/releases/tag/1.3.2) (03-28-2017)

##### Features
* Choose between Local time and GMT for display and editing
* MAGE SDK upgrade to 1.3.0
* GeoPackage iOS upgrade to 1.2.1

##### Bug Fixes

## 1.3.1 (https://github.com/ngageoint/mage-ios/releases/tag/1.3.1) (02-07-2017)

##### Features

##### Bug Fixes
* Update to new mage-ios-sdk  This will ensure when checking that a user exists in an event the same
  managed object context is used.

## 1.3.0 (https://github.com/ngageoint/mage-ios/releases/tag/1.3.0) (11-03-2016)

##### Features
* Users can now favorite observations
* Users with event edit permission can flag observations as important

##### Bug Fixes

## 1.2.1 (https://github.com/ngageoint/mage-ios/releases/tag/1.2.1) (12-06-2016)

##### Features
* Added multitasking screenshot
* Added file protection entitlements file

##### Bug Fixes

## 1.2.0 (https://github.com/ngageoint/mage-ios/releases/tag/1.2.0) (08-11-2016)

##### Features
* Multi select support.
* Filter select and multi select options
* Turn on App Transport Security.

##### Bug Fixes
* Fixed bug where persons location was set to your location when viewing persons info.

## 1.1.0 (https://github.com/ngageoint/mage-ios/releases/tag/1.1.0) (06-23-2016)

##### Features
* Auto zooms to users current location on map in user view.
* Lat/Lng edit text fields added to geometry edit view, users can now manually enter a lat/lng
* Allow avatar edit from profile view.
* Added cancel button to sign up view
* Reworked how we handle media permissions.  Ask for permissions (gallery, camera, mic) before the OS asks.  In this case when the user
  performs an action like 'attach a photo' the app will check for permissions and ask the user.  If permission has been denied the app
  will present a 'link' to MAGE settings to allow the users to change the permission.
* Don't show unknown form fields.  This will help with backwards compatibility, as we won't have to worry what the client will do
  with form fields it does not know how to handle.'
* Pull thumbnails for attachments.  All image attachments will ask for thumbnail from the server, which greatly improves performance.
* Add time based filtering.

##### Bug Fixes

## [1.0.0](https://github.com/ngageoint/mage-ios/releases/tag/1.0.0) (06-14-2016)

* Initial release
