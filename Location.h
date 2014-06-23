//
//  Location.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/20/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocationProperty;

@interface Location : NSManagedObject

@property (nonatomic, retain) id geometry;
@property (nonatomic, retain) NSString * remoteId;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSSet *properties;
@end

@interface Location (CoreDataGeneratedAccessors)

- (void)addPropertiesObject:(LocationProperty *)value;
- (void)removePropertiesObject:(LocationProperty *)value;
- (void)addProperties:(NSSet *)values;
- (void)removeProperties:(NSSet *)values;

@end
