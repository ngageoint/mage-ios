//
//  Location.h
//  Pods
//
//  Created by Billy Newman on 6/24/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Location : NSManagedObject

@property (nonatomic, retain) id geometry;
@property (nonatomic, retain) NSString * remoteId;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) id properties;

@end
