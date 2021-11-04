//
//  ObservationShapeStyleParser.h
//  MAGE
//
//  Created by Brian Osborn on 6/19/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObservationShapeStyle.h"
#import "MAGE-Swift.h"

//@class Observation;
/**
 * Parses the observation form json and retrieves the style
 */
@interface ObservationShapeStyleParser : NSObject

/**
 * Get the observation style
 *
 * @param observation observation
 * @return shape style
 */
+(ObservationShapeStyle *) styleOfObservation: (Observation *) observation;

@end
