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
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:managedObjectContext]];
    [request setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO]]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user.currentUser = %@", [NSNumber numberWithBool:NO]];
    [request setPredicate:predicate];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                               managedObjectContext:managedObjectContext
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    
    return [[Locations alloc] initWithFetchedResultsController:fetchedResultsController];
}


- (id) initWithFetchedResultsController:(NSFetchedResultsController *) fetchedResultsController {
    if (self = [super init]) {
        self.fetchedResultsController = fetchedResultsController;
        self.delegate = self.fetchedResultsController.delegate;
    }
    
    return self;
}



@end
