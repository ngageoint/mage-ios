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
#import "Locations.h"
#import "Observations.h"
#import <GPSLocation.h>

@interface MapDelegate : NSObject <MKMapViewDelegate, NSFetchedResultsControllerDelegate, ObservationSelectionDelegate, UserSelectionDelegate>

@property (weak, nonatomic) IBOutlet id<MapCalloutTapped> mapCalloutDelegate;
@property (strong, nonatomic) Locations *locations;
@property (strong, nonatomic) Observations *observations;
@property (nonatomic) BOOL hideLocations;
@property (nonatomic) BOOL hideObservations;

- (void) updateLocations:(NSArray *) locations;
- (void) updateObservations:(NSArray *) observations;
- (void) updateGPSLocation:(GPSLocation *) location forUser: (User *) user andCenter: (BOOL) shouldCenter;

@end
