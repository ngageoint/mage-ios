//
//  NSManagedObjectModel+MAGE.h
//  mage-ios-sdk
//
//  Created by William Newman on 10/25/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectModel (MAGE)

+ (NSManagedObjectModel *) defaultManagedObjectModel;
+ (void) setDefaultManagedObjectModel:(NSManagedObjectModel *) mangedMobjectModel;

@end
