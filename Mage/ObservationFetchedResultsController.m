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
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"lastModified" ascending:NO]]];
	
    self = [super initWithFetchRequest:fetchRequest
                  managedObjectContext:context
                    sectionNameKeyPath:@"sectionIdentifier"
                             cacheName:nil];
    
    return self;
}

@end
