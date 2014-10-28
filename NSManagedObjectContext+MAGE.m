//
//  NSManagedObjectContext+MAGE.m
//  mage-ios-sdk
//
//  Created by William Newman on 10/25/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "NSManagedObjectContext+MAGE.h"
#import "NSPersistentStoreCoordinator+MAGE.h"

NSManagedObjectContext *defaultManagedObjectContext = nil;

@implementation NSManagedObjectContext (MAGE)

+ (void) setDefaultManagedObjectContext:(NSManagedObjectContext *) mangedObjectContext {
    defaultManagedObjectContext = mangedObjectContext;
}

+ (NSManagedObjectContext *) defaultManagedObjectContext {
    if (defaultManagedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator defaultPersistentStoreCoordinator];
        defaultManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [defaultManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return defaultManagedObjectContext;
}

@end
