//
//  MapDelegate.h
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "ObservationSelectionDelegate.h"
#import "UserSelectionDelegate.h"
#import "MapCalloutTappedSegueDelegate.h"

@interface MapDelegate : NSObject <MKMapViewDelegate, NSFetchedResultsControllerDelegate, ObservationSelectionDelegate, UserSelectionDelegate>

@property (weak, nonatomic) IBOutlet id<MapCalloutTapped> mapCalloutDelegate;

- (void) updateLocations:(NSArray *) locations;
- (void) updateObservations:(NSArray *) observations;

@end
