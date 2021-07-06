//
//  MagicalRecord+MAGE.m
//  mage-ios-sdk
//
//  Created by William Newman on 11/17/15.
//  Copyright © 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "MagicalRecord+MAGE.h"

@implementation MagicalRecord (MAGE)

+(void) setupMageCoreDataStack {
    NSManagedObjectModel *model = [NSManagedObjectModel MR_defaultManagedObjectModel];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    // Adding the journalling mode recommended by apple
    NSMutableDictionary *sqliteOptions = [NSMutableDictionary dictionary];
    [sqliteOptions setObject:@"WAL" forKey:@"journal_mode"];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             NSFileProtectionCompleteUnlessOpen, NSPersistentStoreFileProtectionKey,
                             sqliteOptions, NSSQLitePragmasOption,
                             nil];

    [coordinator MR_addSqliteStoreNamed:@"Mage.sqlite" withOptions:options];
    [NSPersistentStoreCoordinator MR_setDefaultStoreCoordinator:coordinator];
    
    [NSManagedObjectContext MR_initializeDefaultContextWithCoordinator:coordinator];
    
    
    // Prevent MAGE database from being backed up
    NSURL *storeURL = [[NSPersistentStore MR_urlForStoreName:@"Mage.sqlite"] URLByDeletingLastPathComponent];
    NSError *error = nil;
    BOOL success = [storeURL setResourceValue:[NSNumber numberWithBool: YES] forKey:NSURLIsExcludedFromBackupKey error: &error];
    if (!success) {
        NSLog(@"Error excluding %@ from backup %@", storeURL, error);
    }

}

+(void) deleteAndSetupMageCoreDataStack {
    NSLog(@"Remove persistent stores");
    @try {
        if ([NSManagedObjectContext MR_defaultContext] != nil) {
            for (NSPersistentStore *store in [NSManagedObjectContext MR_defaultContext].persistentStoreCoordinator.persistentStores) {
                @try {
                    [[NSManagedObjectContext MR_defaultContext].persistentStoreCoordinator removePersistentStore:store error:nil];
                }
                @catch (id exception) {}
            }
        }
    }
    @catch (id exception) {}
    
    
    NSError *storeError = nil;
    NSError *walError = nil;
    NSError *shmError = nil;
    
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:@"Mage.sqlite"];
    NSURL *walURL = [[storeURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-wal"];
    NSURL *shmURL = [[storeURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-shm"];
    
    NSLog(@"Clean up magical record");
    [MagicalRecord cleanUp];
    NSLog(@"after cleanup");
    if([[NSFileManager defaultManager] removeItemAtURL:storeURL error:&storeError] &&
       [[NSFileManager defaultManager] removeItemAtURL:walURL error:&walError] &&
       [[NSFileManager defaultManager] removeItemAtURL:shmURL error:&shmError]) {
        NSLog(@"Database files were removed.");
    } else {
        NSLog(@"An error has occurred while deleting %@", @"Mage.sqlite");
        NSLog(@"store error description: %@", storeError.description);
        NSLog(@"wal error description: %@", walError.description);
        NSLog(@"shm description: %@", shmError.description);
    }
    
    NSLog(@"setup stack");
    [self setupMageCoreDataStack];
    NSLog(@"stack is set up");
}



@end
