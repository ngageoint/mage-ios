//
//  LocationFetchedResultsController.m
//  MAGE
//
//  Created by Dan Barela on 9/16/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationFetchedResultsController.h"

@implementation LocationFetchedResultsController

- (id) initWithManagedObjectContext: (NSManagedObjectContext *) context {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:context]];
	[request setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO]]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user.currentUser = %@", [NSNumber numberWithBool:NO]];
	[request setPredicate:predicate];
	
    self = [super initWithFetchRequest:request
           managedObjectContext:context
             sectionNameKeyPath:@"sectionIdentifier"
                      cacheName:nil];

    return self;
}

@end
