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

@interface MapViewController_iPad : MapViewController <UISplitViewControllerDelegate, MapCalloutTapped, ObservationSelectionDelegate, UserSelectionDelegate>

@property(nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *eventNameItem;

@end
