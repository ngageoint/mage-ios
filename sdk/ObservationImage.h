//
//  ObservationImage.h
//  Mage
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class Observation;

@interface ObservationImage : NSObject

+ (NSString *) imageNameForObservation:(Observation *) observation;
+ (UIImage *) imageForObservation:(Observation *) observation;

@end
