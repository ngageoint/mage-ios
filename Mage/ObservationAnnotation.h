//
//  ObservationAnnotation.h
//  Mage
//
//

#import <MapKit/MapKit.h>
#import "Observation.h"
#import "MapAnnotation.h"
#import "Event.h"

@interface ObservationAnnotation :  MapAnnotation

@property (nonatomic) NSDate *timestamp;

@property (nonatomic) NSString *name;

@property (nonatomic) Observation *observation;

@property (nonatomic) BOOL selected;

@property (nonatomic) BOOL animateDrop;

- (id)initWithObservation:(Observation *) observation andEventForms: (NSArray *) forms;

- (id)initWithObservation:(Observation *) observation andEventForms: (NSArray *) forms andGeometry: (SFGeometry *) geometry;

- (id)initWithObservation:(Observation *) observation andEventForms: (NSArray *) forms andLocation:(CLLocationCoordinate2D) location;

@end
