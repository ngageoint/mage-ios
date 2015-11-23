//
//  ObservationAnnotation.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Observation.h"

@interface ObservationAnnotation :  NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSDate *timestamp;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

@property (nonatomic) NSString *name;

@property (nonatomic) Observation *observation;

- (id)initWithObservation:(Observation *) observation;
- (MKAnnotationView *) viewForAnnotationOnMapView: (MKMapView *) mapView;

@end
