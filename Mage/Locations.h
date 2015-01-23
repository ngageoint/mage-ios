//
//  Locations.h
//  MAGE
//
//  Created by William Newman on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ManagedObjectContextHolder.h"
#import "User+helper.h"

@interface Locations : NSObject

@property (nonatomic, strong) id<NSFetchedResultsControllerDelegate> delegate;
@property(nonatomic, strong)  NSFetchedResultsController *fetchedResultsController;

+ (id) locationsForAllUsers;
+ (id) locationsForUser:(User *) user;


- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController;

@end
