//
//  GeometryDeserializer.h
//  mage-ios-sdk
//
//  Created by Brian Osborn on 4/24/17.
//  Copyright © 2017 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFGeometry.h"

@interface GeometryDeserializer : NSObject

+(SFGeometry *) parseGeometry: (NSDictionary *) json;

@end
