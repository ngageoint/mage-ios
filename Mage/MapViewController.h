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
#import "ObservationSelectionDelegate.h"

@interface MapViewController : UIViewController<ObservationSelectionDelegate>
@property (strong, nonatomic) IBOutlet NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
