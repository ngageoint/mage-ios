//
//  MapFetchedResultsDelegate.m
//  MAGE
//
//  Created by Dan Barela on 9/15/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapFetchedResultsDelegate.h"
#import "Observation.h"
#import "Location.h"
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import "ObservationImage.h"
#import "PersonImage.h"
#import "GeoPoint.h"
#import <User.h>

@interface MapFetchedResultsDelegate ()
@property (nonatomic) NSMutableDictionary *locationAnnotations;
@property (nonatomic) NSMutableDictionary *observationAnnotations;
@end

@implementation MapFetchedResultsDelegate

- (NSMutableDictionary *) locationAnnotations {
	if (!_locationAnnotations) {
		_locationAnnotations = [[NSMutableDictionary alloc] init];
	}
	
	return _locationAnnotations;
}

- (NSMutableDictionary *) observationAnnotations {
	if (!_observationAnnotations) {
		_observationAnnotations = [[NSMutableDictionary alloc] init];
	}
	
	return _observationAnnotations;
}

#pragma mark - NSFetchResultsController

- (void) controller:(NSFetchedResultsController *) controller
    didChangeObject:(id) object
        atIndexPath:(NSIndexPath *) indexPath
      forChangeType:(NSFetchedResultsChangeType) type
       newIndexPath:(NSIndexPath *)newIndexPath {
    
    if ([object isKindOfClass:[Observation class]]) {
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [self updateObservation:object];
                break;
                
            case NSFetchedResultsChangeDelete:
                NSLog(@"Got delete for observation");
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self updateObservation:object];
                break;
        }
        
    } else {
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [self updateLocation:object];
                break;
                
            case NSFetchedResultsChangeDelete:
                NSLog(@"Got delete for location");
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self updateLocation:object];
                break;
        }
    }
}

- (void) updateLocations:(NSArray *)locations {
    for (Location *location in locations) {
		[self updateLocation:location];
	}
}

- (void) updateObservations:(NSArray *)observations {
    for (Observation *observation in observations) {
		[self updateObservation:observation];
	}
}

- (void) updateLocation:(Location *) location {
	User *user = location.user;
    
	LocationAnnotation *annotation = [self.locationAnnotations objectForKey:user.remoteId];
	if (annotation == nil) {
		annotation = [[LocationAnnotation alloc] initWithLocation:location];
		[_mapView addAnnotation:annotation];
		[self.locationAnnotations setObject:annotation forKey:user.remoteId];
	} else {
        MKAnnotationView *annotationView = [_mapView viewForAnnotation:annotation];
        annotationView.image = [PersonImage imageForLocation:annotation.location];
		[annotation setCoordinate:((GeoPoint *) location.geometry).location.coordinate];
	}
}

- (void) updateObservation: (Observation *) observation {
	ObservationAnnotation *annotation = [self.observationAnnotations objectForKey:observation.remoteId];
	if (annotation == nil) {
		annotation = [[ObservationAnnotation alloc] initWithObservation:observation];
        [_mapView addAnnotation:annotation];
		[self.observationAnnotations setObject:annotation forKey:observation.remoteId];
	} else {
        MKAnnotationView *annotationView = [_mapView viewForAnnotation:annotation];
        annotationView.image = [ObservationImage imageForObservation:observation scaledToWidth:[NSNumber numberWithFloat:35]];
        [annotation setCoordinate:((GeoPoint *) observation.geometry).location.coordinate];
    }
}



@end
