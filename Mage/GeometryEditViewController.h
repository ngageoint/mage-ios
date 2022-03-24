//
//  GeometryEditViewController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "AnnotationDragCallback.h"
#import "GeometryEditCoordinator.h"
#import "GeometryEditMapDelegate.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@interface GeometryEditViewController : UIViewController <AnnotationDragCallback>

@property (strong, nonatomic) IBOutlet MKMapView *map;
@property (nonatomic) BOOL allowsPolygonIntersections;
@property (strong, nonatomic) GeometryEditMapDelegate* mapDelegate;

- (instancetype) initWithCoordinator: (GeometryEditCoordinator *) coordinator scheme: (id<MDCContainerScheming>) containerScheme;
- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme;
- (BOOL) validate:(NSError **) error;

@end
