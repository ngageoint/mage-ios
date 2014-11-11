//
//  ObservationFetchedResultsController.m
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "Observations.h"
#import "NSManagedObjectContext+MAGE.h"

@implementation Observations

+ (id) observations {
    NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context]];
    // TODO look at this, I think we changed Android to timestamp or something
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO], nil]];
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                  managedObjectContext:context
                    sectionNameKeyPath:@"sectionName"
                             cacheName:nil];
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (id) observationsForUser:(User *) user {
    NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO], nil]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"user == %@", user]];

    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:@"sectionName"
                                                                                                          cacheName:nil];
    
    
    return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
}

+ (id) observationsForObservation:(Observation *) observation {
    NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO], nil]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(self = %@)", observation]];
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:context
                                                                                                 sectionNameKeyPath:nil
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
