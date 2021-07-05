//
//  Filter.h
//  MAGE
//
//  Created by William Newman on 1/13/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MageFilter : NSObject
+ (NSString *) getFilterString;
+ (NSString *) getLocationFilterString;
@end
