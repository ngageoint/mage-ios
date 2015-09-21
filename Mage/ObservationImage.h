//
//  ObservationImage.h
//  Mage
//
//

#import <Foundation/Foundation.h>
#import <Observation.h>

@interface ObservationImage : NSObject

+ (NSString *) imageNameForObservation:(Observation *) observation;
+ (UIImage *) imageForObservation:(Observation *) observation scaledToWidth: (NSNumber *) width;

@end
