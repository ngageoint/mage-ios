//
//  LocationServicesHolder.h
//  MAGE
//
//  Created by William Newman on 10/10/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocationService.h"

@interface LocationServiceHolder : NSObject

@property (weak, nonatomic) LocationService *locationService;

@end
