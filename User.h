//
//  User.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 7/15/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * currentUser;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * remoteId;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) Location *location;

@end
