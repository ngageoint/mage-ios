//
//  MapViewController.h
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapDelegate.h"
#import "Locations.h"
#import "Observations.h"
#import "ObservationSelectionDelegate.h"
#import "UserSelectionDelegate.h"

@interface MapViewController : UIViewController <ObservationSelectionDelegate, UserSelectionDelegate>
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet MapDelegate *mapDelegate;

@end
