//
//  GeometryEditViewController.h
//  MAGE
//
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "Observation.h"
#import "ObservationEditViewController.h"
#import <GeoPoint.h>

@interface GeometryEditViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (nonatomic, strong) GeoPoint *geoPoint;
@property (nonatomic, strong) Observation *observation;
@property (strong, nonatomic) id fieldDefinition;
@property (weak, nonatomic) id<PropertyEditDelegate> propertyEditDelegate;

- (IBAction) saveLocation;

@end
