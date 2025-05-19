//
//  CoreDataManager.m
//  mage-ios-sdk
//
//  Created by William Newman on 11/17/15.
//  Copyright © 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "CoreDataManager.h"
#import "MAGE-Swift.h"

static CoreDataManager *sharedManager = nil;

@implementation CoreDataManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupCoreDataStack];
    }
    return self;
}

- (void)setupCoreDataStack {
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Mage" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
    
    // Adding the journalling mode recommended by apple
    NSMutableDictionary *sqliteOptions = [NSMutableDictionary dictionary];
    [sqliteOptions setObject:@"WAL" forKey:@"journal_mode"];
    
    NSDictionary *options = @{
        NSMigratePersistentStoresAutomaticallyOption: @YES,
        NSInferMappingModelAutomaticallyOption: @YES,
        NSPersistentStoreFileProtectionKey: NSFileProtectionCompleteUnlessOpen,
        NSSQLitePragmasOption: sqliteOptions
    };
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Mage.sqlite"];
    NSError *error = nil;
    [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                             configuration:nil
                                                       URL:storeURL
                                                   options:options
                                                     error:&error];
    if (error) {
        NSLog(@"Error setting up persistent store: %@", error);
        abort();
    }
    
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    
    // Prevent MAGE database from being backed up
    NSURL *storeDirectory = [storeURL URLByDeletingLastPathComponent];
    NSError *backupError = nil;
    BOOL success = [storeDirectory setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&backupError];
    if (!success) {
        NSLog(@"Error excluding %@ from backup %@", storeDirectory, backupError);
    }
}

- (void)deleteAndSetupCoreDataStack {
    NSLog(@"Remove persistent stores");
    @try {
        for (NSPersistentStore *store in _persistentStoreCoordinator.persistentStores) {
            @try {
                [_persistentStoreCoordinator removePersistentStore:store error:nil];
            }
            @catch (id exception) {}
        }
    }
    @catch (id exception) {}
    
    NSError *storeError = nil;
    NSError *walError = nil;
    NSError *shmError = nil;
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Mage.sqlite"];
    NSURL *walURL = [[storeURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-wal"];
    NSURL *shmURL = [[storeURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"sqlite-shm"];
    
    NSLog(@"Clean up core data files");
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
    [self setupCoreDataStack];
    NSLog(@"stack is set up");
}

- (void)saveContext:(void (^)(NSManagedObjectContext *context))block {
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    
    [privateContext performBlock:^{
        block(privateContext);
        
        if ([privateContext hasChanges]) {
            NSError *error = nil;
            if (![privateContext save:&error]) {
                NSLog(@"Error saving private context: %@", error);
            }
        }
        
        [_managedObjectContext performBlock:^{
            if ([_managedObjectContext hasChanges]) {
                NSError *error = nil;
                if (![_managedObjectContext save:&error]) {
                    NSLog(@"Error saving main context: %@", error);
                }
            }
        }];
    }];
}

- (void)saveContextAndWait:(void (^)(NSManagedObjectContext *context))block {
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    
    [privateContext performBlockAndWait:^{
        block(privateContext);
        
        if ([privateContext hasChanges]) {
            NSError *error = nil;
            if (![privateContext save:&error]) {
                NSLog(@"Error saving private context: %@", error);
            }
        }
        
        [_managedObjectContext performBlockAndWait:^{
            if ([_managedObjectContext hasChanges]) {
                NSError *error = nil;
                if (![_managedObjectContext save:&error]) {
                    NSLog(@"Error saving main context: %@", error);
                }
            }
        }];
    }];
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end 