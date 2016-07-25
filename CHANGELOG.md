# Change Log
All notable changes to this project will be documented in this file.
Adheres to [Semantic Versioning](http://semver.org/).

---
## 1.1.1 (TBD)

* TBD

##### Features
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
