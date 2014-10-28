//
//  CoreDataStack.m
//  mage-ios-sdk
//
//  Created by William Newman on 10/27/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "CoreDataStack.h"
#import "NSManagedObjectModel+MAGE.h"
#import "NSPersistentStoreCoordinator+MAGE.h"
#import "NSManagedObjectContext+MAGE.h"

@implementation CoreDataStack

+(void) setupCoreDataStack {
    [NSManagedObjectContext defaultManagedObjectContext];
}

+(void) deleteCoreDataStack {
    NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
    [context lock];
    NSArray *stores = [[NSPersistentStoreCoordinator defaultPersistentStoreCoordinator] persistentStores];
    for(NSPersistentStore *store in stores) {
        [[NSPersistentStoreCoordinator defaultPersistentStoreCoordinator] removePersistentStore:store error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
    }
    [context unlock];
    
    [NSManagedObjectContext setDefaultManagedObjectContext:nil];
    [NSPersistentStoreCoordinator setDefaultPersistentStoreCoordinator:nil];
    [NSManagedObjectModel setDefaultManagedObjectModel:nil];
}

@end
