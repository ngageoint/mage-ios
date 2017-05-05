//
//  ObservationAnnotation.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Observation.h"
#import "MapAnnotation.h"

@interface ObservationAnnotation :  MapAnnotation

@property (nonatomic) NSDate *timestamp;

@property (nonatomic) NSString *name;

@property (nonatomic) Observation *observation;

- (id)initWithObservation:(Observation *) observation;

@end
