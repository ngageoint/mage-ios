//
//  MapViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapDelegate.h"
#import "Locations.h"
#import "Observations.h"
#import "TimeFilter.h"
#import "UserSelectionDelegate.h"
#import "ObservationSelectionDelegate.h"
#import "FeedItemSelectionDelegate.h"
#import "LocationService.h"
#import <MaterialComponents/MDCContainerScheme.h>
//#import "MAGE-Swift.h"

@interface MapViewController : UIViewController <MapCalloutTapped, ObservationSelectionDelegate, UserSelectionDelegate, FeedItemSelectionDelegate>
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) MapDelegate *mapDelegate;
// this property should exist in this view coordinator when we get to that
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (nonatomic) LocationService *locationService;

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme;
-(void) filterTapped:(id) sender;
-(void) createNewObservation:(id) sender;

@end
