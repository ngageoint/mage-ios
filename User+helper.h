//
//  User+helper.h
//  mage-ios-sdk
//
//  Created by Billy Newman on 6/26/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "User.h"

@interface User (helper)

+ (User *) insertUserForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context;
+ (User *) fetchUserForId:(NSString *) userId  inManagedObjectContext: (NSManagedObjectContext *) context;

- (void) updateUserForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context;

@end
