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
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Mage.sqlite"];
}

+(void) deleteAndSetupMageCoreDataStack {
    NSError *storeError = nil;
    NSError *walError = nil;
    NSError *shmError = nil;
    
    NSURL *storeURL = [NSPersistentStore MR_urlForStoreName:@"Mage.sqlite"];
    NSURL *walURL = [[storeURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-wal"];
    NSURL *shmURL = [[storeURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-shm"];
    
    [MagicalRecord cleanUp];
    
    if([[NSFileManager defaultManager] removeItemAtURL:storeURL error:&storeError] &&
       [[NSFileManager defaultManager] removeItemAtURL:walURL error:&walError] &&
       [[NSFileManager defaultManager] removeItemAtURL:shmURL error:&shmError]) {
        [self setupCoreDataStack];
    } else {
        NSLog(@"An error has occurred while deleting %@", @"Mage.sqlite");
        NSLog(@"store error description: %@", storeError.description);
        NSLog(@"wal error description: %@", walError.description);
        NSLog(@"shm description: %@", shmError.description);
    }
}

@end
