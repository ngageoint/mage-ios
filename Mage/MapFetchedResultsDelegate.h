//
//  MapFetchedResultsDelegate.h
//  MAGE
//
//  Created by Dan Barela on 9/15/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface MapFetchedResultsDelegate : NSObject <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (void) updateLocations:(NSArray *) locations;
- (void) updateObservations:(NSArray *) observations;

@end
