//
//  Mage.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 3/2/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Mage : NSObject

+ (instancetype) singleton;

- (void) startServices;
- (void) stopServices;

@end
