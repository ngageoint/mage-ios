//
//  ObservationImage.h
//  Mage
//
//  Created by Dan Barela on 7/17/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Observation.h>

@interface ObservationImage : NSObject

+ (NSString *) imageNameForObservation:(Observation *) observation;
+ (UIImage *) imageForObservation:(Observation *) observation scaledToWidth: (NSNumber *) width;

@end
