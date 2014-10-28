//
//  NSPersistentStoreCoordinator+MAGE.h
//  mage-ios-sdk
//
//  Created by William Newman on 10/25/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSPersistentStoreCoordinator (MAGE)

+ (void) setDefaultPersistentStoreCoordinator:(NSPersistentStoreCoordinator *) persistentStoreCoordinator;
+ (NSPersistentStoreCoordinator *) defaultPersistentStoreCoordinator;

@end
