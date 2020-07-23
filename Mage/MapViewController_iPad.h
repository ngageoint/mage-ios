//
//  MapViewController_iPad.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import "MapViewController.h"
#import "MAGEMasterSelectionDelegate.h"
#import "UserSelectionDelegate.h"
#import "ObservationSelectionDelegate.h"
#import "MAGE-Swift.h"

@interface MapViewController_iPad : MapViewController <UISplitViewControllerDelegate, MapCalloutTapped, ObservationSelectionDelegate, UserSelectionDelegate, FeedItemSelectionDelegate>

@end
