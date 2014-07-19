//
//  User.h
//  Pods
//
//  Created by Billy Newman on 7/18/14.
//
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
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) Location *location;

@end
