//
//  Locations.m
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "Locations.h"
#import "NSManagedObjectContext+MAGE.h"

@implementation Locations

+ (id) locationsForAllUsers {
    NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:context]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO]]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user.currentUser = %@", [NSNumber numberWithBool:NO]];
    [fetchRequest setPredicate:predicate];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:@"sectionName"
                                                                                                          cacheName:nil];
    
    return [[Locations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (id) locationsForUser:(User *) user {
    NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:context]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO]]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user = %@", user];
    [fetchRequest setPredicate:predicate];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
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
