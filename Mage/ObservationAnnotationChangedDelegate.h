//
//  ObservationTypeChangedDelegate.h
//  MAGE
//
//  Created by William Newman on 1/19/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Observation.h"

@protocol ObservationAnnotationChangedDelegate <NSObject>

@required

- (void) typeChanged:(Observation *) observation;
- (void) variantChanged:(Observation *) observation;

@end
