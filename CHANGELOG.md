# Change Log
All notable changes to this project will be documented in this file.
Adheres to [Semantic Versioning](http://semver.org/).

---
## 3.0.3

##### Bug Fixes
* archived forms are no longer shown in the form picker

## 3.0.2

##### Bug Fixes
* fixes a bug where users with the no edit role were not being shown the create button

## 3.0.1

##### Bug Fixes
* copy and paste is back for form fields
* iPad behaves more like the web

## 3.0.0

##### Release Notes
* Multi form support:  Users will be able to add multiple forms to an observation when the server configuration allows.
* Brand new look and feel:  This release unifies the look and feel of the iOS app with Android and the web using Material design practices
* Straight line navigation: Users can now navigate, within the app, to any feature on the map including users or observations
* This version supports MAGE server versions 5.4 and 6.x
* This release no longer has a dependency on mage-ios-sdk, it has since been deprecated.

##### Features
* Bottom sheets are now used for all map items, replacing callouts
* Main map now remembers the last position and zoom level
* When images are captured with the camera for an observation, the GPS location is added to the image metadata
* SDK has been merged into the mage-ios baseline
* Adds support for feeds in preparation for MAGE server updates

##### Bug Fixes

## 2.1.3

##### Release Notes

##### Features
* Local user signup captcha

##### Bug Fixes

## 2.1.2

##### Release Notes

##### Features

##### Bug Fixes
* Pull in new mage-ios-sdk to fix crash when translating feed fields to strings.
* Fix bug showing polygon/polyline map callout.

## 2.1.1

##### Release Notes

##### Features

##### Bug Fixes
* Update mage-ios-sdk dependency fixing issues with third party login.

## 2.1.0

##### Release Notes

* Save on data usage by customizing data synchronization options to sync only on specific networks, ie cell or wi-fi. See below for more information.

##### Features
* Users can now further customize data synchronization in "Settings -> Network Sync Settings". Includes separate synchronization options for
  observations, attachments and user locations. Users have the option to sync over all networks (default), wi-fi only, specific wi-fi networks (inclusive or exclusive) or never.
* Google authentication support is back. This includes updates for all third party authentication strategies to align with Apple guidelines.

##### Bug Fixes
* Fix GeoPackage layer selection on iOS 14.
* Support for iOS 14 date picker.

## 2.0.19 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.19)

##### Release Notes

##### Features

##### Bug Fixes
* Duplicate locally shared GeoPackages now prompt the user asking if the old GeoPackage should be overwritten or the new GeoPackage should be also imported.
* Fix bug where video will not attach to observation when photo has not been attached first.

## 2.0.18 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.18)

##### Release Notes

##### Features
* Add observation accuracy.  Accuracy circle displayed on map for annotation click, observation view, 
  and edit. Accuracy info is also displayed textually in observation view and edit.
* Show location accuracy circle in user profile map.
* Image caching is now handled by KingFisher, this affects all attachment views
* Observation feed display is now separate from the map marker display

##### Bug Fixes
* Images and videos selected from the gallery are no longer re-saved to the gallery
* iPad filter button works again
* The gallery was being launched from a background thread the first time the app was launched

## 2.0.17 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.17)

##### Release Notes

##### Features

##### Bug Fixes
* Fixed bug that could cause app crash when selecting a new event.
* Fixed possible race condition where the token could be marked as invalid
immediately after the user has completed signin.

## 2.0.16 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.16)

##### Release Notes

##### Features
* Upgraded to GeoPackage-iOS 4.0.1

##### Bug Fixes
* Fix bug causing offline map layer to appear above the GeoPackage layers

## 2.0.15 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.15)

##### Release Notes

##### Features

* Support XYZ/TMS/WMS layers form the server on the mobile client
* Allow cancelling a GeoPackage download

##### Bug Fixes
* Support new sharing options to pick up GeoPackages being shared into MAGE.
* Fix crash when attaching audio recording

## 2.0.14 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.14)

##### Release Notes

##### Features

##### Bug Fixes
* Fix iPad layout issues for iOS 13
* Fix crash when trying to modify observation location for events with no forms.

## 2.0.13 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.13)

##### Release Notes

##### Features

##### Bug Fixes
* Wrap UISearchBar background color setter in iOS 13 check.

## 2.0.12 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.12)

##### Release Notes

##### Features
* iOS 13 updates.
* Integrate SSZipArchive
* SAML authentication support.

##### Bug Fixes

## 2.0.11 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.11)

##### Release Notes

##### Features
* Traffic map layer.
* LDAP authentication support.
* Default image upload size to orginal changed to orginal.
* Observation feed display is now separate from the map marker display

##### Bug Fixes

## 2.0.10 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.10)

##### Release Notes

##### Features
* Added loading indicator to oauth provider page load
* Apply default styles to StyledPolyline and StyledPolygon.  This will ensure static features without those styles defined will  appear on the map. 

##### Bug Fixes
* Multi line form names in form picker collection view now wrap correctly.  This is a 
  workaround for a bug discovered in iOS 12.  
* Fixed bug where static feature map annotation callout wasn't sized correctly.  Updated to use same callout the geopackage features use, which supports
  html and clickable links.

## 2.0.9 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.9)

##### Release Notes

##### Features
* Add custom default values to event forms.
* From the settings menu you can now select from your most recent events.
* Customize the size and quality of photo and video uploads.

##### Bug Fixes
* Fixed a bug that could cause a crash when being notified of an observation.

## 2.0.8 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.8)

##### Release Notes
* Updated default observation and location filters to 'last month' from 'all'.

##### Features
* New mage sdk will keep UI up to date by pulling observation in chunks.

## 2.0.7 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.7)

##### Release Notes

##### Features
* URLs in GeoPackage features are now clickable.
* GeoPackage SDK updated to 3.1.0.

##### Bug Fixes
* Cleanup coordinators lists when controllers are done.

## 2.0.6 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.6)

##### Bug Fixes
* Upgrade to 2.0.8 SDK which fixes the case where an observation has no forms but an event does
* No more crashing when signing up for an account

## 2.0.5 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.5) 

##### Release Notes

Locations can now be viewed and edited in MGRS or Latitude Longitude.

##### Features

* Added MGRS as an option to show and edit locations.

##### Bug Fixes

* GeoPackage downloading does not fail if two GeoPackages had the same name

## 2.0.4 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.4) (08-21-2018)

##### Release Notes

Getting duplicate observations? Not anymore. Found what we believe was causing this to happen in the case where the phone stops the app and the database is not set up properly when the app restarts.

##### Bug Fixes

* Check if protected data is available prior to setting up the database
* Verify that the database was opened properly before moving on to the app
* Removed background fetch
* Maps should update when going back to the map
* Events with no forms will not crash the app

## 2.0.3 (https://github.com/ngageoint/mage-ios/releases/tag/2.0.3) (07-02-2018)

##### Release Notes

On the go? Initial support for GeoPackage download from the MAGE server.

##### Features

* Download GeoPackages that are linked to the events, from the server
* Event chooser screen loading time should be improved

##### Bug Fixes

* Fix new observation form picker crash when theme is set to auto.
* Invalidate server token when a user logs out on the app
* Bug fixes for some exceptions when opening invalid GeoPackage files
* Bug fixes for oauth login type

## [2.0.2](https://github.com/ngageoint/mage-ios/releases/tag/2.0.2) (04-18-2018)

##### Release Notes

Tired of burning your retinas while using MAGE at night or in a dark area?  MAGE now comes with a wonderful night theme.  Sometimes, users would log in without a connection and immediately be logged out as soon as the app would regain connection.  How rude.  Now when you are logged in without a connection to the server, you will be notified and allowed to log in from the settings screen when you have a connection again.  MAGE will no longer log you out when a connection is obtained, however, before you see any updates from your team, and before your local updates are sent to them, you will need to log in again.  Also, bug fixes.  Found them all this time...

##### Features

* Themes: Currently support day and night themes
* Disconnected login has been improved to give the user more feedback
* Additions for login.gov

##### Bug Fixes

* Fixes case where an observation was being edited when the user logged out and then changed their server.
* Attachment cell constraint fix
* Observation markers are not dropped multiple times when an observation is created
* Apple maps URL fixed for case with primary fields with spaces
* You can now cancel adding a voice recording
* Fixes case where connection is lost before events are pulled

## [2.0.1](https://github.com/ngageoint/mage-ios/releases/tag/2.0.1) (02-15-2018)

##### Features

* Geometry cells in observations now match the look and feel of observation location cells
* Map settings now use the coordinator pattern
* Geometry Edit uses the same map type as the main map

##### Bug Fixes

* Geometries are sent properly for location fields in observations
* Constraints are updated for the login screen when the keyboard is shown
* Local login is not used unless the network error is cannot connect to host
* Observation View updates when a new form is added to an observation
* Constraints are updated when the keyboard shows on the geometry edit view
* Fix for table layout in iOS 10
* Fix for events containing no forms
* Fix for forms with a geometry field

## 2.0 (https://github.com/ngageoint/mage-ios/releases/tag/2.0) (11-21-2017)

##### Features
* Observation geometry support for lines and polygons
* Multiple forms per event support
* Users can delete observations
* Observation local notification support
* Hook up new mage-ios-sdk background upload service for attachments.
* iOS 11 support
* Users can change their password from the app

##### Bug Fixes
* Save videos to local MAGE app directory.  This will prevent deletion from gallery from dissociating the attachment from the observation.
* Don't save (duplicate) media picked from the gallery.

## 1.4.5 (https://github.com/ngageoint/mage-ios/releases/tag/1.4.5) (11-06-2017)

##### Features

* Fix issue preventing users from adding collected media to the photos library

##### Bug Fixes

## 1.4.4 (https://github.com/ngageoint/mage-ios/releases/tag/1.4.4) (10-26-2017)

##### Features

##### Bug Fixes
* Fix issue with map annotation cache picking wrong icon

## 1.4.3 (https://github.com/ngageoint/mage-ios/releases/tag/1.4.3) (10-21-2017)

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
