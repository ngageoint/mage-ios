//
//  ObservationImage.h
//  Mage
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Observation.h"

@interface ObservationImage : NSObject

+ (NSString *) imageNameForObservation:(Observation *) observation;
+ (UIImage *) imageForObservation:(Observation *) observation;

@end
