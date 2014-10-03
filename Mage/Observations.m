//
//  ObservationFetchedResultsController.m
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "Observations.h"

@implementation Observations

+ (id) observationsInManagedObjectContext:(NSManagedObjectContext *) managedObjectContext {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:managedObjectContext]];
    // TODO look at this, I think we changed Android to timestamp or something
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"timestamp.timeAgoSinceNow" ascending:NO], [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO], nil]];
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                  managedObjectContext:managedObjectContext
                    sectionNameKeyPath:@"timestamp.timeAgoSinceNow"
                             cacheName:nil];
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
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
