//
//  UID.h
//  Mage
//
//  Created by Billy Newman on 8/6/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceUUID : NSObject

+ (NSUUID *) retrieveDeviceUUID;

@end
