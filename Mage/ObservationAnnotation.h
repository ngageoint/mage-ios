//
//  ObservationAnnotation.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Observation.h"
#import "MapAnnotation.h"
#import <Event.h>

@interface ObservationAnnotation :  MapAnnotation

@property (nonatomic) NSDate *timestamp;

@property (nonatomic) NSString *name;

@property (nonatomic) Observation *observation;

@property (nonatomic) BOOL selected;

- (id)initWithObservation:(Observation *) observation andEventForms: (NSArray *) forms;

- (id)initWithObservation:(Observation *) observation andEventForms: (NSArray *) forms andGeometry: (WKBGeometry *) geometry;

- (id)initWithObservation:(Observation *) observation andEventForms: (NSArray *) forms andLocation:(CLLocationCoordinate2D) location;

@end
