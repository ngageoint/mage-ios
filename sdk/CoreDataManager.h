//
//  CoreDataManager.h
//  mage-ios-sdk
//
//  Created by William Newman on 11/17/15.
//  Copyright © 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataManager : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (instancetype)sharedManager;

- (void)setupCoreDataStack;
- (void)deleteAndSetupCoreDataStack;
- (void)saveContext:(void (^)(NSManagedObjectContext *context))block;
- (void)saveContextAndWait:(void (^)(NSManagedObjectContext *context))block;

@end

NS_ASSUME_NONNULL_END 