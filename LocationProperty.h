//
//  LocationProperty.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/20/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface LocationProperty : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) id value;
@property (nonatomic, retain) Location *location;

@end
