//
//  Location.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/27/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Location : NSManagedObject

@property (nonatomic, retain) id geometry;
@property (nonatomic, retain) id properties;
@property (nonatomic, retain) NSString * remoteId;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * userId;

@end
