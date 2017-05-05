//
//  MapDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "ObservationSelectionDelegate.h"
#import "UserSelectionDelegate.h"
#import "MapCalloutTappedSegueDelegate.h"
#import "Locations.h"
#import "Observations.h"
#import <GPSLocation.h>
#import "CacheOverlayListener.h"
#import "MapObservations.h"


@protocol UserTrackingModeChanged <NSObject>

@required
-(void) userTrackingModeChanged:(MKUserTrackingMode) mode;

@end

@protocol LocationAuthorizationStatusChanged <NSObject>

@required
- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
@end

@protocol CacheOverlayDelegate <NSObject>

@optional
- (void) onCacheOverlayTapped:(NSString *) message;
@end


@interface MapDelegate : NSObject <MKMapViewDelegate, NSFetchedResultsControllerDelegate, ObservationSelectionDelegate, UserSelectionDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate, CacheOverlayListener>

@property (nonatomic, weak) id<UserTrackingModeChanged> userTrackingModeDelegate;
@property (nonatomic, weak) id<LocationAuthorizationStatusChanged> locationAuthorizationChangedDelegate;
@property (nonatomic, weak) id<CacheOverlayDelegate> cacheOverlayDelegate;

@property (nonatomic, weak) IBOutlet id<MapCalloutTapped> mapCalloutDelegate;
@property (nonatomic, strong) Locations *locations;
@property (nonatomic, strong) Observations *observations;
@property (nonatomic) BOOL hideLocations;
@property (nonatomic) BOOL hideObservations;
@property (nonatomic) BOOL hideStaticLayers;
@property (nonatomic, strong) NSMutableDictionary *locationAnnotations;
@property (nonatomic, strong) MapObservations *mapObservations;

- (void) updateLocations:(NSArray *) locations;
- (void) updateObservations:(NSArray *) observations;
- (void) updateGPSLocation:(GPSLocation *) location forUser: (User *) user andCenter: (BOOL) shouldCenter;
- (void) setUserTrackingMode:(MKUserTrackingMode) userTrackingMode animated:(BOOL) animated;
- (void) setMapView:(MKMapView *)mapView;

@end
