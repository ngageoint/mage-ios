//
//  ObservationFetchedResultsController.m
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationFetchedResultsController.h"

@implementation ObservationFetchedResultsController

- (id) initWithManagedObjectContext: (NSManagedObjectContext *) context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context]];
    // TODO look at this, I think we changed Android to timestamp or something
	[fetchRequest setSortDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"timestamp.timeAgoSinceNow" ascending:NO], [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO], nil]];
	
    self = [super initWithFetchRequest:fetchRequest
                  managedObjectContext:context
                    sectionNameKeyPath:@"timestamp.timeAgoSinceNow"
                             cacheName:nil];
    
    return self;
}

@end
