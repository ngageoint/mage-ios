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

@protocol UserTrackingModeChanged <NSObject>

@required
-(void) userTrackingModeChanged:(MKUserTrackingMode) mode;

@end

@protocol LocationAuthorizationStatusChanged <NSObject>

@required
- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
@end


@interface MapDelegate : NSObject <MKMapViewDelegate, NSFetchedResultsControllerDelegate, ObservationSelectionDelegate, UserSelectionDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) id<UserTrackingModeChanged> userTrackingModeDelegate;
@property (nonatomic, weak) id<LocationAuthorizationStatusChanged> locationAuthorizationChangedDelegate;

@property (nonatomic, weak) IBOutlet id<MapCalloutTapped> mapCalloutDelegate;
@property (nonatomic, strong) Locations *locations;
@property (nonatomic, strong) Observations *observations;
@property (nonatomic) BOOL hideLocations;
@property (nonatomic) BOOL hideObservations;
@property (nonatomic) BOOL hideStaticLayers;
@property (nonatomic, strong) NSMutableDictionary *locationAnnotations;
@property (nonatomic, strong) NSMutableDictionary *observationAnnotations;

- (void) updateLocations:(NSArray *) locations;
- (void) updateObservations:(NSArray *) observations;
- (void) updateGPSLocation:(GPSLocation *) location forUser: (User *) user andCenter: (BOOL) shouldCenter;
- (void) setUserTrackingMode:(MKUserTrackingMode) userTrackingMode animated:(BOOL) animated;
- (void) setMapView:(MKMapView *)mapView;

@end
