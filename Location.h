//
//  Location.h
//  mage-ios-sdk
//
//  Created by William Newman on 4/22/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * eventId;
@property (nonatomic, retain) id geometry;
@property (nonatomic, retain) id properties;
@property (nonatomic, retain) NSString * remoteId;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) User *user;

@end
