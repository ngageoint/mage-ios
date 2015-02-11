//
//  MapViewController_iPad.h
//  MAGE
//
//  Created by William Newman on 9/30/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapViewController.h"
#import "MAGEMasterSelectionDelegate.h"
#import "UserSelectionDelegate.h"
#import "ObservationSelectionDelegate.h"

@interface MapViewController_iPad : MapViewController <UISplitViewControllerDelegate, MapCalloutTapped, ObservationSelectionDelegate, UserSelectionDelegate>

@property(nonatomic, weak) IBOutlet UIToolbar *toolbar;

@end
