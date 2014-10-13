//
//  Locations.m
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "Locations.h"

@implementation Locations

+ (id) locationsForAllUsersInManagedObjectContext:(NSManagedObjectContext *) managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:managedObjectContext]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO]]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user.currentUser = %@", [NSNumber numberWithBool:NO]];
    [fetchRequest setPredicate:predicate];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:managedObjectContext
                                                                                                 sectionNameKeyPath:@"sectionName"
                                                                                                          cacheName:nil];
    
    return [[Locations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (id) locationsForUserId:(NSString *) userId inManagedObjectContext:(NSManagedObjectContext *) managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:managedObjectContext]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO]]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user.remoteId = %@", userId];
    [fetchRequest setPredicate:predicate];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:managedObjectContext
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    
    return [[Locations alloc] initWithFetchedResultsController:fetchedResultsController];
}



- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController {
    if (self = [super init]) {
        self.fetchedResultsController = fetchedResultsController;
    }
    
    return self;
}

-(void) setDelegate:(id<NSFetchedResultsControllerDelegate>)delegate {
    self.fetchedResultsController.delegate = delegate;
}


@end
