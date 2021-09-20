//
//  MapDelegate.h
//  MAGE
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "ObservationSelectionDelegate.h"
#import "UserSelectionDelegate.h"
#import "Locations.h"
#import "Observations.h"
#import "GPSLocation.h"
#import "CacheOverlayListener.h"
#import "MapObservations.h"
#import "MapCalloutTapped.h"
#import "FeedItem.h"
#import <MaterialComponents/MDCContainerScheme.h>
#import "FeatureDetailViewController.h"

@class StraightLineNavigation;
@class ObservationBottomSheetController;
@class UserBottomSheetController;
@class FeatureBottomSheetController;
@class GeoPackageFeatureBottomSheetController;
@class FeedItemBottomSheetController;

@protocol FeedItemDelegate <NSObject>

- (void) addFeedItem:(FeedItem *)feedItem;
- (void) removeFeedItem:(FeedItem *)feedItem;
    
@end

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

@interface MapDelegate : NSObject <MKMapViewDelegate, NSFetchedResultsControllerDelegate, ObservationSelectionDelegate, UserSelectionDelegate, UIGestureRecognizerDelegate,  CacheOverlayListener>
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) StraightLineNavigation *straightLineNavigation;
@property (nonatomic) CLLocationCoordinate2D navigationDestinationCoordinate;

@property (nonatomic, weak) id<UserTrackingModeChanged> userTrackingModeDelegate;
@property (nonatomic, weak) id<LocationAuthorizationStatusChanged> locationAuthorizationChangedDelegate;
@property (nonatomic, weak) id<CacheOverlayDelegate> cacheOverlayDelegate;

@property (nonatomic, weak) IBOutlet id<MapCalloutTapped> mapCalloutDelegate;
@property (nonatomic, strong) Locations *locations;
@property (nonatomic, strong) Observations *observations;
@property (nonatomic) BOOL hideLocations;
@property (nonatomic) BOOL hideObservations;
@property (nonatomic) BOOL hideStaticLayers;
@property (nonatomic) BOOL canShowUserCallout;
@property (nonatomic) BOOL canShowObservationCallout;
@property (nonatomic) BOOL canShowGpsLocationCallout;
@property (nonatomic) BOOL allowEnlarge;
@property (nonatomic) BOOL trackViewState;
@property (nonatomic, strong) NSMutableDictionary *locationAnnotations;
@property (nonatomic, strong) MapObservations *mapObservations;
@property (nonatomic, weak) UIViewController *navigationController;
@property (nonatomic, weak) UIStackView *mapStack;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@property (strong, nonatomic) ObservationBottomSheetController *obsBottomSheet;
@property (strong, nonatomic) UserBottomSheetController *userBottomSheet;
@property (strong, nonatomic) FeatureBottomSheetController *featureBottomSheet;
@property (strong, nonatomic) GeoPackageFeatureBottomSheetController *geoPackageFeatureBottomSheet;
@property (strong, nonatomic) FeedItemBottomSheetController *feedItemBottomSheet;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) User *userToNavigateTo;
@property (strong, nonatomic) Observation *observationToNavigateTo;
@property (strong, nonatomic) FeedItem *feedItemToNavigateTo;
@property (nonatomic) CLLocationCoordinate2D locationToNavigateTo;
@property (strong, nonatomic) UIImage *navigationImage;

- (void) updateLocations:(NSArray *) locations;
- (void) updateLocationPredicates: (NSMutableArray *) predicates;
- (void) updateObservations:(NSArray *) observations;
- (void) setObservations:(Observations *)observations withCompletion: (void (^)(void)) complete;
- (void) updateObservationPredicates: (NSMutableArray *) predicates;
- (void) updateGPSLocation:(GPSLocation *) location forUser: (User *) user;
- (void) setUserTrackingMode:(MKUserTrackingMode) userTrackingMode animated:(BOOL) animated;
- (void) setMapView:(MKMapView *)mapView;
- (void) mapClickAtPoint: (CGPoint) point;
- (void) cleanup;
- (void) ensureMapLayout;
- (void) setupListeners;
- (void) setMapEventDelegte: (id<MKMapViewDelegate>) mapEventDelegate;
- (void) startHeading;
- (void) stopHeading;
- (void) startStraightLineNavigation: (CLLocationCoordinate2D) destination image: (UIImage *) image;
- (void) updateStraightLineNavigationDestination: (CLLocationCoordinate2D) destination;
- (void) resetEnlargedPin;
@end
