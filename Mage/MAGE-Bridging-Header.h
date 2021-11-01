//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "AppDelegate.h"
#import "DataConnectionUtilities.h"
#import "StoredPassword.h"

#import "ObservationFields.h"
#import "ObservationAccuracy.h"
#import "MapObservation.h"
#import "MapObservationManager.h"

// Not sure why this isn't getting added via the geopackage pod...
#import "GPKGMapShapeConverter.h"
#import "GPKGFeatureRowData.h"

#import "FadeTransitionSegue.h"
#import "MediaLoader.h"
#import "MageServer.h"
#import "Mage.h"
#import "Server.h"
#import <MGRS.h>
#import "MagicalRecord+MAGE.h"
#import "MageOfflineObservationManager.h"
#import "SettingsTableViewController.h"
#import "NSDate+display.h"
#import "MapDelegate.h"
#import "Locations.h"
#import "Observations.h"
#import "SFGeometryUtils.h"
#import "ExternalDevice.h"
#import "MageSessionManager.h"
#import "MapViewController.h"
#import "FeedItemSelectionDelegate.h"
#import "MapSettings.h"
#import "MageSessionManager.h"
#import "AuthenticationCoordinator.h"
#import "LoginViewController.h"
#import "DisclaimerViewController.h"
#import "ServerURLController.h"
#import "SignUpViewController.h"
#import "SignUpViewController_Server5.h"
#import "ChangePasswordViewController.h"
#import "LocalLoginView.h"
#import "DeviceUUID.h"
#import "Authentication.h"
#import "FormDefaults.h"
#import "AttachmentCollectionDataStore.h"
#import "AudioRecorderViewController.h"
#import "Recording.h"
//#import "ObservationSelectionDelegate.h"
#import "SelectEditViewController.h"
#import "GeometryEditCoordinator.h"
#import "GeometryEditViewController.h"
#import "GeometryEditMapDelegate.h"
#import "MapViewController.h"
#import "MapSettingsCoordinator.h"
#import "SettingsViewController.h"
#import "TimeFilter.h"
#import "ObservationImage.h"
#import "MageFilter.h"
#import "UINavigationItem+Subtitle.h"
#import "ObservationFilterTableViewController.h"
#import "ObservationTableHeaderView.h"
#import "StaticPointAnnotation.h"
#import "LocationFilterTableViewController.h"

#import "ObservationPushService.h"
#import "AttachmentPushService.h"
#import "LocationAnnotation.h"

#pragma mark - Core Data Entities
#import "Attachment.h"
#import "Observation.h"
#import "ObservationImportant.h"
#import "ObservationFavorite.h"
#import "Layer.h"

#import "Form.h"
